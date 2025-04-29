from app import create_app, db
from app.models import User, Category, Expense, Income

def init_db():
    app = create_app()
    with app.app_context():
        db.create_all()
        
        # Create default categories if they don't exist
        default_categories = [
            {"name": "Food", "color_code": "#FF5733"},
            {"name": "Transport", "color_code": "#33FF57"},
            {"name": "Entertainment", "color_code": "#3357FF"},
            {"name": "Utilities", "color_code": "#F3FF33"},
            {"name": "Shopping", "color_code": "#FF33F6"}
        ]
        
        # Check if there's a test user
        test_user = User.query.filter_by(username="test_user").first()
        if not test_user:
            # Create a test user
            test_user = User(
                username="test_user",
                email="test@example.com",
                first_name="Test",
                last_name="User"
            )
            test_user.password = "password123"
            db.session.add(test_user)
            db.session.commit()
            
            # Add default categories for test user
            for cat in default_categories:
                category = Category(
                    user_id=test_user.id,
                    name=cat["name"],
                    color_code=cat["color_code"]
                )
                db.session.add(category)
            
            db.session.commit()
            print("Database initialized with test user and default categories.")
        else:
            print("Database already contains test data.")

if __name__ == "__main__":
    init_db()