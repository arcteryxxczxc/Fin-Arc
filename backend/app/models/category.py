# backend/models/category.py

from datetime import datetime
from backend.app import db
from sqlalchemy.sql import func

class Category(db.Model):
    """
    Category model for expense categorization
    Allows users to create custom categories with budget limits
    """
    __tablename__ = 'categories'
    
    id = db.Column(db.Integer, primary_key=True)
    
    # Foreign key to user
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    
    # Category details
    name = db.Column(db.String(50), nullable=False)
    description = db.Column(db.String(255), nullable=True)
    color_code = db.Column(db.String(7), nullable=False, default='#757575')  # Hex color code
    icon = db.Column(db.String(50), nullable=True)  # Font Awesome icon name
    
    # Budget settings
    budget_limit = db.Column(db.Numeric(10, 2), nullable=True)  # Monthly budget limit
    budget_start_day = db.Column(db.Integer, default=1)  # Day of month when budget resets
    
    # Category flags
    is_default = db.Column(db.Boolean, default=False)  # Whether this is a system default category
    is_active = db.Column(db.Boolean, default=True)  # Whether this category is active
    is_income = db.Column(db.Boolean, default=False)  # Whether this is an income category
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = db.relationship('User', backref=db.backref('categories', lazy='dynamic', cascade='all, delete-orphan'))
    
    # Add unique constraint to prevent duplicate category names for the same user
    __table_args__ = (
        db.UniqueConstraint('user_id', 'name', name='_user_category_uc'),
    )
    
    @property
    def formatted_budget(self):
        """Return budget formatted as string with 2 decimal places"""
        if self.budget_limit is None:
            return "No limit"
        return "{:.2f}".format(float(self.budget_limit))
    
    @property
    def current_spending(self):
        """Calculate current month's spending for this category"""
        # Get current month's start and end dates
        now = datetime.utcnow()
        
        # If budget starts on a specific day, adjust the month range
        if self.budget_start_day > 1:
            # If today is before budget start day, use previous month's start day
            if now.day < self.budget_start_day:
                if now.month == 1:  # January
                    start_date = datetime(now.year - 1, 12, self.budget_start_day).date()
                else:
                    start_date = datetime(now.year, now.month - 1, self.budget_start_day).date()
            else:
                # Use current month's start day
                start_date = datetime(now.year, now.month, self.budget_start_day).date()
                
            # End date is next month's start day minus 1
            if now.month == 12:  # December
                end_month = 1
                end_year = now.year + 1
            else:
                end_month = now.month + 1
                end_year = now.year
                
            # Check if the day exists in end month (handle months with fewer days)
            import calendar
            _, days_in_month = calendar.monthrange(end_year, end_month)
            end_day = min(self.budget_start_day - 1, days_in_month)
            end_date = datetime(end_year, end_month, end_day).date()
        else:
            # Simple month-based range (1st to end of month)
            import calendar
            _, days_in_month = calendar.monthrange(now.year, now.month)
            start_date = datetime(now.year, now.month, 1).date()
            end_date = datetime(now.year, now.month, days_in_month).date()
        
        # Query for expenses in this category within the date range
        from backend.models.expense import Expense
        total = db.session.query(func.sum(Expense.amount)).filter(
            Expense.category_id == self.id,
            Expense.date >= start_date,
            Expense.date <= end_date
        ).scalar() or 0
        
        return float(total)
    
    @property
    def budget_percentage(self):
        """Calculate percentage of budget used"""
        if self.budget_limit is None or float(self.budget_limit) == 0:
            return 0
        
        spending = self.current_spending
        percentage = (spending / float(self.budget_limit)) * 100
        return min(percentage, 100)  # Cap at 100%
    
    @property
    def budget_status(self):
        """Get budget status (under, near, over)"""
        if self.budget_limit is None:
            return "no_limit"
        
        percentage = self.budget_percentage
        
        if percentage >= 100:
            return "over_budget"
        elif percentage >= 90:
            return "near_limit"
        else:
            return "under_budget"
    
    @classmethod
    def get_or_create_default_categories(cls, user_id):
        """
        Create default categories for a new user if they don't exist
        
        Args:
            user_id: ID of the user
            
        Returns:
            List of created Category objects
        """
        from backend.app import current_app
        
        # Check if user already has categories
        existing_categories = cls.query.filter_by(user_id=user_id).count()
        if existing_categories > 0:
            return []
        
        # Get default categories from config
        default_categories = current_app.config.get('DEFAULT_CATEGORIES', [])
        created_categories = []
        
        for category_data in default_categories:
            category = cls(
                user_id=user_id,
                name=category_data.get('name'),
                color_code=category_data.get('color_code', '#757575'),
                is_default=True,
                is_active=True
            )
            db.session.add(category)
            created_categories.append(category)
        
        db.session.commit()
        return created_categories
    
    @classmethod
    def get_user_categories(cls, user_id, include_inactive=False, only_expense=True):
        """
        Get categories for a specific user
        
        Args:
            user_id: ID of the user
            include_inactive: Whether to include inactive categories
            only_expense: Whether to only include expense categories (not income)
            
        Returns:
            List of Category objects
        """
        query = cls.query.filter_by(user_id=user_id)
        
        if not include_inactive:
            query = query.filter_by(is_active=True)
            
        if only_expense:
            query = query.filter_by(is_income=False)
            
        return query.order_by(cls.name).all()
    
    def __repr__(self):
        """String representation of the Category object"""
        return f'<Category {self.id}: {self.name}>'