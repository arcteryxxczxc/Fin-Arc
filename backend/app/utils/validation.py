from flask import request, jsonify
from jsonschema import validate, ValidationError
from functools import wraps
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

# Schema definitions for API endpoints
EXPENSE_SCHEMA = {
    "type": "object",
    "required": ["amount"],
    "properties": {
        "amount": {"type": "number", "minimum": 0.01},
        "description": {"type": ["string", "null"]},
        "date": {"type": ["string", "null"], "pattern": "^\\d{4}-\\d{2}-\\d{2}$"},
        "time": {"type": ["string", "null"], "pattern": "^\\d{2}:\\d{2}$"},
        "category_id": {"type": ["integer", "null"]},
        "payment_method": {"type": ["string", "null"]},
        "location": {"type": ["string", "null"]},
        "is_recurring": {"type": "boolean"},
        "recurring_type": {"type": ["string", "null"]},
        "notes": {"type": ["string", "null"]}
    }
}

INCOME_SCHEMA = {
    "type": "object",
    "required": ["amount", "source"],
    "properties": {
        "amount": {"type": "number", "minimum": 0.01},
        "source": {"type": "string", "minLength": 1},
        "description": {"type": ["string", "null"]},
        "date": {"type": ["string", "null"], "pattern": "^\\d{4}-\\d{2}-\\d{2}$"},
        "category_id": {"type": ["integer", "null"]},
        "is_recurring": {"type": "boolean"},
        "recurring_type": {"type": ["string", "null"]},
        "recurring_day": {"type": ["integer", "null"], "minimum": 1, "maximum": 31},
        "is_taxable": {"type": "boolean"},
        "tax_rate": {"type": ["number", "null"], "minimum": 0, "maximum": 100}
    }
}

CATEGORY_SCHEMA = {
    "type": "object",
    "required": ["name"],
    "properties": {
        "name": {"type": "string", "minLength": 1, "maxLength": 50},
        "description": {"type": ["string", "null"]},
        "color_code": {"type": "string", "pattern": "^#([A-Fa-f0-9]{3}|[A-Fa-f0-9]{6})$"},
        "icon": {"type": ["string", "null"]},
        "budget_limit": {"type": ["number", "null"], "minimum": 0},
        "budget_start_day": {"type": ["integer", "null"], "minimum": 1, "maximum": 31},
        "is_income": {"type": "boolean"},
        "is_active": {"type": "boolean"}
    }
}

USER_SCHEMA = {
    "type": "object",
    "required": ["username", "email", "password"],
    "properties": {
        "username": {"type": "string", "minLength": 3, "maxLength": 64},
        "email": {"type": "string", "format": "email", "maxLength": 120},
        "password": {"type": "string", "minLength": 8},
        "first_name": {"type": ["string", "null"], "maxLength": 64},
        "last_name": {"type": ["string", "null"], "maxLength": 64}
    }
}

LOGIN_SCHEMA = {
    "type": "object",
    "required": ["username", "password"],
    "properties": {
        "username": {"type": "string"},
        "password": {"type": "string"}
    }
}

PASSWORD_CHANGE_SCHEMA = {
    "type": "object",
    "required": ["current_password", "new_password"],
    "properties": {
        "current_password": {"type": "string"},
        "new_password": {"type": "string", "minLength": 8}
    }
}

USER_SETTINGS_SCHEMA = {
    "type": "object",
    "properties": {
        "default_currency": {"type": ["string", "null"], "minLength": 3, "maxLength": 3},
        "notification_enabled": {"type": "boolean"},
        "theme": {"type": ["string", "null"]},
        "language": {"type": ["string", "null"]}
    }
}