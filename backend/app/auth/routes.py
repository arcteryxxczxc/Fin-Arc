from datetime import datetime, timedelta
from flask import request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from app.auth import auth_bp
from app.models import User
from app import db
from email_validator import validate_email, EmailNotValidError

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    
    if not data:
        return jsonify({"msg": "Missing JSON in request"}), 400
        
    username = data.get('username', '')
    email = data.get('email', '')
    password = data.get('password', '')
    
    # Validate required fields
    if not username or not email or not password:
        return jsonify({"msg": "Missing required fields"}), 400
    
    # Validate email format
    try:
        valid = validate_email(email)
        email = valid.email
    except EmailNotValidError as e:
        return jsonify({"msg": str(e)}), 400
    
    # Check if username already exists
    if User.query.filter_by(username=username).first():
        return jsonify({"msg": "Username already exists"}), 409
    
    # Check if email already exists
    if User.query.filter_by(email=email).first():
        return jsonify({"msg": "Email already exists"}), 409
    
    # Create new user
    new_user = User(
        username=username,
        email=email,
        password_hash=User.generate_hash(password)
    )
    
    try:
        new_user.save_to_db()
        access_token = create_access_token(identity=username)
        return jsonify({
            "msg": "User created successfully",
            "access_token": access_token,
            "user": {
                "id": new_user.id,
                "username": new_user.username,
                "email": new_user.email
            }
        }), 201
    except Exception as e:
        return jsonify({"msg": f"Error creating user: {str(e)}"}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    
    if not data:
        return jsonify({"msg": "Missing JSON in request"}), 400
        
    username = data.get('username', '')
    password = data.get('password', '')
    
    # Validate required fields
    if not username or not password:
        return jsonify({"msg": "Missing username or password"}), 400
    
    # Find user by username
    current_user = User.query.filter_by(username=username).first()
    
    # Check if user exists
    if not current_user:
        return jsonify({"msg": "User not found"}), 404
    
    # Check if account is locked
    if current_user.is_account_locked():
        lock_time = current_user.locked_until
        remaining_minutes = round((lock_time - datetime.utcnow()).total_seconds() / 60)
        return jsonify({
            "msg": f"Account locked due to too many failed attempts. Try again in {remaining_minutes} minutes."
        }), 403
    
    # Verify password
    if User.verify_hash(password, current_user.password_hash):
        # Reset login attempts on successful login
        current_user.update_login_attempts(successful=True)
        
        access_token = create_access_token(identity=username)
        return jsonify({
            "msg": "Login successful",
            "access_token": access_token,
            "user": {
                "id": current_user.id,
                "username": current_user.username,
                "email": current_user.email
            }
        }), 200
    else:
        # Increment login attempts on failed login
        current_user.update_login_attempts(successful=False)
        
        return jsonify({"msg": "Invalid credentials"}), 401

@auth_bp.route('/profile', methods=['GET'])
@jwt_required()
def profile():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    if not user:
        return jsonify({"msg": "User not found"}), 404
    
    return jsonify({
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "created_at": user.created_at.strftime('%Y-%m-%d %H:%M:%S')
    }), 200