import os
from flask import Flask
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
    """Application factory function
    
    Creates and configures the Flask application based on provided config
    or environment settings. Initializes all extensions and registers
    all blueprints.
    
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
    CORS(app)

    # Configure login manager
    login_manager.login_view = 'auth.login'
    login_manager.login_message_category = 'info'
    login_manager.session_protection = 'strong'

    @login_manager.user_loader
    def load_user(user_id):
        # Import models here to avoid circular imports
        from app.models.user import User
        return User.query.get(int(user_id))

    # Register blueprints
    from app.api import api_bp
    from app.auth import auth_bp

    app.register_blueprint(api_bp)
    app.register_blueprint(auth_bp)

    # Register individual route blueprints
    with app.app_context():
        # Try to import and register UI route blueprints
        try:
            from app.api.expenses import expense_routes
            app.register_blueprint(expense_routes)
        except ImportError:
            app.logger.warning("Could not register expense routes")

        try:
            from app.api.categories import category_routes
            app.register_blueprint(category_routes)
        except ImportError:
            app.logger.warning("Could not register category routes")

        try:
            from app.api.income import income_routes
            app.register_blueprint(income_routes)
        except ImportError:
            app.logger.warning("Could not register income routes")

        try:
            from app.api.reports import report_routes
            app.register_blueprint(report_routes)
        except ImportError:
            app.logger.warning("Could not register report routes")

    # Error handlers
    @app.errorhandler(404)
    def page_not_found(e):
        """Handle 404 errors"""
        from flask import render_template
        return render_template('errors/404.html'), 404

    @app.errorhandler(500)
    def internal_server_error(e):
        """Handle 500 errors"""
        from flask import render_template
        return render_template('errors/500.html'), 500

    # Route for health check
    @app.route('/health')
    def health_check():
        return {"status": "healthy"}
        
    # Create template directories if they don't exist
    template_dirs = ['about', 'contact']
    os.makedirs(os.path.join(app.root_path, 'templates', 'about'), exist_ok=True)
    os.makedirs(os.path.join(app.root_path, 'templates', 'contact'), exist_ok=True)

    return app