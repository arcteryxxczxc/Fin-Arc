#!/usr/bin/env python3
# Application entry point

import os
import sys

# Add the parent directory to the Python path so we can import the app package
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from app import create_app
from app.models.category import Category
from flask_login import current_user

app = create_app()

# Add before request handler to check for default categories
@app.before_request
def check_default_categories():
    """Create default categories for new user if needed
    
    This middleware checks if the current authenticated user has any categories.
    If not, it creates the default categories defined in the application config.
    """
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
    """Home page route
    
    Renders the main landing page for the application.
    """
    from flask import render_template
    return render_template('index.html')

# Routes for the pages that weren't working
@app.route('/dashboard')
def dashboard():
    """Dashboard route
    
    Redirect to the reports dashboard page.
    """
    from flask import redirect, url_for
    return redirect(url_for('reports.dashboard'))

@app.route('/categories')
def categories():
    """Categories route
    
    Redirect to the categories index page.
    """
    from flask import redirect, url_for
    return redirect(url_for('categories.index'))

@app.route('/expenses')
def expenses():
    """Expenses route
    
    Redirect to the expenses index page.
    """
    from flask import redirect, url_for
    return redirect(url_for('expenses.index'))

@app.route('/income')
def income():
    """Income route
    
    Redirect to the income index page.
    """
    from flask import redirect, url_for
    return redirect(url_for('income.index'))

@app.route('/reports')
def reports():
    """Reports route
    
    Redirect to the reports dashboard page.
    """
    from flask import redirect, url_for
    return redirect(url_for('reports.dashboard'))

@app.route('/about')
def about():
    """About page route
    
    Renders the about page for the application.
    """
    from flask import render_template
    return render_template('about.html')

@app.route('/contact')
def contact():
    """Contact page route
    
    Renders the contact page for the application.
    """
    from flask import render_template
    return render_template('contact.html')

if __name__ == '__main__':
    # Get port from environment variable or use default
    port = int(os.environ.get('PORT', 5000))
    
    # Run the application
    app.run(host='0.0.0.0', port=port, debug=True)