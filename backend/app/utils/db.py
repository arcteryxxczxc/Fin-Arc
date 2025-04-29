from app import db
from functools import wraps
from sqlalchemy.exc import SQLAlchemyError
import logging

logger = logging.getLogger(__name__)

def commit_changes():
    """
    Commit changes to database with error handling
    """
    try:
        db.session.commit()
        return True
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error: {str(e)}")
        return False

def save_to_db(model):
    """
    Add model to database and commit
    """
    try:
        db.session.add(model)
        db.session.commit()
        return True
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Error saving to database: {str(e)}")
        return False

def delete_from_db(model):
    """
    Delete model from database and commit
    """
    try:
        db.session.delete(model)
        db.session.commit()
        return True
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Error deleting from database: {str(e)}")
        return False

def paginate_query(query, page=1, per_page=10):
    """
    Paginate a SQLAlchemy query
    """
    return query.paginate(page=page, per_page=per_page, error_out=False)

def get_or_create(model, **kwargs):
    """
    Get an existing row or create if it doesn't exist
    """
    instance = model.query.filter_by(**kwargs).first()
    if instance:
        return instance, False
    
    instance = model(**kwargs)
    save_to_db(instance)
    return instance, True

def safe_commit():
    """
    Safely commit changes to database with error handling
    
    Returns:
        tuple: (success, error_message)
    """
    try:
        db.session.commit()
        return True, None
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error during commit: {str(e)}")
        return False, str(e)

def transaction(func):
    """
    Decorator for functions that should run in a transaction
    Will automatically handle committing or rolling back the session
    """
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            result = func(*args, **kwargs)
            db.session.commit()
            return result
        except Exception as e:
            db.session.rollback()
            raise e
    return wrapper