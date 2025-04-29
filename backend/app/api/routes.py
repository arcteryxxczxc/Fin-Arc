from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.utils.api import api_success, api_error

@api_bp.route('/test', methods=['GET'])
@jwt_required()
def test():
    """Test endpoint to verify API is working"""
    return api_success({"msg": "API is working!"})

@api_bp.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for monitoring"""
    return api_success({"status": "healthy"})

@api_bp.route('/test-auth', methods=['GET'])
@jwt_required()
def test_auth():
    """Test endpoint to verify authentication is working"""
    current_username = get_jwt_identity()
    return api_success({
        "msg": "Authentication working correctly",
        "username": current_username
    })