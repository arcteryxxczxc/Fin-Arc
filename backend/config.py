import os
from datetime import timedelta

class Config:
    """Base configuration"""
    # Secret key for session management and CSRF protection
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'you-will-never-guess'
    FLUTTER_WEB_URL = os.environ.get('FLUTTER_WEB_URL')
    # Comma-separated list of allowed Flutter Web URLs in production
    FLUTTER_WEB_URLS = os.environ.get('FLUTTER_WEB_URLS', '')

    # Database configuration - improved parameterization
    DB_USER = os.environ.get('DB_USER', 'postgres')
    DB_PASSWORD = os.environ.get('DB_PASSWORD', 'postgres')
    DB_HOST = os.environ.get('DB_HOST', 'localhost')
    DB_PORT = os.environ.get('DB_PORT', '5432')
    DB_NAME = os.environ.get('DB_NAME', 'fin_arc')
    
    # Full database URL constructed from parameters
    DATABASE_URL = os.environ.get('DATABASE_URL')
    if not DATABASE_URL:
        DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    
    SQLALCHEMY_DATABASE_URI = DATABASE_URL
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Connection pool settings
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_size': 10,
        'pool_recycle': 3600,
        'pool_pre_ping': True
    }
    
    # Enhanced security headers
    SECURITY_HEADERS = {
        'Content-Security-Policy': "default-src 'self'",
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'SAMEORIGIN',
        'X-XSS-Protection': '1; mode=block'
    }

    # JWT settings with enhanced security
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'jwt-secret-key-change-in-production'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    JWT_BLACKLIST_ENABLED = True
    JWT_BLACKLIST_TOKEN_CHECKS = ['access', 'refresh']
    
    # Security settings
    SESSION_COOKIE_SECURE = False  # Set to False for development without HTTPS
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
    UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'app', 'uploads')
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
    
    # Logging configuration
    LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    LOG_FILE = os.environ.get('LOG_FILE', 'flask_app.log')


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    TESTING = False
    SESSION_COOKIE_SECURE = False  # Allow HTTP in development
    
    # More verbose logging for development
    LOG_LEVEL = 'DEBUG'


class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    DEBUG = True
    
    # Testing database configuration
    TEST_DB_NAME = os.environ.get('TEST_DB_NAME', 'fin_arc_test')
    SQLALCHEMY_DATABASE_URI = os.environ.get('TEST_DATABASE_URL') or \
        f"postgresql://{Config.DB_USER}:{Config.DB_PASSWORD}@{Config.DB_HOST}:{Config.DB_PORT}/{TEST_DB_NAME}"
    
    WTF_CSRF_ENABLED = False  # Disable CSRF during tests
    SESSION_COOKIE_SECURE = False
    
    # Reduce security timeouts for testing
    LOGIN_ATTEMPT_TIMEOUT = 1  # 1 second timeout for tests
    

class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    TESTING = False
    
    # In production, ensure secret keys are set as environment variables
    # and will cause an error if not set
    @property
    def SECRET_KEY(self):
        key = os.environ.get('SECRET_KEY')
        if not key:
            raise ValueError("SECRET_KEY environment variable is not set")
        return key
        
    @property
    def JWT_SECRET_KEY(self):
        key = os.environ.get('JWT_SECRET_KEY')
        if not key:
            raise ValueError("JWT_SECRET_KEY environment variable is not set")
        return key
    
    # Ensure database URL is set
    @property
    def SQLALCHEMY_DATABASE_URI(self):
        uri = os.environ.get('DATABASE_URL')
        if not uri:
            raise ValueError("DATABASE_URL environment variable is not set")
        return uri
    
    # Enhanced security for production
    SESSION_COOKIE_SECURE = True  # Require HTTPS
    PERMANENT_SESSION_LIFETIME = timedelta(days=7)  # Shorter session in production
    
    # Connection pool optimized for production
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_size': 20,
        'max_overflow': 10,
        'pool_recycle': 1800,
        'pool_pre_ping': True
    }


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