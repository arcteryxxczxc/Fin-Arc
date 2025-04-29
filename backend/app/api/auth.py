from flask import request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from app.api import api_bp
from app.models.user import User, LoginAttempt
from app import db
from email_validator import validate_email, EmailNotValidError
from datetime import datetime, timedelta
import logging

# Set up logging
logger = logging.getLogger(__name__)

@api_bp.route('/auth/register', methods=['POST'])
def register():
    """API endpoint for user registration"""
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Missing JSON in request"}), 400
        
    username = data.get('username', '')
    email = data.get('email', '')
    password = data.get('password', '')
    first_name = data.get('first_name', '')
    last_name = data.get('last_name', '')
    
    # Validate required fields
    if not username or not email or not password:
        return jsonify({"error": "Missing required fields"}), 400
    
    # Validate email format
    try:
        valid = validate_email(email)
        email = valid.email
    except EmailNotValidError as e:
        return jsonify({"error": str(e)}), 400
    
    # Check if username already exists
    if User.query.filter_by(username=username).first():
        return jsonify({"error": "Username already exists"}), 409
    
    # Check if email already exists
    if User.query.filter_by(email=email).first():
        return jsonify({"error": "Email already exists"}), 409
    
    # Create new user
    try:
        new_user = User(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name
        )
        new_user.password = password
        new_user.save_to_db()
        
        # Generate JWT token
        access_token = create_access_token(identity=username)
        
        logger.info(f"API: User registered successfully: {username}")
        
        return jsonify({
            "message": "User created successfully",
            "access_token": access_token,
            "user": {
                "id": new_user.id,
                "username": new_user.username,
                "email": new_user.email,
                "first_name": new_user.first_name,
                "last_name": new_user.last_name
            }
        }), 201
    except Exception as e:
        logger.error(f"API: Error creating user: {str(e)}")
        return jsonify({"error": f"Error creating user: {str(e)}"}), 500

@api_bp.route('/auth/login', methods=['POST'])
def login():
    """API endpoint for user login"""
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Missing JSON in request"}), 400
        
    username = data.get('username', '')
    password = data.get('password', '')
    
    # Validate required fields
    if not username or not password:
        return jsonify({"error": "Missing username or password"}), 400
    
    # Find user by username
    user = User.query.filter_by(username=username).first()
    
    # Check if user exists
    if not user:
        logger.warning(f"API: Login attempt for non-existent user: {username}")
        return jsonify({"error": "Invalid username or password"}), 401
    
    # Check if account is locked
    if user.is_account_locked():
        if user.locked_until:
            remaining_minutes = round((user.locked_until - datetime.utcnow()).total_seconds() / 60)
            logger.warning(f"API: Login attempt on locked account: {username}")
            return jsonify({
                "error": f"Account locked due to too many failed attempts. Try again in {remaining_minutes} minutes."
            }), 403
    
    # Verify password
    if user.verify_password(password):
        # Reset login attempts on successful login
        user.update_login_attempts(successful=True)
        
        # Record successful login attempt
        LoginAttempt.add_login_attempt(
            user=user,
            ip_address=request.remote_addr,
            user_agent=request.user_agent.string,
            success=True
        )
        
        # Update last login time
        user.update_last_login()
        
        # Create JWT token
        access_token = create_access_token(identity=username)
        
        logger.info(f"API: Successful login: {username}")
        
        return jsonify({
            "message": "Login successful",
            "access_token": access_token,
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name
            }
        }), 200
    else:
        # Increment login attempts on failed login
        user.update_login_attempts(successful=False)
        
        # Record failed login attempt
        LoginAttempt.add_login_attempt(
            user=user,
            ip_address=request.remote_addr,
            user_agent=request.user_agent.string,
            success=False
        )
        
        logger.warning(f"API: Failed login attempt for user: {username}")
        return jsonify({"error": "Invalid username or password"}), 401

@api_bp.route('/auth/profile', methods=['GET'])
@jwt_required()
def profile():
    """API endpoint to get user profile information"""
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    if not user:
        return jsonify({"error": "User not found"}), 404
    
    # Get user login history
    login_attempts = LoginAttempt.query.filter_by(user_id=user.id)\
        .order_by(LoginAttempt.timestamp.desc())\
        .limit(10)\
        .all()
    
    login_history = [{
        "timestamp": attempt.timestamp.strftime('%Y-%m-%d %H:%M:%S'),
        "ip_address": attempt.ip_address,
        "user_agent": attempt.user_agent,
        "success": attempt.success
    } for attempt in login_attempts]
    
    return jsonify({
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "created_at": user.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        "last_login": user.last_login.strftime('%Y-%m-%d %H:%M:%S') if user.last_login else None,
        "login_history": login_history
    }), 200

@api_bp.route('/auth/change-password', methods=['POST'])
@jwt_required()
def change_password():
    """API endpoint to change password"""
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Missing JSON in request"}), 400
    
    current_password = data.get('current_password', '')
    new_password = data.get('new_password', '')
    
    if not current_password or not new_password:
        return jsonify({"error": "Current password and new password are required"}), 400
    
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    if not user:
        return jsonify({"error": "User not found"}), 404
    
    # Verify current password
    if not user.verify_password(current_password):
        return jsonify({"error": "Current password is incorrect"}), 401
    
    # Update password
    try:
        user.password = new_password
        user.save_to_db()
        logger.info(f"API: Password changed for user: {user.username}")
        return jsonify({"message": "Password changed successfully"}), 200
    except Exception as e:
        logger.error(f"API: Error changing password: {str(e)}")
        return jsonify({"error": "Error changing password"}), 500

@api_bp.route('/auth/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh_token():
    """API endpoint to refresh an access token"""
    current_username = get_jwt_identity()
    access_token = create_access_token(identity=current_username)
    return jsonify({"access_token": access_token}), 200

@api_bp.route('/auth/logout', methods=['POST'])
@jwt_required()
def logout():
    """API endpoint for user logout
    
    Note: Since JWT is stateless, this endpoint just provides a standardized way
    for the client to know they should discard the token.
    """
    return jsonify({"message": "Successfully logged out"}), 200