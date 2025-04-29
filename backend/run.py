# backend/run.py
#!/usr/bin/env python3
# Application entry point

import os
import sys

# Add the parent directory to the Python path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from app import create_app
from flask_jwt_extended import get_jwt_identity, verify_jwt_in_request
from flask import jsonify, request
from app.utils.api import api_success, api_error

app = create_app()

# API route for root
@app.route('/api')
def api_root():
    """API root endpoint with available endpoints"""
    return api_success({
        "name": "Fin-Arc API",
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

# Health check endpoint for monitoring
@app.route('/api/health')
def health_check():
    """Health check endpoint for monitoring"""
    return api_success({"status": "healthy"})

if __name__ == '__main__':
    # Get port from environment variable or use default
    port = int(os.environ.get('PORT', 5000))
    
    # Run the application
    app.run(host='0.0.0.0', port=port, debug=app.config.get('DEBUG', False))