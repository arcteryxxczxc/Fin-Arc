import os
from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from flask_bcrypt import Bcrypt
from dotenv import load_dotenv
from datetime import timedelta
from sqlalchemy.exc import SQLAlchemyError
import logging

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
    """Application factory function that creates a Flask API-only backend
    
    Creates and configures the Flask application based on provided config
    or environment settings. Initializes all extensions and registers
    all API blueprints.
    
    Args:
        config: Configuration object to use (optional)
        
    Returns:
        Configured Flask application
    """
    app = Flask(__name__)
    
    # Configure the app
    if config is None:
        # Import config here to avoid circular imports
        from config import get_config
        config = get_config()
    
    app.config.from_object(config)
    
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
        'capacitor://localhost',  # Capacitor for mobile
        'ionic://localhost',      # Ionic for mobile
        'http://localhost',       # General localhost
        'file://'                 # File protocol for mobile apps
    ]
    
    # Add production URLs if in production
    if app.config.get('FLASK_ENV') == 'production':
        production_urls = app.config.get('FLUTTER_WEB_URLS', '').split(',')
        for url in production_urls:
            if url and url.strip():
                origins.append(url.strip())
    
    # Configure CORS with more flexible settings for APIs
    CORS(app, 
         resources={r"/api/*": {"origins": origins}}, 
         supports_credentials=True,
         allow_headers=["Content-Type", "Authorization", "Access-Control-Allow-Credentials"],
         methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
         expose_headers=["Content-Disposition"])  # For file downloads

    # Configure JWT settings
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=1)
    app.config['JWT_REFRESH_TOKEN_EXPIRES'] = timedelta(days=30)
    app.config['JWT_ERROR_MESSAGE_KEY'] = 'error'
    app.config['JWT_BLACKLIST_ENABLED'] = True
    app.config['JWT_BLACKLIST_TOKEN_CHECKS'] = ['access', 'refresh']

    # Configure logging
    logging_level = getattr(logging, app.config.get('LOG_LEVEL', 'INFO'))
    logging.basicConfig(
        level=logging_level,
        format=app.config.get('LOG_FORMAT', '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    )
    
    # Register API blueprint
    from app.api import api_bp
    app.register_blueprint(api_bp)

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

    return app