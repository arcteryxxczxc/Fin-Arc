from datetime import datetime
from app import db
from passlib.hash import pbkdf2_sha256 as sha256

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(120), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(120), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    login_attempts = db.Column(db.Integer, default=0)
    locked_until = db.Column(db.DateTime, nullable=True)

    # Relationships
    expenses = db.relationship('Expense', backref='user', lazy=True, cascade='all, delete-orphan')
    incomes = db.relationship('Income', backref='user', lazy=True, cascade='all, delete-orphan')
    categories = db.relationship('Category', backref='user', lazy=True, cascade='all, delete-orphan')
    settings = db.relationship('UserSettings', backref='user', lazy=True, uselist=False, cascade='all, delete-orphan')
    
    @staticmethod
    def generate_hash(password):
        return sha256.hash(password)
    
    @staticmethod
    def verify_hash(password, hash_):
        return sha256.verify(password, hash_)

    def save_to_db(self):
        db.session.add(self)
        db.session.commit()
    
    def update_login_attempts(self, successful=True):
        if successful:
            self.login_attempts = 0
            self.locked_until = None
        else:
            self.login_attempts += 1
            if self.login_attempts >= 5:  # Lock after 5 failed attempts
                self.locked_until = datetime.utcnow() + datetime.timedelta(minutes=15)
        db.session.commit()
        
    def is_account_locked(self):
        if self.locked_until and self.locked_until > datetime.utcnow():
            return True
        return False