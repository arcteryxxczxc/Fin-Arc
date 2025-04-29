from flask import Blueprint

# Create a blueprint for API routes
api_bp = Blueprint('api', __name__, url_prefix='/api')

# Import routes to register them with the blueprint
from app.api import routes

# Import other API modules
try:
    from app.api import auth
except ImportError:
    pass

try:
    from app.api import categories
except ImportError:
    pass

try:
    from app.api import expenses
except ImportError:
    pass

try:
    from app.api import income
except ImportError:
    pass

try:
    from app.api import reports
except ImportError:
    pass

try:
    from app.api import currencies
except ImportError:
    pass

try:
    from app.api import settings
except ImportError:
    pass

try:
    from app.api import notifications
except ImportError:
    pass