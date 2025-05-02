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

# Health check endpoint for monitoring
@app.route('/api/health')
def health_check():
    """Health check endpoint for monitoring"""
    return api_success({"status": "healthy"})

# Add a CORS test endpoint
@app.route('/api/cors-test')
def cors_test():
    """Test endpoint to verify CORS is working"""
    return api_success({"message": "CORS is working properly"})

# Add an OPTIONS handler for any route
@app.route('/', defaults={'path': ''}, methods=['OPTIONS'])
@app.route('/<path:path>', methods=['OPTIONS'])
def options_handler(path):
    """Handle OPTIONS requests for any route"""
    response = app.make_default_options_response()
    return response

if __name__ == '__main__':
    # Get port from environment variable or use default
    port = int(os.environ.get('PORT', 8111))
    
    # Get host from environment variable or use default
    host = os.environ.get('HOST', '0.0.0.0')
    
    # Get debug mode from environment variable or use config
    debug = os.environ.get('DEBUG', app.config.get('DEBUG', True))
    
    # Log startup information
    app.logger.info(f"Starting Fin-Arc API on {host}:{port} (Debug: {debug})")
    
    # Run the application with threading enabled
    app.run(host=host, port=port, debug=debug, threaded=True)