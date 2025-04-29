# backend/app/utils/validation.py
from flask import request
from jsonschema import validate, ValidationError
import logging

logger = logging.getLogger(__name__)

def validate_json(schema):
    """
    Decorator to validate JSON request data against a schema
    
    Args:
        schema: JSON schema to validate against
        
    Returns:
        Decorator function
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Get JSON data from request
            data = request.get_json()
            
            if not data:
                return jsonify({"error": "Missing JSON in request"}), 400
            
            try:
                validate(instance=data, schema=schema)
            except ValidationError as e:
                logger.warning(f"JSON validation error: {str(e)}")
                return jsonify({"error": f"Validation error: {str(e.message)}"}), 400
                
            return func(*args, **kwargs)
        return wrapper
    return decorator

# Example schema for expense creation
EXPENSE_SCHEMA = {
    "type": "object",
    "required": ["amount"],
    "properties": {
        "amount": {"type": "number", "minimum": 0.01},
        "description": {"type": "string"},
        "date": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$"},
        "category_id": {"type": ["integer", "null"]},
        "payment_method": {"type": ["string", "null"]},
        "location": {"type": ["string", "null"]},
        "is_recurring": {"type": "boolean"},
        "recurring_type": {"type": ["string", "null"]},
        "notes": {"type": ["string", "null"]}
    }
}