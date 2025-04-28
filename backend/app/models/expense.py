# backend/models/expense.py

from datetime import datetime
from backend.app import db
from sqlalchemy.sql import func

class Expense(db.Model):
    """
    Expense model for tracking user expenses
    Includes relationship to users and categories
    """
    __tablename__ = 'expenses'
    
    id = db.Column(db.Integer, primary_key=True)
    
    # Foreign keys
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey('categories.id', ondelete='SET NULL'), nullable=True)
    
    # Expense details
    amount = db.Column(db.Numeric(10, 2), nullable=False)  # Using Numeric for precision
    description = db.Column(db.String(255), nullable=True)
    date = db.Column(db.Date, nullable=False, default=datetime.utcnow().date)
    time = db.Column(db.Time, nullable=True, default=datetime.utcnow().time)
    
    # Location information (optional)
    location = db.Column(db.String(255), nullable=True)
    
    # Payment method
    payment_method = db.Column(db.String(50), nullable=True)  # e.g., cash, credit card, debit card
    
    # Receipt information
    has_receipt = db.Column(db.Boolean, default=False)
    receipt_path = db.Column(db.String(255), nullable=True)
    
    # Flags and notes
    is_recurring = db.Column(db.Boolean, default=False)
    recurring_type = db.Column(db.String(20), nullable=True)  # daily, weekly, monthly, yearly
    notes = db.Column(db.Text, nullable=True)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = db.relationship('User', backref=db.backref('expenses', lazy='dynamic', cascade='all, delete-orphan'))
    category = db.relationship('Category', backref=db.backref('expenses', lazy='dynamic'))
    
    @property
    def formatted_amount(self):
        """Return amount formatted as string with 2 decimal places"""
        return "{:.2f}".format(float(self.amount))
    
    @property
    def formatted_date(self):
        """Return date formatted as string"""
        return self.date.strftime('%Y-%m-%d') if self.date else ''
    
    @property
    def month_year(self):
        """Return month and year of expense for grouping"""
        return self.date.strftime('%Y-%m') if self.date else ''
    
    @property
    def is_overdue(self):
        """Check if a recurring expense is overdue"""
        if not self.is_recurring:
            return False
            
        # Implementation depends on recurring expense logic
        # Would require additional tracking of last payment date
        return False
    
    @classmethod
    def get_total_by_category(cls, user_id, start_date=None, end_date=None):
        """
        Get total expenses grouped by category
        
        Args:
            user_id: ID of the user
            start_date: Optional start date filter
            end_date: Optional end date filter
            
        Returns:
            List of tuples with (category_id, category_name, total_amount)
        """
        query = db.session.query(
            cls.category_id,
            Category.name,
            func.sum(cls.amount).label('total')
        ).join(
            Category, cls.category_id == Category.id, isouter=True
        ).filter(
            cls.user_id == user_id
        ).group_by(
            cls.category_id,
            Category.name
        )
        
        if start_date:
            query = query.filter(cls.date >= start_date)
        
        if end_date:
            query = query.filter(cls.date <= end_date)
        
        return query.all()
    
    @classmethod
    def get_total_by_month(cls, user_id, year=None):
        """
        Get total expenses grouped by month
        
        Args:
            user_id: ID of the user
            year: Optional year filter
            
        Returns:
            List of tuples with (month, total_amount)
        """
        # Extract month from date for grouping
        month_extract = func.date_trunc('month', cls.date).label('month')
        
        query = db.session.query(
            month_extract,
            func.sum(cls.amount).label('total')
        ).filter(
            cls.user_id == user_id
        ).group_by(
            month_extract
        ).order_by(
            month_extract
        )
        
        if year:
            query = query.filter(func.extract('year', cls.date) == year)
        
        return query.all()
    
    @classmethod
    def get_recent_expenses(cls, user_id, limit=5):
        """
        Get most recent expenses for a user
        
        Args:
            user_id: ID of the user
            limit: Number of expenses to return
            
        Returns:
            List of Expense objects
        """
        return cls.query.filter_by(
            user_id=user_id
        ).order_by(
            cls.date.desc(),
            cls.time.desc() if cls.time else cls.id.desc()
        ).limit(limit).all()
    
    def __repr__(self):
        """String representation of the Expense object"""
        return f'<Expense {self.id}: {self.formatted_amount} on {self.formatted_date}>'


# Import Category here at the bottom to avoid circular imports
from backend.models.category import Category