#!/usr/bin/env python3
# run.py - Application entry point

import os
from app import create_app
from app.models.user import User
from app.models.category import Category

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

# Home route
@app.route('/')
def index():
    """Home page route"""
    from flask import render_template
    return render_template('index.html')

if __name__ == '__main__':
    # Get port from environment variable or use default
    port = int(os.environ.get('PORT', 5000))
    
    # Run the application
    app.run(host='0.0.0.0', port=port, debug=True)