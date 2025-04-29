from flask import jsonify
from app.api import api_bp
from flask_jwt_extended import jwt_required, get_jwt_identity

# Explicitly import all API modules to ensure routes are registered
from app.api import auth
from app.api import categories
from app.api import expenses
from app.api import income
from app.api import currencies
from app.api import settings
from app.api import notifications

# Import reports API explicitly
try:
    from app.api import reports
except ImportError:
    pass

@api_bp.route('/test', methods=['GET'])
@jwt_required()
def test():
    return jsonify({"msg": "API is working!"}), 200

@api_bp.route('/health', methods=['GET'])
def health_check():
    return {"status": "healthy"}, 200

@api_bp.route('/test-auth', methods=['GET'])
@jwt_required()
def test_auth():
    """Test endpoint to verify authentication is working"""
    current_username = get_jwt_identity()
    return jsonify({
        "msg": "Authentication working correctly",
        "username": current_username
    }), 200