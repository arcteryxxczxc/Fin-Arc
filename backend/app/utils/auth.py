from flask import current_app, request
from functools import wraps
from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
from app.models.user import User

def admin_required(fn):
    """
    Decorator to require admin role for a route
    """
    @wraps(fn)
    def wrapper(*args, **kwargs):
        verify_jwt_in_request()
        username = get_jwt_identity()
        user = User.query.filter_by(username=username).first()
        if not user or not user.is_admin:
            return {"msg": "Administrator access required"}, 403
        return fn(*args, **kwargs)
    return wrapper

def get_user_from_token():
    """
    Get the current user from JWT token
    """
    username = get_jwt_identity()
    return User.query.filter_by(username=username).first()

def get_request_ip():
    """
    Get client IP address from request
    """
    if request.environ.get('HTTP_X_FORWARDED_FOR'):
        return request.environ['HTTP_X_FORWARDED_FOR']
    return request.remote_addr

def get_user_agent():
    """
    Get user agent string from request
    """
    return request.user_agent.string if request.user_agent else 'Unknown'