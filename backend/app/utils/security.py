import secrets
import string
from flask import current_app
import re
from passlib.hash import pbkdf2_sha256

def generate_password(length=12):
    """
    Generate a secure random password
    """
    # Define character sets
    lowercase = string.ascii_lowercase
    uppercase = string.ascii_uppercase
    numbers = string.digits
    special_chars = '!@#$%^&*'
    
    # Ensure at least one of each type
    password = [
        secrets.choice(lowercase),
        secrets.choice(uppercase),
        secrets.choice(numbers),
        secrets.choice(special_chars)
    ]
    
    # Fill the rest of the password
    remaining_length = length - 4
    all_chars = lowercase + uppercase + numbers + special_chars
    password.extend(secrets.choice(all_chars) for _ in range(remaining_length))
    
    # Shuffle the password
    secrets.SystemRandom().shuffle(password)
    
    return ''.join(password)

def validate_password_strength(password):
    """
    Validate password strength against policy
    Returns (is_valid, message)
    """
    min_length = current_app.config.get('PASSWORD_MIN_LENGTH', 8)
    require_upper = current_app.config.get('PASSWORD_REQUIRE_UPPER', True)
    require_lower = current_app.config.get('PASSWORD_REQUIRE_LOWER', True)
    require_digit = current_app.config.get('PASSWORD_REQUIRE_DIGIT', True)
    require_special = current_app.config.get('PASSWORD_REQUIRE_SPECIAL', True)
    
    if len(password) < min_length:
        return False, f"Password must be at least {min_length} characters long"
    
    if require_upper and not re.search(r'[A-Z]', password):
        return False, "Password must contain at least one uppercase letter"
    
    if require_lower and not re.search(r'[a-z]', password):
        return False, "Password must contain at least one lowercase letter"
    
    if require_digit and not re.search(r'\d', password):
        return False, "Password must contain at least one digit"
    
    if require_special and not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        return False, "Password must contain at least one special character"
    
    return True, "Password meets requirements"

def sanitize_input(input_string):
    """
    Sanitize user input to prevent injection attacks
    """
    # Basic sanitization for XSS prevention
    sanitized = input_string
    sanitized = sanitized.replace('<', '&lt;')
    sanitized = sanitized.replace('>', '&gt;')
    sanitized = sanitized.replace('"', '&quot;')
    sanitized = sanitized.replace("'", '&#x27;')
    return sanitized

def generate_secure_token(length=32):
    """
    Generate a secure token for use in reset links or API keys
    """
    return secrets.token_urlsafe(length)

def hash_password(password):
    """
    Create a secure hash of a password
    """
    return pbkdf2_sha256.hash(password)

def verify_password(stored_hash, password):
    """
    Verify a password against its hash
    """
    return pbkdf2_sha256.verify(password, stored_hash)