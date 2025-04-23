from app import db

class UserSettings(db.Model):
    __tablename__ = 'user_settings'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    default_currency = db.Column(db.String(3), default='UZS')
    notification_enabled = db.Column(db.Boolean, default=True)
    theme = db.Column(db.String(20), default='light')  # light, dark
    language = db.Column(db.String(2), default='en')   # en, ru, uz
    
    def save_to_db(self):
        db.session.add(self)
        db.session.commit()
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'default_currency': self.default_currency,
            'notification_enabled': self.notification_enabled,
            'theme': self.theme,
            'language': self.language
        }