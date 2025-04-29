from flask import request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.models import User
from app.services.notifications import NotificationService
from app.utils.api import api_success, api_error
import logging

# Set up logging
logger = logging.getLogger(__name__)

@api_bp.route('/notifications', methods=['GET'])
@jwt_required()
def get_notifications():
    """
    Get notifications for the current user
    
    Query parameters:
    - unread_only: Whether to return only unread notifications (default: false)
    
    Returns a list of notifications
    """
    try:
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Check if we should return only unread notifications
        unread_only = request.args.get('unread_only', 'false').lower() == 'true'
        
        # Get notifications
        notifications = NotificationService.get_user_notifications(user.id, unread_only)
        
        return api_success({
            "notifications": [notification.to_dict() for notification in notifications]
        })
    except Exception as e:
        logger.error(f"Error getting notifications: {str(e)}")
        return api_error(f"Error getting notifications: {str(e)}", 500)

@api_bp.route('/notifications/check', methods=['POST'])
@jwt_required()
def check_budget_limits():
    """
    Check budget limits and create notifications
    
    Returns a list of new notifications
    """
    try:
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Check budget limits and create notifications
        notifications = NotificationService.check_budget_limits(user.id)
        
        return api_success({
            "new_notifications": len(notifications),
            "notifications": [notification.to_dict() for notification in notifications]
        })
    except Exception as e:
        logger.error(f"Error checking budget limits: {str(e)}")
        return api_error(f"Error checking budget limits: {str(e)}", 500)

@api_bp.route('/notifications/<int:notification_id>/read', methods=['POST'])
@jwt_required()
def mark_notification_as_read(notification_id):
    """
    Mark a notification as read
    
    Path parameters:
    - notification_id: ID of the notification to mark as read
    
    Returns a success message
    """
    try:
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Mark notification as read
        success = NotificationService.mark_notification_as_read(notification_id, user.id)
        
        if success:
            return api_success({"message": "Notification marked as read"})
        else:
            return api_error("Notification not found", 404)
    except Exception as e:
        logger.error(f"Error marking notification as read: {str(e)}")
        return api_error(f"Error marking notification as read: {str(e)}", 500)

@api_bp.route('/notifications/read-all', methods=['POST'])
@jwt_required()
def mark_all_notifications_as_read():
    """
    Mark all notifications as read for the current user
    
    Returns the number of notifications marked as read
    """
    try:
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Mark all notifications as read
        count = NotificationService.mark_all_as_read(user.id)
        
        return api_success({
            "message": f"{count} notifications marked as read",
            "count": count
        })
    except Exception as e:
        logger.error(f"Error marking all notifications as read: {str(e)}")
        return api_error(f"Error marking all notifications as read: {str(e)}", 500)