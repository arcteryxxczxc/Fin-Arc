#!/usr/bin/env python3
# Application entry point

import os
import sys

# Add the parent directory to the Python path so we can import the app package
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from app import create_app
from app.models.category import Category
from flask_login import current_user
from flask import jsonify

app = create_app()

# Add before request handler to check for default categories
@app.before_request
def check_default_categories():
    """Create default categories for new user if needed"""
    from flask_login import current_user
    from app import db
    
    if current_user.is_authenticated:
        # Count user's categories
        category_count = Category.query.filter_by(user_id=current_user.id).count()
        
        # If no categories yet, create default ones
        if category_count == 0:
            Category.get_or_create_default_categories(current_user.id)

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

if __name__ == '__main__':
    # Get port from environment variable or use default
    port = int(os.environ.get('PORT', 5000))
    
    # Run the application
    app.run(host='0.0.0.0', port=port, debug=True)