import os
import logging
from logging.handlers import RotatingFileHandler

def configure_logging(app):
    """Configure logging for the Flask application
    
    Args:
        app: Flask application instance
    """
    # Get log level from config
    log_level_name = app.config.get('LOG_LEVEL', 'INFO')
    log_level = getattr(logging, log_level_name)
    
    # Get log file from config or use default
    log_file = app.config.get('LOG_FILE', 'flask_app.log')
    
    # Create logs directory if it doesn't exist
    log_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'logs')
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
    
    log_path = os.path.join(log_dir, log_file)
    
    # Configure basic logging
    logging.basicConfig(
        level=log_level,
        format=app.config.get('LOG_FORMAT', '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    )
    
    # Create file handler for logging to file
    file_handler = RotatingFileHandler(
        log_path, 
        maxBytes=10*1024*1024,  # 10 MB
        backupCount=5
    )
    file_handler.setLevel(log_level)
    file_handler.setFormatter(logging.Formatter(
        app.config.get('LOG_FORMAT', '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ))
    
    # Add handlers to root logger
    logging.getLogger('').addHandler(file_handler)
    
    # Add handlers to Flask app logger
    app.logger.addHandler(file_handler)
    app.logger.setLevel(log_level)
    
    # Configure SQLAlchemy logging if needed
    if log_level <= logging.DEBUG:
        logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)
    
    # Log startup info
    app.logger.info(f"Logging configured at level {log_level_name}")
    app.logger.info(f"Log file: {log_path}")
    
    return app