# backend/app.py

from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from flask_bcrypt import Bcrypt
from datetime import datetime, timedelta
import os

# Initialize Flask extensions
db = SQLAlchemy()
migrate = Migrate()
login_manager = LoginManager()
bcrypt = Bcrypt()

# Create and configure the app
app = Flask(__name__)

# Load configuration
app.config.from_object('backend.config.Config')

# Initialize extensions
db.init_app(app)
migrate.init_app(app, db)
login_manager.init_app(app)
bcrypt.init_app(app)

# Configure login manager
login_manager.login_view = 'login'
login_manager.login_message_category = 'info'
login_manager.session_protection = 'strong'

# Import models - will move to separate files in the future
from backend.models.user import User, LoginAttempt

# Configure user loader for login manager
@login_manager.user_loader
def load_user(user_id):
    """Load user by ID for Flask-Login"""
    return User.query.get(int(user_id))

# Import routes
from backend.routes.auth import auth_routes
from backend.routes.expenses import expense_routes
from backend.routes.categories import category_routes
from backend.routes.income import income_routes
from backend.routes.reports import report_routes

# Register blueprints
app.register_blueprint(auth_routes)
app.register_blueprint(expense_routes)
app.register_blueprint(category_routes)
app.register_blueprint(income_routes)
app.register_blueprint(report_routes)

# Error handlers
@app.errorhandler(404)
def page_not_found(e):
    """Handle 404 errors"""
    return render_template('errors/404.html'), 404

@app.errorhandler(500)
def internal_server_error(e):
    """Handle 500 errors"""
    return render_template('errors/500.html'), 500

# Home route
@app.route('/')
def index():
    """Home page route"""
    return render_template('index.html')

# Initialize database before first request
@app.before_first_request
def create_tables():
    """Create all database tables if they don't exist"""
    db.create_all()

if __name__ == '__main__':
    app.run(debug=True)