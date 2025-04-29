from flask import Blueprint

# Create a blueprint for API routes
api_bp = Blueprint('api', __name__, url_prefix='/api')

# Import API modules to register routes
from app.api import auth
from app.api import expenses
from app.api import income
from app.api import categories
from app.api import currencies
from app.api import settings
from app.api import notifications

# Import reports API if it exists
try:
    from app.api import reports
except ImportError:
    pass