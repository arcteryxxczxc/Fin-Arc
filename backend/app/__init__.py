import os
from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from flask_bcrypt import Bcrypt
from dotenv import load_dotenv
from datetime import timedelta
from sqlalchemy.exc import SQLAlchemyError
import logging
import psycopg2
import traceback
import re

# Load environment variables from .env file
load_dotenv()

# Initialize extensions
db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()
bcrypt = Bcrypt()

# Set up logger
logger = logging.getLogger(__name__)

def create_app(config=None):
    """Application factory function that creates a Flask API-only backend"""
    app = Flask(__name__)
    
    # Configure the app
    if config is None:
        # Import config here to avoid circular imports
        from config import get_config
        config = get_config()
    
    app.config.from_object(config)
    
    # Configure logging
    try:
        from logging_config import configure_logging
        configure_logging(app)
    except ImportError:
        # Basic logging configuration if logging_config.py is not available
        logging_level = getattr(logging, app.config.get('LOG_LEVEL', 'INFO'))
        logging.basicConfig(
            level=logging_level,
            format=app.config.get('LOG_FORMAT', '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        )
        
    # Test database connection before initializing app
    try:
        # Try to connect to the database to validate connection
        conn_string = app.config['SQLALCHEMY_DATABASE_URI']
        app.logger.info(f"Testing database connection to: {conn_string.split('@')[1]}")
        
        # Parse connection string to get credentials (without password)
        if conn_string.startswith('postgresql'):
            # Extract connection parameters
            db_params = {}
            params_str = conn_string.split('://')[-1]
            
            # Extract user and password
            user_pass, host_port_db = params_str.split('@', 1)
            if ':' in user_pass:
                db_params['user'], db_params['password'] = user_pass.split(':', 1)
            else:
                db_params['user'] = user_pass
                db_params['password'] = ''
                
            # Extract host, port, and database
            if '/' in host_port_db:
                host_port, db_name = host_port_db.split('/', 1)
                db_params['dbname'] = db_name
                
                if ':' in host_port:
                    db_params['host'], db_params['port'] = host_port.split(':', 1)
                else:
                    db_params['host'] = host_port
            
            # Try connection
            app.logger.info(f"Connecting to PostgreSQL database: host={db_params.get('host')}, user={db_params.get('user')}, dbname={db_params.get('dbname')}")
            conn = psycopg2.connect(
                host=db_params.get('host', 'localhost'),
                user=db_params.get('user', 'postgres'),
                password=db_params.get('password', ''),
                dbname=db_params.get('dbname', 'fin_arc'),
                port=db_params.get('port', '5432')
            )
            conn.close()
            app.logger.info("Database connection successful")
    except Exception as e:
        app.logger.error(f"Database connection error: {str(e)}")
        app.logger.error(f"Connection string: {conn_string.split(':')[0]}://{conn_string.split(':')[1].split(':')[0]}:***@{conn_string.split('@')[1]}")
        app.logger.error(f"Stack trace: {traceback.format_exc()}")
    
    # Initialize extensions with app
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    bcrypt.init_app(app)
    
    # Configure CORS for Flutter Web/Mobile client
    origins = [
        'http://localhost:8080',  # Flutter web default dev port
        'http://127.0.0.1:8080',
        'http://localhost:3000',  # Alternative dev server
        'http://127.0.0.1:3000',
        'capacitor://localhost',  # Capacitor for mobile
        'ionic://localhost',      # Ionic for mobile
        'http://localhost',       # General localhost
        'http://127.0.0.1',
        'file://'                 # File protocol for mobile apps
    ]
    
    # Add additional Flutter development ports
    flutter_dev_ports = ['8000', '8081', '8082', '8083', '8084', '8085', '8888', '8889', 
                         '1234', '4200', '4000', '4001', '5000', '5500', '8111']
    for port in flutter_dev_ports:
        origins.append(f'http://localhost:{port}')
        origins.append(f'http://127.0.0.1:{port}')
    
    # Add production URLs if in production
    production_origins = []
    if app.config.get('FLASK_ENV') == 'production':
        production_urls = app.config.get('FLUTTER_WEB_URLS', '').split(',')
        for url in production_urls:
            if url and url.strip():
                production_origins.append(url.strip())
    
    # Simplified CORS configuration
    CORS(app, 
         resources={r"/*": {"origins": "*"}},
         supports_credentials=True,
         allow_headers=["Content-Type", "Authorization", "Access-Control-Allow-Credentials", 
                        "X-Requested-With", "Accept"],
         methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
         expose_headers=["Content-Disposition", "Authorization"])

    # Configure JWT settings
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=1)
    app.config['JWT_REFRESH_TOKEN_EXPIRES'] = timedelta(days=30)
    app.config['JWT_ERROR_MESSAGE_KEY'] = 'error'
    app.config['JWT_BLACKLIST_ENABLED'] = True
    app.config['JWT_BLACKLIST_TOKEN_CHECKS'] = ['access', 'refresh']

    # Create database tables if they don't exist
    with app.app_context():
        try:
            db.create_all()
            app.logger.info("Database tables created or confirmed to exist")
        except Exception as e:
            app.logger.error(f"Error creating database tables: {str(e)}")
    
    # Register API blueprint
    from app.api import api_bp
    app.register_blueprint(api_bp)

    # Global handler for OPTIONS requests
    @app.route('/<path:path>', methods=['OPTIONS'])
    def handle_options(path):
        return '', 200

    # Add after_request function to adjust headers
    @app.after_request
    def after_request(response):
        app.logger.debug(f"Response headers: {dict(response.headers)}")
        
        # Ensure Content-Type is correct for JSON responses
        if hasattr(response, 'json') and response.json is not None and response.headers.get('Content-Type') == 'text/html; charset=utf-8':
            response.headers['Content-Type'] = 'application/json; charset=utf-8'
        
        # Remove duplicated CORS headers if they exist
        headers = dict(response.headers)
        for header in ['Access-Control-Allow-Origin', 'Access-Control-Allow-Headers', 'Access-Control-Allow-Methods']:
            if header in headers and headers[header].count(',') > 5:  # Sign of duplication
                values = headers[header].split(',')
                unique_values = list(set([v.strip() for v in values]))
                response.headers[header] = ', '.join(unique_values)
        
        return response

    # Add before_request function for debugging
    @app.before_request
    def log_request_info():
        if app.config.get('DEBUG', False):
            app.logger.debug('Headers: %s', dict(request.headers))
            app.logger.debug('Body: %s', request.get_data())

    # Error handlers returning JSON responses
    @app.errorhandler(400)
    def bad_request(e):
        logger.warning(f"Bad request: {str(e)}")
        return jsonify({"error": "Bad request", "message": str(e)}), 400

    @app.errorhandler(401)
    def unauthorized(e):
        logger.warning(f"Unauthorized: {str(e)}")
        return jsonify({"error": "Unauthorized", "message": str(e)}), 401

    @app.errorhandler(403)
    def forbidden(e):
        logger.warning(f"Forbidden: {str(e)}")
        return jsonify({"error": "Forbidden", "message": str(e)}), 403

    @app.errorhandler(404)
    def not_found(e):
        logger.warning(f"Not found: {str(e)}")
        return jsonify({"error": "Resource not found", "message": str(e)}), 404

    @app.errorhandler(500)
    def internal_server_error(e):
        logger.error(f"Server error: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500
    
    @app.errorhandler(SQLAlchemyError)
    def handle_db_error(e):
        db.session.rollback()
        logger.error(f"Database error: {str(e)}")
        return jsonify({"error": "Database error occurred"}), 500
        
    # JWT error handlers
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        logger.warning(f"Expired token: {jwt_payload.get('sub', 'unknown')}")
        return jsonify({
            'error': 'Token has expired',
            'status': 401
        }), 401
    
    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        logger.warning(f"Invalid token: {error}")
        return jsonify({
            'error': 'Invalid token',
            'message': 'Signature verification failed',
            'status': 401
        }), 401
    
    @jwt.unauthorized_loader
    def missing_token_callback(error):
        logger.warning(f"Missing token: {error}")
        return jsonify({
            'error': 'Authorization required',
            'message': 'Request does not contain an access token',
            'status': 401
        }), 401
        
    @jwt.revoked_token_loader
    def revoked_token_callback(jwt_header, jwt_payload):
        logger.warning(f"Revoked token: {jwt_payload.get('sub', 'unknown')}")
        return jsonify({
            'error': 'Token has been revoked',
            'status': 401
        }), 401

    # Log successful app creation
    app.logger.info(f"App created in {app.config.get('FLASK_ENV', 'default')} mode")
    
    return app