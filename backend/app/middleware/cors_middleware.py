from flask import request, Response, current_app
import logging

logger = logging.getLogger(__name__)

class CORSMiddleware:
    """
    Custom CORS middleware to ensure OPTIONS requests are handled correctly
    This functions as an additional safeguard beyond Flask-CORS
    """
    
    def __init__(self, app=None):
        self.app = app
        if app:
            self.init_app(app)
            
    def init_app(self, app):
        """Initialize the middleware with the Flask app"""
        app.before_request(self.before_request)
        app.after_request(self.after_request)
        
    def before_request(self):
        """Handle preflight OPTIONS requests"""
        if request.method == 'OPTIONS':
            logger.debug(f"Handling OPTIONS request for: {request.path}")
            headers = {
                'Access-Control-Allow-Origin': '*',  # Will be overridden by the configured origins
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With, Accept',
                'Access-Control-Allow-Credentials': 'true',
                'Access-Control-Max-Age': '86400',  # Cache preflight response for 24 hours
            }
            return Response('', 200, headers)
            
    def after_request(self, response):
        """Add CORS headers to all responses"""
        # These headers will generally be overridden by Flask-CORS
        # but serve as a fallback in case Flask-CORS doesn't apply
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept')
        response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH')
        response.headers.add('Access-Control-Allow-Credentials', 'true')
        
        return response