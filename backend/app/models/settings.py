from app import db

class UserSettings(db.Model):
    """
    User settings model for storing application preferences
    
    This model stores user-specific settings like default currency,
    notification preferences, theme, and language.
    """
    __tablename__ = 'user_settings'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    default_currency = db.Column(db.String(3), default='UZS')
    notification_enabled = db.Column(db.Boolean, default=True)
    theme = db.Column(db.String(20), default='light')  # light, dark
    language = db.Column(db.String(2), default='en')   # en, ru, uz
    
    # Relationships
    user = db.relationship('User', backref=db.backref('settings', uselist=False, cascade='all, delete-orphan'))
    
    def save_to_db(self):
        """Save settings to database"""
        db.session.add(self)
        db.session.commit()
    
    def to_dict(self):
        """Convert settings to dictionary for API responses"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'default_currency': self.default_currency,
            'notification_enabled': self.notification_enabled,
            'theme': self.theme,
            'language': self.language
        }
        
    @classmethod
    def get_or_create(cls, user_id):
        """
        Get existing settings for a user or create new default settings
        
        Args:
            user_id: ID of the user
            
        Returns:
            UserSettings object
        """
        settings = cls.query.filter_by(user_id=user_id).first()
        
        if not settings:
            settings = cls(user_id=user_id)
            settings.save_to_db()
            
        return settings
    
    def __repr__(self):
        """String representation of the UserSettings object"""
        return f'<UserSettings for user_id={self.user_id}>'