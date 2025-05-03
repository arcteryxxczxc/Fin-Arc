from flask import request, jsonify
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from app.api import api_bp
from app.models.user import User, LoginAttempt
from app.utils.api import api_success, api_error
from app.utils.db import safe_commit
from app.utils.validation import validate_json, USER_SCHEMA, LOGIN_SCHEMA, PASSWORD_CHANGE_SCHEMA
from email_validator import validate_email, EmailNotValidError
from datetime import datetime
import logging

# Set up logging
logger = logging.getLogger(__name__)

@api_bp.route('/auth/register', methods=['POST', 'OPTIONS'])
@validate_json(USER_SCHEMA)
def register():
    """API endpoint for user registration"""
    if request.method == 'OPTIONS':
        return api_success({'message': 'CORS preflight accepted'})
    
    try:
        data = request.get_json()
        
        # Validate email format
        try:
            valid = validate_email(data['email'])
            email = valid.email
        except EmailNotValidError as e:
            return api_error(str(e), 400)
        
        # Check if username already exists
        if User.query.filter_by(username=data['username']).first():
            return api_error("Username already exists", 409)
        
        # Check if email already exists
        if User.query.filter_by(email=email).first():
            return api_error("Email already exists", 409)
        
        # Create new user
        new_user = User(
            username=data['username'],
            email=email,
            first_name=data.get('first_name', ''),
            last_name=data.get('last_name', '')
        )
        new_user.password = data['password']
        
        # Save to database
        new_user.save_to_db()
        
        # Generate JWT tokens
        access_token = create_access_token(identity=data['username'])
        refresh_token = create_refresh_token(identity=data['username'])
        
        logger.info(f"User registered successfully: {data['username']}")
        
        return api_success({
            "message": "User created successfully",
            "access_token": access_token,
            "refresh_token": refresh_token,
            "user": {
                "id": new_user.id,
                "username": new_user.username,
                "email": new_user.email,
                "first_name": new_user.first_name,
                "last_name": new_user.last_name
            }
        }, code=201)
    except Exception as e:
        logger.error(f"Error creating user: {str(e)}")
        return api_error(f"Error creating user: {str(e)}", 500)

@api_bp.route('/auth/login', methods=['POST', 'OPTIONS'])
@validate_json(LOGIN_SCHEMA)
def login():
    """API endpoint for user login"""
    # Handle OPTIONS request for CORS preflight
    if request.method == 'OPTIONS':
        return api_success({'message': 'CORS preflight accepted'})
        
    try:
        data = request.get_json()
        username = data['username']
        password = data['password']
        
        # Find user by username
        user = User.query.filter_by(username=username).first()
        
        # Check if user exists
        if not user:
            logger.warning(f"Login attempt for non-existent user: {username}")
            return api_error("Invalid username or password", 401)
        
        # Check if account is locked
        if user.is_account_locked():
            if user.locked_until:
                remaining_minutes = round((user.locked_until - datetime.utcnow()).total_seconds() / 60)
                logger.warning(f"Login attempt on locked account: {username}")
                return api_error(
                    f"Account locked due to too many failed attempts. Try again in {remaining_minutes} minutes.",
                    403
                )
        
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
            
            # Create JWT tokens
            access_token = create_access_token(identity=username)
            refresh_token = create_refresh_token(identity=username)
            
            logger.info(f"Successful login: {username}")
            
            return api_success({
                "message": "Login successful",
                "access_token": access_token,
                "refresh_token": refresh_token,
                "user": {
                    "id": user.id,
                    "username": user.username,
                    "email": user.email,
                    "first_name": user.first_name,
                    "last_name": user.last_name
                }
            })
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
            
            logger.warning(f"Failed login attempt for user: {username}")
            return api_error("Invalid username or password", 401)
    except Exception as e:
        logger.error(f"Error during login: {str(e)}")
        return api_error("An error occurred during login", 500)

@api_bp.route('/auth/profile', methods=['GET'])
@jwt_required()
def profile():
    """API endpoint to get user profile information"""
    try:
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
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
        
        return api_success({
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "created_at": user.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            "last_login": user.last_login.strftime('%Y-%m-%d %H:%M:%S') if user.last_login else None,
            "login_history": login_history
        })
    except Exception as e:
        logger.error(f"Error retrieving user profile: {str(e)}")
        return api_error("An error occurred while retrieving user profile", 500)

@api_bp.route('/auth/change-password', methods=['POST'])
@jwt_required()
@validate_json(PASSWORD_CHANGE_SCHEMA)
def change_password():
    """API endpoint to change password"""
    try:
        data = request.get_json()
        current_password = data['current_password']
        new_password = data['new_password']
        
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Verify current password
        if not user.verify_password(current_password):
            return api_error("Current password is incorrect", 401)
        
        # Update password
        user.password = new_password
        success, error = safe_commit()
        
        if not success:
            return api_error(f"Database error: {error}", 500)
        
        logger.info(f"Password changed for user: {user.username}")
        return api_success(message="Password changed successfully")
    except Exception as e:
        logger.error(f"Error changing password: {str(e)}")
        return api_error("An error occurred while changing password", 500)

@api_bp.route('/auth/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh_token():
    """API endpoint to refresh access token"""
    try:
        current_username = get_jwt_identity()
        access_token = create_access_token(identity=current_username)
        return api_success({"access_token": access_token})
    except Exception as e:
        logger.error(f"Error refreshing token: {str(e)}")
        return api_error("An error occurred while refreshing token", 500)

@api_bp.route('/auth/logout', methods=['POST'])
@jwt_required()
def logout():
    """API endpoint for user logout
    
    Note: For complete logout security, the client should discard tokens
    """
    return api_success(message="Successfully logged out")