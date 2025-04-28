# Fin-Arc - Personal Finance Application

Fin-Arc is a comprehensive personal finance management application that helps you track expenses, set budgets, and achieve your financial goals. The application features both a web interface (Flask) and a mobile app (Flutter).

## Features

- **Expense Tracking**: Record and categorize all your expenses
- **Income Management**: Track various income sources
- **Budget Planning**: Set budgets for different expense categories
- **Visual Reports**: Understand your spending with interactive charts
- **Multi-currency Support**: Handle transactions in different currencies
- **Receipt Storage**: Upload and store receipts for your expenses
- **Recurring Transactions**: Set up recurring income and expenses
- **Budget Notifications**: Get alerts when approaching budget limits
- **Secure Authentication**: Protect your financial data

## Architecture

The application consists of two main components:

1. **Backend**: Python Flask REST API with PostgreSQL database
2. **Frontend**: Flutter cross-platform mobile application and web interface

### Backend Tech Stack

- **Flask**: Web framework
- **SQLAlchemy**: ORM for database operations
- **PostgreSQL**: Database
- **JWT**: Authentication
- **Pytest**: Testing
- **Gunicorn**: WSGI HTTP Server

### Frontend Tech Stack

- **Flutter**: Cross-platform framework
- **Provider**: State management
- **http/dio**: API integration
- **fl_chart**: Interactive charts
- **sqflite**: Local database for offline support

## Getting Started

### Prerequisites

- Python 3.9+
- Flutter SDK
- PostgreSQL
- Docker (optional)

### Installation

#### Using Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/arcteryxxczxc/fin-arc.git
cd fin-arc

# Start the application
docker-compose up -d
```

#### Manual Setup

##### Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export FLASK_APP=run.py
export FLASK_ENV=development
export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/finance_app

# Initialize database
flask db upgrade

# Run the application
flask run
```

##### Frontend Setup

```bash
# Navigate to frontend directory
cd frontend

# Get Flutter dependencies
flutter pub get

# Run the application
flutter run
```

## Database Schema

The application uses the following main database models:

- **User**: Authentication and user information
- **Category**: Expense and income categories
- **Expense**: Transaction records for expenses
- **Income**: Transaction records for income sources
- **UserSettings**: User preferences and settings

## API Endpoints

The backend provides a RESTful API with the following main endpoints:

- **Auth**: `/api/auth/` - Authentication endpoints
- **Expenses**: `/api/expenses/` - Expense management
- **Income**: `/api/income/` - Income management
- **Categories**: `/api/categories/` - Category management
- **Reports**: `/api/reports/` - Financial reports and statistics

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments
- Created by Albert Jidebayev