from flask import jsonify
from app.api import api_bp
from flask_jwt_extended import jwt_required

# Import all routes
from app.api import categories, expenses, incomes, reports, currencies, settings, notifications

@api_bp.route('/test', methods=['GET'])
@jwt_required()
def test():
    return jsonify({"msg": "API is working!"}), 200

@api_bp.route('/health', methods=['GET'])
def health_check():
    return {"status": "healthy"}, 200