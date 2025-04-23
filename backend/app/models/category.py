from app import db

class Category(db.Model):
    __tablename__ = 'categories'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    budget_limit = db.Column(db.Float, nullable=True)
    color_code = db.Column(db.String(7), default='#000000')  # Hex color code
    
    # Relationships
    expenses = db.relationship('Expense', backref='category', lazy=True, cascade='all, delete-orphan')
    
    def save_to_db(self):
        db.session.add(self)
        db.session.commit()
        
    def delete_from_db(self):
        db.session.delete(self)
        db.session.commit()
        
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'budget_limit': self.budget_limit,
            'color_code': self.color_code,
            'expense_count': len(self.expenses) if self.expenses else 0
        }