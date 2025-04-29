import os
from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from flask_login import LoginManager
from flask_bcrypt import Bcrypt
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Initialize extensions
db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()
login_manager = LoginManager()
bcrypt = Bcrypt()

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
    login_manager.init_app(app)
    bcrypt.init_app(app)
    
    # Configure CORS to allow requests from Flutter Web client
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    # Configure login manager for API auth only
    login_manager.login_view = None  # No redirect for failed auth

    @login_manager.user_loader
    def load_user(user_id):
        # Import models here to avoid circular imports
        from app.models.user import User
        return User.query.get(int(user_id))

    # Register API blueprint
    from app.api import api_bp
    app.register_blueprint(api_bp)

    # Error handlers returning JSON responses
    @app.errorhandler(404)
    def page_not_found(e):
        """Handle 404 errors with JSON response"""
        return jsonify({"error": "Resource not found", "message": str(e)}), 404

    @app.errorhandler(500)
    def internal_server_error(e):
        """Handle 500 errors with JSON response"""
        return jsonify({"error": "Internal server error", "message": str(e)}), 500

    # Route for health check
    @app.route('/api/health')
    def health_check():
        return jsonify({"status": "healthy"})
        
    return app