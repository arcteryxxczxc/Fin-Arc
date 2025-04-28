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
        
        # Set account as locked and calculate lock expiration time
        self.account_locked = True
        self.locked_until = datetime.utcnow() + timedelta(seconds=timeout)
        db.session.commit()
    
    def unlock_account(self):
        """Unlock account"""
        self.account_locked = False
        self.locked_until = None
        db.session.commit()
    
    def is_account_locked(self):
        """
        Check if account is currently locked
        
        Returns:
            bool: True if account is locked, False otherwise
        """
        if not self.account_locked:
            return False
        
        # If lock period has expired, unlock account
        if self.locked_until and datetime.utcnow() > self.locked_until:
            self.unlock_account()
            return False
            
        return self.account_locked
    
    def update_login_attempts(self, successful=False):
        """
        Update login attempts and handle account locking if needed
        
        Args:
            successful: Whether the login attempt was successful
        """
        # Record the login attempt
        attempt = LoginAttempt(
            user_id=self.id,
            ip_address=None,  # Would be set from request in route
            user_agent=None,  # Would be set from request in route
            success=successful
        )
        db.session.add(attempt)
        
        if successful:
            # Reset failed attempts counter by clearing old records
            # This approach keeps the history but no longer counts old attempts
            self.update_last_login()
        else:
            # Check for max attempts
            max_attempts = current_app.config.get('MAX_LOGIN_ATTEMPTS', 5)
            
            # Count recent failed attempts (last hour)
            one_hour_ago = datetime.utcnow() - timedelta(hours=1)
            recent_failed_attempts = LoginAttempt.query.filter(
                LoginAttempt.user_id == self.id,
                LoginAttempt.success == False,
                LoginAttempt.timestamp > one_hour_ago
            ).count()
            
            # Lock account if max attempts reached
            if recent_failed_attempts >= max_attempts:
                self.lock_account()
            else:
                # Ensure any changes are saved
                db.session.commit()
    
    def generate_reset_token(self, expiration=3600):
        """
        Generate a secure token for password reset
        
        Args:
            expiration: Token expiration time in seconds (default: 1 hour)
            
        Returns:
            str: Reset token
        """
        import secrets
        
        # Generate a secure token
        self.password_reset_token = secrets.token_urlsafe(32)
        self.password_reset_expires = datetime.utcnow() + timedelta(seconds=expiration)
        db.session.commit()
        
        return self.password_reset_token
    
    @staticmethod
    def verify_reset_token(token):
        """
        Verify a password reset token
        
        Args:
            token: The token to verify
            
        Returns:
            User: User object if token is valid, None otherwise
        """
        user = User.query.filter_by(password_reset_token=token).first()
        
        if not user or not user.password_reset_expires:
            return None
            
        if datetime.utcnow() > user.password_reset_expires:
            return None
            
        return user
    
    def clear_reset_token(self):
        """Clear password reset token after use"""
        self.password_reset_token = None
        self.password_reset_expires = None
        db.session.commit()
    
    # Financial statistics methods
    @property
    def total_expenses_current_month(self):
        """Calculate total expenses for current month"""
        from app.models.expense import Expense
        import calendar
    
        now = datetime.utcnow()
        _, days_in_month = calendar.monthrange(now.year, now.month)
        start_date = datetime(now.year, now.month, 1).date()
        end_date = datetime(now.year, now.month, days_in_month).date()
    
        total = db.session.query(func.sum(Expense.amount)).filter(
            Expense.user_id == self.id,
            Expense.date >= start_date,
            Expense.date <= end_date
        ).scalar() or 0
    
        return float(total)

    @property
    def total_income_current_month(self):
        """Calculate total income for current month"""
        from app.models.income import Income
        import calendar
        
        now = datetime.utcnow()
        _, days_in_month = calendar.monthrange(now.year, now.month)
        start_date = datetime(now.year, now.month, 1).date()
        end_date = datetime(now.year, now.month, days_in_month).date()
        
        total = db.session.query(func.sum(Income.amount)).filter(
            Income.user_id == self.id,
            Income.date >= start_date,
            Income.date <= end_date
        ).scalar() or 0
        
        return float(total)

    @property
    def current_month_balance(self):
        """Calculate balance (income - expenses) for current month"""
        return self.total_income_current_month - self.total_expenses_current_month

    @property
    def expense_categories_with_budget(self):
        """Get all expense categories that have budget limits set"""
        from app.models.category import Category
        
        return Category.query.filter(
            Category.user_id == self.id,
            Category.is_active == True,
            Category.is_income == False,
            Category.budget_limit.isnot(None)
        ).all()

    def get_expense_category_breakdown(self, start_date=None, end_date=None):
        """Get breakdown of expenses by category for a date range"""
        from app.models.expense import Expense
        
        return Expense.get_total_by_category(self.id, start_date, end_date)

    def get_income_source_breakdown(self, start_date=None, end_date=None):
        """Get breakdown of income by source for a date range"""
        from app.models.income import Income
        
        return Income.get_total_by_source(self.id, start_date, end_date)

    def get_monthly_expense_trend(self, months=6):
        """Get expense trend for the last X months"""
        from app.models.expense import Expense
        
        # Get expense totals by month
        return Expense.get_total_by_month(self.id, None)  # passing None gets all years

    def get_monthly_income_trend(self, months=6):
        """Get income trend for the last X months"""
        from app.models.income import Income
        
        # Get income totals by month
        return Income.get_total_by_month(self.id, None)  # passing None gets all years

    def get_savings_rate(self, months=3):
        """Calculate savings rate (income - expenses) / income for recent months"""
        from app.models.expense import Expense
        from app.models.income import Income
        
        # Calculate start date (months ago)
        now = datetime.utcnow()
        start_month = now.month - months
        start_year = now.year
        
        # Adjust for previous year
        while start_month <= 0:
            start_month += 12
            start_year -= 1
            
        start_date = datetime(start_year, start_month, 1).date()
        
        # Get total income and expenses
        total_income = db.session.query(func.sum(Income.amount)).filter(
            Income.user_id == self.id,
            Income.date >= start_date
        ).scalar() or 0
        
        total_expenses = db.session.query(func.sum(Expense.amount)).filter(
            Expense.user_id == self.id,
            Expense.date >= start_date
        ).scalar() or 0
        
        # Calculate savings rate
        if float(total_income) == 0:
            return 0
        
        savings = float(total_income) - float(total_expenses)
        savings_rate = (savings / float(total_income)) * 100
        
        return max(0, savings_rate)  # Ensure we don't return negative savings rate

    def save_to_db(self):
        """Save user to database"""
        db.session.add(self)
        db.session.commit()

    def __repr__(self):
        """String representation of the User object"""
        return f'<User {self.username}>'


class LoginAttempt(db.Model):
    """
    Track login attempts for security monitoring and account lockout
    """
    __tablename__ = 'login_attempts'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    ip_address = db.Column(db.String(45))  # IPv6 can be up to 45 chars
    user_agent = db.Column(db.String(255))
    success = db.Column(db.Boolean, default=False)
    
    @classmethod
    def add_login_attempt(cls, user, ip_address, user_agent, success):
        """
        Record a login attempt
        
        Args:
            user: User object
            ip_address: IP address of the request
            user_agent: User agent string
            success: Whether the login was successful
        """
        # Create a new login attempt record
        attempt = cls(
            user_id=user.id,
            ip_address=ip_address,
            user_agent=user_agent,
            success=success
        )
        db.session.add(attempt)
        db.session.commit()
        
        # If login failed and max attempts reached, lock account
        if not success and user.has_reached_max_login_attempts():
            user.lock_account()
    
    def __repr__(self):
        """String representation of the LoginAttempt object"""
        status = "Success" if self.success else "Failure"
        return f'<LoginAttempt {status} for User {self.user_id} at {self.timestamp}>'