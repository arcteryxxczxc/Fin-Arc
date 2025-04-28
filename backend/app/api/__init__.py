from flask import Blueprint

# Create a blueprint for API routes
api_bp = Blueprint('api', __name__, url_prefix='/api')

# Import routes to register them with the blueprint
from app.api import routes, auth, categories, expenses, incomes, reports, currencies, settings, notifications