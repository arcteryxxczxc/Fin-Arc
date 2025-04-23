from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.models import User, UserSettings

@api_bp.route('/settings', methods=['GET'])
@jwt_required()
def get_user_settings():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    # Get or create settings
    settings = UserSettings.query.filter_by(user_id=user.id).first()
    if not settings:
        settings = UserSettings(user_id=user.id)
        settings.save_to_db()
    
    return jsonify(settings.to_dict()), 200

@api_bp.route('/settings', methods=['PUT'])
@jwt_required()
def update_user_settings():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    # Get or create settings
    settings = UserSettings.query.filter_by(user_id=user.id).first()
    if not settings:
        settings = UserSettings(user_id=user.id)
    
    data = request.get_json()
    if not data:
        return jsonify({"msg": "Missing JSON in request"}), 400
    
    # Update settings
    if 'default_currency' in data:
        settings.default_currency = data['default_currency']
    
    if 'notification_enabled' in data:
        settings.notification_enabled = data['notification_enabled']
    
    if 'theme' in data:
        settings.theme = data['theme']
    
    if 'language' in data:
        settings.language = data['language']
    
    try:
        settings.save_to_db()
        return jsonify({
            "msg": "Settings updated successfully",
            "settings": settings.to_dict()
        }), 200
    except Exception as e:
        return jsonify({"msg": f"Error updating settings: {str(e)}"}), 500