from app import db
from app.models.category import Category
from app.models.expense import Expense
from datetime import datetime, timedelta
from sqlalchemy import func

class BudgetNotification(db.Model):
    """
    Budget notification model for tracking budget alerts
    
    This model stores notifications related to budget limits and alerts
    users when they approach or exceed their budget limits.
    """
    __tablename__ = 'budget_notifications'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey('categories.id', ondelete='CASCADE'), nullable=False)
    message = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_read = db.Column(db.Boolean, default=False)
    
    # Relationships
    user = db.relationship('User', backref=db.backref('budget_notifications', lazy='dynamic', cascade='all, delete-orphan'))
    category = db.relationship('Category', backref=db.backref('notifications', lazy='dynamic'))
    
    def save_to_db(self):
        """Save notification to database"""
        db.session.add(self)
        db.session.commit()
    
    def mark_as_read(self):
        """Mark notification as read"""
        self.is_read = True
        db.session.commit()
    
    def to_dict(self):
        """Convert notification to dictionary for API responses"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'category_id': self.category_id,
            'category_name': self.category.name if self.category else "Unknown",
            'message': self.message,
            'created_at': self.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'is_read': self.is_read
        }
    
    def __repr__(self):
        """String representation of the BudgetNotification object"""
        return f'<BudgetNotification {self.id}: {self.message[:30]}... for user_id={self.user_id}>'


class NotificationService:
    """Service for managing budget notifications"""
    
    @staticmethod
    def check_budget_limits(user_id):
        """
        Check if any category is over budget and create notifications
        
        Args:
            user_id: ID of the user
            
        Returns:
            List of created BudgetNotification objects
        """
        # Get current month
        today = datetime.utcnow()
        first_day = datetime(today.year, today.month, 1)
        
        # Get all categories with budget limits for this user
        categories = Category.query.filter(
            Category.user_id == user_id,
            Category.budget_limit.isnot(None)
        ).all()
        
        notifications = []
        
        for category in categories:
            # Sum expenses for this category this month
            total_expense = db.session.query(func.sum(Expense.amount)).filter(
                Expense.user_id == user_id,
                Expense.category_id == category.id,
                Expense.date >= first_day
            ).scalar() or 0
            
            # Calculate percentage of budget used
            budget_used_percent = (float(total_expense) / float(category.budget_limit)) * 100
            
            # Check thresholds and create notifications
            thresholds = [
                (90, f"You've used 90% of your {category.name} budget this month."),
                (100, f"You've reached your {category.name} budget limit for this month!")
            ]
            
            for threshold, message in thresholds:
                if budget_used_percent >= threshold:
                    # Check if notification already exists
                    existing = BudgetNotification.query.filter(
                        BudgetNotification.user_id == user_id,
                        BudgetNotification.category_id == category.id,
                        BudgetNotification.message == message,
                        BudgetNotification.created_at >= first_day
                    ).first()
                    
                    if not existing:
                        notification = BudgetNotification(
                            user_id=user_id,
                            category_id=category.id,
                            message=message
                        )
                        notification.save_to_db()
                        notifications.append(notification)
        
        return notifications
    
    @staticmethod
    def get_user_notifications(user_id, unread_only=False):
        """
        Get all notifications for a user
        
        Args:
            user_id: ID of the user
            unread_only: Whether to return only unread notifications
            
        Returns:
            List of BudgetNotification objects
        """
        query = BudgetNotification.query.filter(BudgetNotification.user_id == user_id)
        
        if unread_only:
            query = query.filter(BudgetNotification.is_read == False)
        
        notifications = query.order_by(BudgetNotification.created_at.desc()).all()
        return notifications
    
    @staticmethod
    def mark_notification_as_read(notification_id, user_id):
        """
        Mark a notification as read
        
        Args:
            notification_id: ID of the notification
            user_id: ID of the user (for security)
            
        Returns:
            bool: True if notification was marked as read, False otherwise
        """
        notification = BudgetNotification.query.filter_by(id=notification_id, user_id=user_id).first()
        if notification:
            notification.mark_as_read()
            return True
        return False
    
    @staticmethod
    def mark_all_as_read(user_id):
        """
        Mark all notifications for a user as read
        
        Args:
            user_id: ID of the user
            
        Returns:
            int: Number of notifications marked as read
        """
        notifications = BudgetNotification.query.filter_by(
            user_id=user_id, 
            is_read=False
        ).all()
        
        count = 0
        for notification in notifications:
            notification.is_read = True
            count += 1
        
        db.session.commit()
        return count