# backend/run.py
#!/usr/bin/env python3
# Application entry point

import os
import sys
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Add the parent directory to the Python path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from app import create_app
from app.utils.api import api_success

app = create_app()

# API route for root - must be defined here to avoid circular imports
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
    
    # Get host from environment variable or use default
    host = os.environ.get('HOST', '0.0.0.0')
    
    # Get debug mode from environment variable or use config
    debug = os.environ.get('DEBUG', app.config.get('DEBUG', False))
    
    # Log startup information
    app.logger.info(f"Starting Fin-Arc API on {host}:{port} (Debug: {debug})")
    
    # Run the application
    app.run(host=host, port=port, debug=debug)