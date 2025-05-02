#!/usr/bin/env python3
"""
Initialize the database for the Fin-Arc application
- Creates tables if they don't exist
- Adds default categories
- Creates a test user if specified
"""

import os
import sys
import logging
from sqlalchemy.exc import SQLAlchemyError
from dotenv import load_dotenv

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Add parent directory to path to allow imports
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

# Load environment variables
load_dotenv()

# Import app components
from app import create_app, db
from app.models import User, Category, Expense, Income

def init_db(create_test_user=True):
    """Initialize the database with tables and default data"""
    logger.info("Starting database initialization...")
    
    # Create Flask app with application context
    app = create_app()
    
    with app.app_context():
        try:
            # Create all tables
            db.create_all()
            logger.info("Database tables created successfully")
            
            # Create default categories if they don't exist
            default_categories = [
                {"name": "Food", "color_code": "#FF5733", "icon": "restaurant"},
                {"name": "Transport", "color_code": "#33FF57", "icon": "directions_car"},
                {"name": "Entertainment", "color_code": "#3357FF", "icon": "movie"},
                {"name": "Utilities", "color_code": "#F3FF33", "icon": "power"},
                {"name": "Shopping", "color_code": "#FF33F6", "icon": "shopping_bag"},
                {"name": "Housing", "color_code": "#33FFF6", "icon": "home"},
                {"name": "Health", "color_code": "#FF3333", "icon": "local_hospital"},
                {"name": "Education", "color_code": "#8333FF", "icon": "school"},
                {"name": "Salary", "color_code": "#33FF33", "icon": "work", "is_income": True},
                {"name": "Investment", "color_code": "#FFCC33", "icon": "trending_up", "is_income": True}
            ]
            
            if create_test_user:
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
                    logger.info(f"Created test user: {test_user.username}")
                    
                    # Add default categories for test user
                    for cat in default_categories:
                        is_income = cat.get("is_income", False)
                        category = Category(
                            user_id=test_user.id,
                            name=cat["name"],
                            color_code=cat["color_code"],
                            icon=cat.get("icon"),
                            is_income=is_income
                        )
                        db.session.add(category)
                    
                    db.session.commit()
                    logger.info(f"Added {len(default_categories)} default categories for test user")
                    
                    # Add sample data
                    # TODO: Add sample expenses and income entries
                    
                else:
                    logger.info(f"Test user '{test_user.username}' already exists")
                    
                    # Check if the test user has categories
                    cat_count = Category.query.filter_by(user_id=test_user.id).count()
                    if cat_count == 0:
                        # Add default categories for test user
                        for cat in default_categories:
                            is_income = cat.get("is_income", False)
                            category = Category(
                                user_id=test_user.id,
                                name=cat["name"],
                                color_code=cat["color_code"],
                                icon=cat.get("icon"),
                                is_income=is_income
                            )
                            db.session.add(category)
                        
                        db.session.commit()
                        logger.info(f"Added {len(default_categories)} default categories for existing test user")
            
            logger.info("Database initialization completed successfully!")
            
        except SQLAlchemyError as e:
            db.session.rollback()
            logger.error(f"Database error during initialization: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Error during database initialization: {str(e)}")
            raise

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Initialize the Fin-Arc database.')
    parser.add_argument('--no-test-user', action='store_true', help='Skip creating test user')
    parser.add_argument('--reset', action='store_true', help='Reset the database (drop all tables)')
    
    args = parser.parse_args()
    
    # Create Flask app for database reset if needed
    if args.reset:
        app = create_app()
        with app.app_context():
            logger.warning("Dropping all database tables!")
            db.drop_all()
            logger.info("All tables dropped successfully")
    
    # Initialize the database
    init_db(create_test_user=not args.no_test_user)