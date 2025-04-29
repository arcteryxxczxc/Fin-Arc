# backend/app/models/report.py
from datetime import datetime
from app import db
from sqlalchemy.sql import func

class Report(db.Model):
    """
    Report model for storing saved/generated reports
    """
    __tablename__ = 'reports'
    
    id = db.Column(db.Integer, primary_key=True)
    
    # Foreign key to user
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    
    # Report details
    name = db.Column(db.String(100), nullable=False)
    type = db.Column(db.String(50), nullable=False)  # 'monthly', 'annual', 'cashflow', 'budget'
    parameters = db.Column(db.JSON, nullable=True)   # Store report parameters as JSON
    data = db.Column(db.JSON, nullable=True)         # Store report data as JSON
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = db.relationship('User', backref=db.backref('reports', lazy='dynamic', cascade='all, delete-orphan'))
    
    def save_to_db(self):
        """Save report to database"""
        db.session.add(self)
        db.session.commit()
        
    def delete_from_db(self):
        """Delete report from database"""
        db.session.delete(self)
        db.session.commit()
    
    def to_dict(self):
        """Convert report to dictionary for API responses"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'type': self.type,
            'parameters': self.parameters,
            'created_at': self.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'updated_at': self.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        }
    
    def __repr__(self):
        """String representation of the Report object"""
        return f'<Report {self.id}: {self.name} ({self.type})>'