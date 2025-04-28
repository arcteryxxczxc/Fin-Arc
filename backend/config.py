import os
from datetime import timedelta

class Config:
    """Base configuration"""
    # Secret key for session management and CSRF protection
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'you-will-never-guess'
    
    # Database configuration
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
        'postgresql://postgres:postgres@localhost/fin_arc'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # JWT settings
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'jwt-secret-key-change-in-production'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    
    # Security settings
    SESSION_COOKIE_SECURE = True  # Only send cookies over HTTPS
    SESSION_COOKIE_HTTPONLY = True  # Prevent JavaScript access to session cookie
    PERMANENT_SESSION_LIFETIME = timedelta(days=30)  # Session expiration
    
    # Password policy
    PASSWORD_MIN_LENGTH = 8
    PASSWORD_REQUIRE_UPPER = True
    PASSWORD_REQUIRE_LOWER = True
    PASSWORD_REQUIRE_DIGIT = True
    PASSWORD_REQUIRE_SPECIAL = True
    
    # Login security
    MAX_LOGIN_ATTEMPTS = 5  # Maximum number of failed login attempts
    LOGIN_ATTEMPT_TIMEOUT = 15 * 60  # Lockout period in seconds (15 minutes)
    
    # Upload settings
    UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16 MB max upload size
    
    # Application defaults
    DEFAULT_CATEGORIES = [
        {'name': 'Food', 'color_code': '#4285F4'},
        {'name': 'Transportation', 'color_code': '#EA4335'},
        {'name': 'Housing', 'color_code': '#FBBC05'},
        {'name': 'Entertainment', 'color_code': '#34A853'},
        {'name': 'Utilities', 'color_code': '#FF6D01'},
        {'name': 'Healthcare', 'color_code': '#46BDC6'},
        {'name': 'Education', 'color_code': '#7B1FA2'},
        {'name': 'Shopping', 'color_code': '#C2185B'},
        {'name': 'Other', 'color_code': '#757575'}
    ]
    
    # Default dark blue theme colors
    PRIMARY_COLOR = '#001F3F'
    SECONDARY_COLOR = '#0074D9'
    ACCENT_COLOR = '#39CCCC'
    SUCCESS_COLOR = '#2ECC40'
    DANGER_COLOR = '#FF4136'
    WARNING_COLOR = '#FFDC00'
    INFO_COLOR = '#7FDBFF'


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    TESTING = False
    SESSION_COOKIE_SECURE = False  # Allow HTTP in development
    
    # Override database URI for development
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
        'postgresql://postgres:postgres@localhost/fin_arc_dev'
    

class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'  # Use in-memory database for tests
    WTF_CSRF_ENABLED = False  # Disable CSRF during tests
    SESSION_COOKIE_SECURE = False
    

class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    TESTING = False
    
    # In production, ensure these are set as environment variables
    SECRET_KEY = os.environ.get('SECRET_KEY')
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY')
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')
    
    # Enhanced security for production
    SESSION_COOKIE_SECURE = True
    PERMANENT_SESSION_LIFETIME = timedelta(days=7)  # Shorter session in production


# Set active configuration
config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}


def get_config():
    """
    Get the current configuration based on environment
    
    Returns:
        Config object based on FLASK_ENV environment variable
    """
    env = os.environ.get('FLASK_ENV', 'default')
    return config.get(env, config['default'])