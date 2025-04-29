from flask import request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.models import User, UserSettings
from app.utils.api import api_success, api_error
from app.utils.db import safe_commit
from app.utils.validation import validate_json, USER_SETTINGS_SCHEMA
import logging

# Set up logging
logger = logging.getLogger(__name__)

@api_bp.route('/settings', methods=['GET'])
@jwt_required()
def get_user_settings():
    """
    Get user settings
    
    Returns user settings object
    """
    try:
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get or create settings
        settings = UserSettings.query.filter_by(user_id=user.id).first()
        if not settings:
            settings = UserSettings(user_id=user.id)
            settings.save_to_db()
        
        return api_success(settings.to_dict())
    except Exception as e:
        logger.error(f"Error getting user settings: {str(e)}")
        return api_error(f"Error getting user settings: {str(e)}", 500)

@api_bp.route('/settings', methods=['PUT'])
@jwt_required()
@validate_json(USER_SETTINGS_SCHEMA)
def update_user_settings():
    """
    Update user settings
    
    Request body:
    - default_currency: Default currency code (optional)
    - notification_enabled: Whether notifications are enabled (optional)
    - theme: Theme name (optional)
    - language: Language code (optional)
    """
    try:
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get or create settings
        settings = UserSettings.query.filter_by(user_id=user.id).first()
        if not settings:
            settings = UserSettings(user_id=user.id)
        
        data = request.get_json()
        if not data:
            return api_error("Missing JSON in request", 400)
        
        # Update settings
        if 'default_currency' in data:
            settings.default_currency = data['default_currency']
        
        if 'notification_enabled' in data:
            settings.notification_enabled = data['notification_enabled']
        
        if 'theme' in data:
            settings.theme = data['theme']
        
        if 'language' in data:
            settings.language = data['language']
        
        # Save to database
        settings.save_to_db()
        
        return api_success({
            "message": "Settings updated successfully",
            "settings": settings.to_dict()
        })
    except Exception as e:
        logger.error(f"Error updating user settings: {str(e)}")
        return api_error(f"Error updating user settings: {str(e)}", 500)