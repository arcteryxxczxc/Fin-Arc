# Import models with try/except to avoid errors if some models don't exist yet
try:
    from backend.app.models.user import User, LoginAttempt
except ImportError:
    pass

try:
    from backend.app.models.expense import Expense
except ImportError:
    pass

try:
    from backend.app.models.income import Income
except ImportError:
    pass

try:
    from backend.app.models.category import Category
except ImportError:
    pass

try:
    from backend.app.models.settings import UserSettings
except ImportError:
    pass