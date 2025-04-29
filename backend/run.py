#!/usr/bin/env python3
# Application entry point

import os
import sys

# Add the parent directory to the Python path so we can import the app package
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from app import create_app
from app.models.category import Category
from flask_jwt_extended import get_jwt_identity, verify_jwt_in_request
from flask import jsonify, request

app = create_app()

# API route for root
@app.route('/api')
def api_root():
    """API root endpoint with available endpoints"""
    return jsonify({
        "message": "Welcome to Fin-Arc API",
        "version": "1.0",
        "endpoints": {
            "auth": "/api/auth",
            "expenses": "/api/expenses",
            "categories": "/api/categories",
            "income": "/api/income",
            "reports": "/api/reports",
            "settings": "/api/settings",
            "currencies": "/api/currencies",
            "notifications": "/api/notifications"
        }
    })

# Before request handler to check for default categories
@app.before_request
def before_request_handler():
    """Create default categories for new user if needed"""
    # Only proceed for authenticated requests
    if request.path.startswith('/api/') and request.path != '/api/auth/login' and request.path != '/api/auth/register':
        try:
            verify_jwt_in_request()
            username = get_jwt_identity()
            
            # Import here to avoid circular imports
            from app.models.user import User
            
            user = User.query.filter_by(username=username).first()
            if user:
                # Check if user has categories
                from app import db
                category_count = Category.query.filter_by(user_id=user.id).count()
                
                # If no categories yet, create default ones
                if category_count == 0:
                    Category.get_or_create_default_categories(user.id)
        except:
            # If JWT verification fails, continue - the endpoint will handle it
            pass

if __name__ == '__main__':
    # Get port from environment variable or use default
    port = int(os.environ.get('PORT', 5000))
    
    # Run the application
    app.run(host='0.0.0.0', port=port, debug=app.config.get('DEBUG', False))