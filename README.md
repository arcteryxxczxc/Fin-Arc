# Fin-Arc Backend API

This is the RESTful API backend for the Fin-Arc personal finance application. It's built with Flask and PostgreSQL and is designed to be consumed by a Flutter frontend.

## Technology Stack

- **Flask**: Lightweight web framework
- **PostgreSQL**: Relational database for persistent storage
- **SQLAlchemy**: ORM for database interaction
- **Flask-JWT-Extended**: JWT authentication 
- **Flask-Migrate**: Database migrations
- **Flask-CORS**: Cross-Origin Resource Sharing support for Flutter

## Project Structure

```
backend/
├── app/
│   ├── api/                  # API routes
│   │   ├── __init__.py       # API blueprint registration
│   │   ├── auth.py           # Authentication endpoints
│   │   ├── categories.py     # Category management 
│   │   ├── currencies.py     # Currency conversion
│   │   ├── expenses.py       # Expense management
│   │   ├── income.py         # Income management
│   │   ├── notifications.py  # User notifications
│   │   ├── reports.py        # Financial reports
│   │   └── settings.py       # User settings
│   ├── forms/                # Form definitions (for validation)
│   ├── models/               # Database models
│   ├── services/             # Business logic services
│   ├── utils/                # Utility functions
│   └── __init__.py           # Application factory
├── config.py                 # Configuration
├── run.py                    # Application entry point
└── init_db.py                # Database initialization
```

## API Endpoints

The API follows RESTful conventions and is structured under the `/api` prefix. All endpoints return JSON responses.

### Authentication

- `POST /api/auth/register`: Register a new user
- `POST /api/auth/login`: Login and get access token
- `GET /api/auth/profile`: Get user profile
- `POST /api/auth/change-password`: Change password
- `POST /api/auth/logout`: Logout (client-side token disposal)

### Expenses

- `GET /api/expenses`: List expenses (with filtering)
- `GET /api/expenses/<id>`: Get single expense
- `POST /api/expenses`: Create expense
- `PUT /api/expenses/<id>`: Update expense
- `DELETE /api/expenses/<id>`: Delete expense
- `POST /api/expenses/bulk`: Bulk actions on expenses
- `GET /api/expenses/export`: Export expenses as CSV
- `GET /api/expenses/stats`: Get expense statistics

### Income

- `GET /api/income`: List income entries (with filtering)
- `GET /api/income/<id>`: Get single income entry
- `POST /api/income`: Create income entry
- `PUT /api/income/<id>`: Update income entry
- `DELETE /api/income/<id>`: Delete income entry
- `POST /api/income/bulk`: Bulk actions on income entries
- `GET /api/income/export`: Export income entries as CSV
- `GET /api/income/stats`: Get income statistics

### Categories

- `GET /api/categories`: List categories
- `GET /api/categories/<id>`: Get single category
- `POST /api/categories`: Create category
- `PUT /api/categories/<id>`: Update category
- `DELETE /api/categories/<id>`: Delete category
- `POST /api/categories/bulk`: Bulk actions on categories
- `PUT /api/categories/budgets`: Update category budgets
- `GET /api/categories/<id>/expenses`: Get expenses for a category
- `GET /api/categories/<id>/stats`: Get category statistics
- `POST /api/categories/default`: Create default categories

### Reports

- `GET /api/reports/dashboard`: Get dashboard data
- `GET /api/reports/monthly`: Get monthly report
- `GET /api/reports/annual`: Get annual report
- `GET /api/reports/cashflow`: Get cash flow report
- `GET /api/reports/budget`: Get budget report

### Settings

- `GET /api/settings`: Get user settings
- `PUT /api/settings`: Update user settings

### Notifications

- `GET /api/notifications`: Get user notifications
- `POST /api/notifications/check`: Check budget limits
- `POST /api/notifications/<id>/read`: Mark notification as read
- `POST /api/notifications/read-all`: Mark all notifications as read

### Currencies

- `GET /api/currencies/convert`: Convert amount between currencies
- `GET /api/currencies/rates`: Get exchange rates
- `GET /api/currencies/list`: Get list of common currencies

## Authentication

The API uses JWT (JSON Web Tokens) for authentication. Most endpoints require a valid access token which should be included in the `Authorization` header using the Bearer scheme:

```
Authorization: Bearer <your_access_token>
```

Upon successful login, the client receives an access token that should be stored and used for subsequent requests.

## Error Handling

The API returns appropriate HTTP status codes and error messages:

- `200 OK`: Request succeeded
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Missing or invalid authentication
- `403 Forbidden`: Authenticated but not authorized
- `404 Not Found`: Resource not found
- `409 Conflict`: Request conflicts with current state
- `500 Internal Server Error`: Server-side error

All error responses include a JSON object with an `error` field containing a descriptive message.

## Setup and Deployment

### Prerequisites

- Python 3.9+
- PostgreSQL 13+
- Docker (optional, for containerized deployment)

### Development Setup

1. Clone the repository
2. Create and activate a virtual environment
3. Install dependencies: `pip install -r requirements.txt`
4. Configure environment variables in `.env` file
5. Initialize the database: `python init_db.py`
6. Run the application: `python run.py`

### Environment Variables

Create a `.env` file with the following variables:

```
SECRET_KEY=your-secret-key-change-in-production
JWT_SECRET_KEY=your-jwt-secret-key-change-in-production
DATABASE_URL=postgresql://username:password@localhost:5432/fin_arc
FLASK_APP=run.py
FLASK_ENV=development
DEBUG=True
```

### Production Deployment

For production, set appropriate environment variables and use a WSGI server like Gunicorn:

```
gunicorn --bind 0.0.0.0:5000 run:app
```

Or use Docker with the provided Dockerfile and docker-compose.yml.

## Flutter Integration

This API backend is designed to be consumed by a Flutter frontend. All endpoints return JSON data that can be easily parsed by the Flutter application. CORS is configured to allow requests from the Flutter frontend.

## Testing

All API endpoints can be tested using tools like Postman or curl. Sample requests and responses for each endpoint are documented in the API documentation.