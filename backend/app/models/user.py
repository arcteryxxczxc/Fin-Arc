from datetime import datetime, timedelta
from flask import current_app
from flask_login import UserMixin
from sqlalchemy.sql import func
from app import db, bcrypt

class User(db.Model, UserMixin):
    """
    User model for authentication and user management
    Includes enhanced security features for tracking login attempts and account lockouts
    """
    __tablename__ = 'users'
    
    # Basic user information
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), unique=True, nullable=False, index=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(128), nullable=False)
    first_name = db.Column(db.String(64))
    last_name = db.Column(db.String(64))
    
    # User status fields
    is_active = db.Column(db.Boolean, default=True)
    is_admin = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Security related fields
    last_login = db.Column(db.DateTime)
    account_locked = db.Column(db.Boolean, default=False)
    locked_until = db.Column(db.DateTime)
    password_reset_token = db.Column(db.String(100), unique=True)
    password_reset_expires = db.Column(db.DateTime)
    
    # Relationships
    login_attempts = db.relationship('LoginAttempt', backref='user', lazy='dynamic', cascade='all, delete-orphan')
    # Other relationships will be defined in their respective models with backref
    
    @property
    def password(self):
        """Prevent password from being accessed"""
        raise AttributeError('password is not a readable attribute')
    
    @password.setter
    def password(self, password):
        """Set password hash"""
        # Generate password hash using bcrypt
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    
    def verify_password(self, password):
        """Check if password matches"""
        # Verify password against stored hash
        return bcrypt.check_password_hash(self.password_hash, password)
    
    def update_last_login(self):
        """Update last login timestamp"""
        self.last_login = datetime.utcnow()
        db.session.commit()
    
    def lock_account(self, timeout=None):
        """
        Lock account after multiple failed login attempts
        
        Args:
            timeout: Optional custom timeout in seconds
        """
        # Use default timeout from config if not specified
        if timeout is None:
            timeout = current_app.config.get('LOGIN_ATTEMPT_TIMEOUT', 15 * 60)  # Default 15 minutes
        
        # Set account as locked and calculate