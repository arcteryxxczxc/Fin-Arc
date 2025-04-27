#!/usr/bin/env python3
# run.py - Application entry point

import os
from flask import render_template
from flask_login import current_user
from backend.app import app
from backend.models.user import User
from backend.models.category import Category
from backend.models.expense import Expense
from backend.models.income import Income
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

# Create a context processor to make functions available in templates
@app.context_processor
def utility_processor():
    """Add utility functions for templates"""
    def format_currency(amount):
        """Format a number as currency"""
        if amount is None:
            return "$0.00"
        return "${:,.2f}".format(float(amount))
    
    def format_percentage(value):
        """Format a number as percentage"""
        if value is None:
            return "0%"
        return "{:.1f}%".format(float(value))
    
    return dict(
        format_currency=format_currency,
        format_percentage=format_percentage
    )

# Set up error handlers
@app.errorhandler(404)
def page_not_found(e):
    """Handle 404 errors"""
    return render_template('errors/404.html'), 404

@app.errorhandler(500)
def internal_server_error(e):
    """Handle 500 errors"""
    return render_template('errors/500.html'), 500

# Add before request handler to check for default categories
@app.before_request
def check_default_categories():
    """Create default categories for new user if needed"""
    if current_user.is_authenticated:
        # Count user's categories
        category_count = Category.query.filter_by(user_id=current_user.id).count()
        
        # If no categories yet, create default ones
        if category_count == 0:
            Category.get_or_create_default_categories(current_user.id)

if __name__ == '__main__':
    # Get port from environment variable or use default
    port = int(os.environ.get('PORT', 5000))
    
    # Run the application
    app.run(host='0.0.0.0', port=port, debug=True)


# Register blueprints
app.register_blueprint(auth_routes)
app.register_blueprint(expense_routes)
app.register_blueprint(category_routes)
app.register_blueprint(income_routes)
app.register_blueprint(report_routes)

# Create a context processor to make functions available in templates
@app.context_processor
def utility_processor():
    """Add utility functions for templates"""
    def format_currency(amount):
        """Format a number as currency"""
        if amount is None:
            return "$0.00"
        return "${:,.2f}".format(float(amount))
    
    def format_percentage(value):
        """Format a number as percentage"""
        if value is None:
            return "0%"
        return "{:.1f}%".format(float(value))
    
    return dict(
        format_currency=format_currency,
        format_percentage=format_percentage
    )

# Set up error handlers
@app.errorhandler(404)
def page_not_found(e):
    """Handle 404 errors"""
    return render_template('errors/404.html'), 404

@app.errorhandler(500)
def internal_server_error(e):
    """Handle 500 errors"""
    return render_template('errors/500.html'), 500

# Add before request handler to check for default categories
@app.before_request
def check_default_categories():
    """Create default categories for new user if needed"""
    if current_user.is_authenticated:
        # Count user's categories
        category_count = Category.query.filter_by(user_id=current_user.id).count()
        
        # If no categories yet, create default ones
        if category_count == 0:
            Category.get_or_create_default_categories(current_user.id)

if __name__ == '__main__':
    # Get port from environment variable or use default
    port = int(os.environ.get('PORT', 5000))
    
    # Run the application
    app.run(host='0.0.0.0', port=port, debug=True)