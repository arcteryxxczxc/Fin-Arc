from flask import Blueprint

# Create a blueprint for authentication routes that render templates
auth_bp = Blueprint('auth', __name__, url_prefix='/auth')

# Import routes to register them with the blueprint
from app.auth import routes