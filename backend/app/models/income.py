from datetime import datetime
from app import db
from sqlalchemy.sql import func

class Income(db.Model):
    """
    Income model for tracking user income sources
    """
    __tablename__ = 'incomes'
    
    id = db.Column(db.Integer, primary_key=True)
    
    # Foreign key to user
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    
    # Income details
    amount = db.Column(db.Numeric(10, 2), nullable=False)  # Using Numeric for precision
    source = db.Column(db.String(100), nullable=False)  # Income source (e.g., Salary, Freelance)
    description = db.Column(db.String(255), nullable=True)
    date = db.Column(db.Date, nullable=False, default=datetime.utcnow().date)
    
    # Income flags
    is_recurring = db.Column(db.Boolean, default=False)  # Whether this is a recurring income
    recurring_type = db.Column(db.String(20), nullable=True)  # daily, weekly, monthly, yearly
    recurring_day = db.Column(db.Integer, nullable=True)  # Day of month/week for recurring income
    
    # Category info (using income categories)
    category_id = db.Column(db.Integer, db.ForeignKey('categories.id', ondelete='SET NULL'), nullable=True)
    
    # Tax information
    is_taxable = db.Column(db.Boolean, default=True)
    tax_rate = db.Column(db.Numeric(5, 2), nullable=True)  # Tax rate percentage
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = db.relationship('User', backref=db.backref('incomes', lazy='dynamic', cascade='all, delete-orphan'))
    category = db.relationship('Category', backref=db.backref('incomes', lazy='dynamic'))
    
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
        """Return month and year of income for grouping"""
        return self.date.strftime('%Y-%m') if self.date else ''
    
    @property
    def after_tax_amount(self):
        """Calculate amount after tax deduction"""
        if not self.is_taxable or self.tax_rate is None:
            return float(self.amount)
        
        tax_deduction = float(self.amount) * (float(self.tax_rate) / 100)
        return float(self.amount) - tax_deduction
    
    @classmethod
    def get_total_by_month(cls, user_id, year=None):
        """
        Get total income grouped by month
        
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
    def get_total_by_source(cls, user_id, start_date=None, end_date=None):
        """
        Get total income grouped by source
        
        Args:
            user_id: ID of the user
            start_date: Optional start date filter
            end_date: Optional end date filter
            
        Returns:
            List of tuples with (source, total_amount)
        """
        query = db.session.query(
            cls.source,
            func.sum(cls.amount).label('total')
        ).filter(
            cls.user_id == user_id
        ).group_by(
            cls.source
        )
        
        if start_date:
            query = query.filter(cls.date >= start_date)
        
        if end_date:
            query = query.filter(cls.date <= end_date)
        
        return query.all()
    
    @classmethod
    def get_recent_incomes(cls, user_id, limit=5):
        """
        Get most recent incomes for a user
        
        Args:
            user_id: ID of the user
            limit: Number of incomes to return
            
        Returns:
            List of Income objects
        """
        return cls.query.filter_by(
            user_id=user_id
        ).order_by(
            cls.date.desc(),
            cls.id.desc()
        ).limit(limit).all()
    
    @classmethod
    def calculate_monthly_average(cls, user_id, months=3):
        """
        Calculate average monthly income based on recent months
        
        Args:
            user_id: ID of the user
            months: Number of months to consider
            
        Returns:
            Float representing average monthly income
        """
        # Get current date
        now = datetime.utcnow()
        
        # Calculate start date (months ago from start of current month)
        start_month = now.month - months
        start_year = now.year
        
        # Adjust year if we went back to previous year
        while start_month <= 0:
            start_month += 12
            start_year -= 1
            
        start_date = datetime(start_year, start_month, 1).date()
        
        # Query for total income since start date
        total = db.session.query(func.sum(cls.amount)).filter(
            cls.user_id == user_id,
            cls.date >= start_date
        ).scalar() or 0
        
        # Return average
        return float(total) / months
    
    def save_to_db(self):
        """Save income to database"""
        db.session.add(self)
        db.session.commit()
        
    def delete_from_db(self):
        """Delete income from database"""
        db.session.delete(self)
        db.session.commit()
    
    def __repr__(self):
        """String representation of the Income object"""
        return f'<Income {self.id}: {self.formatted_amount} from {self.source} on {self.formatted_date}>'