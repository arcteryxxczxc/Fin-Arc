from flask import Blueprint

# Create a blueprint for API routes
api_bp = Blueprint('api', __name__, url_prefix='/api')

# Import routes to register them with the blueprint
# Try to import each module individually to avoid failing if some are missing
try:
    from backend.app.api import routes
except ImportError:
    pass

try:
    from backend.app.api import auth
except ImportError:
    pass

try:
    from backend.app.api import categories
except ImportError:
    pass

try:
    from backend.app.api import expenses
except ImportError:
    pass

try:
    from backend.app.api import incomes
except ImportError:
    pass

try:
    from backend.app.api import reports
except ImportError:
    pass

try:
    from backend.app.api import currencies
except ImportError:
    pass

try:
    from backend.app.api import settings
except ImportError:
    pass

try:
    from backend.app.api import notifications
except ImportError:
    pass