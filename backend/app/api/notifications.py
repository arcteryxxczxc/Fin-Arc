from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.models import User
from app.services.notifications import NotificationService

@api_bp.route('/notifications', methods=['GET'])
@jwt_required()
def get_notifications():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    # Check if we should return only unread notifications
    unread_only = request.args.get('unread_only', 'false').lower() == 'true'
    
    # Get notifications
    notifications = NotificationService.get_user_notifications(user.id, unread_only)
    
    return jsonify({
        "notifications": [notification.to_dict() for notification in notifications]
    }), 200

@api_bp.route('/notifications/check', methods=['POST'])
@jwt_required()
def check_budget_limits():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    # Check budget limits and create notifications
    notifications = NotificationService.check_budget_limits(user.id)
    
    return jsonify({
        "new_notifications": len(notifications),
        "notifications": [notification.to_dict() for notification in notifications]
    }), 200

@api_bp.route('/notifications/<int:notification_id>/read', methods=['POST'])
@jwt_required()
def mark_notification_as_read(notification_id):
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    # Mark notification as read
    success = NotificationService.mark_notification_as_read(notification_id, user.id)
    
    if success:
        return jsonify({"msg": "Notification marked as read"}), 200
    else:
        return jsonify({"msg": "Notification not found"}), 404