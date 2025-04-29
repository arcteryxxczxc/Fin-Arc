# Fin-Arc: Personal Finance Application

Fin-Arc is a comprehensive personal finance application that helps users track expenses, manage income, analyze spending patterns, and achieve financial goals.

## Project Structure

The project consists of two main parts:
- **Backend** - Flask REST API with PostgreSQL database
- **Frontend** - Flutter mobile/web application

## Features

- User authentication (register, login, password reset)
- Expense tracking with categories and analytics
- Income management with recurring income tracking
- Budget planning and monitoring
- Financial reports and visualizations
- Multi-currency support
- Light/dark theme support

## Setup Instructions

### Prerequisites

- Python 3.9+
- Flask and related packages
- PostgreSQL database
- Flutter SDK 3.0+
- Dart SDK 2.16+

### Backend Setup

1. **Navigate to the backend directory**:
   ```bash
   cd backend
   ```

2. **Create and activate a virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install the dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**:
   ```bash
   cp .env.example .env
   ```
   Edit the `.env` file with your database configuration and other settings.

5. **Initialize the database**:
   ```bash
   flask db init
   flask db migrate -m "Initial migration"
   flask db upgrade
   python init_db.py  # Create initial data
   ```

6. **Run the development server**:
   ```bash
   flask run
   ```
   The API server will be available at http://localhost:5000

### Backend Docker Setup (Alternative)

If you prefer using Docker:

1. **Build and run the Docker containers**:
   ```bash
   docker-compose up --build
   ```

2. **Initialize the database inside Docker**:
   ```bash
   docker-compose exec web flask db init
   docker-compose exec web flask db migrate -m "Initial migration"
   docker-compose exec web flask db upgrade
   docker-compose exec web python init_db.py
   ```

### Frontend Setup

1. **Navigate to the frontend directory**:
   ```bash
   cd frontend
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Update API endpoint**:
   Edit `lib/utils/constants.dart` if your backend is not running on the default URL.

4. **Run the application**:
   ```bash
   flutter run -d chrome  # For web

## Testing

### Backend Testing

1. **Run unit tests**:
   ```bash
   cd backend
   pytest
   ```

2. **API testing with Postman or cURL**:
   Import the included Postman collection from `backend/docs/Fin-Arc API.postman_collection.json` for easy API testing.

### Frontend Testing

1. **Run Flutter tests**:
   ```bash
   cd frontend
   flutter test
   ```

## API Documentation

The API documentation is available at `/api/docs` when the backend server is running. It includes all endpoints, request/response formats, and authentication requirements.

Key API endpoints:

- Authentication: `/api/auth/*`
- Expenses: `/api/expenses/*`
- Income: `/api/income/*`
- Categories: `/api/categories/*`
- Reports: `/api/reports/*`

## Common Issues and Troubleshooting

### Backend Issues

1. **Database connection errors**:
   - Verify database credentials in `.env` file
   - Ensure PostgreSQL service is running
   - Check network connectivity if using remote database

2. **Missing dependencies**:
   - Run `pip install -r requirements.txt` again
   - Check for error messages during installation

### Frontend Issues

1. **API connection errors**:
   - Verify the API URL in `constants.dart`
   - Ensure backend server is running
   - Check CORS settings in backend if needed

2. **Flutter build errors**:
   - Run `flutter clean` and then `flutter pub get`
   - Update Flutter SDK if needed
   - Check for conflicting package versions in `pubspec.yaml`

## Development Guidelines

1. **Code Style**:
   - Backend: Follow PEP 8 guidelines
   - Frontend: Follow Dart style guidelines

2. **Git Workflow**:
   - Create feature branches from `develop`
   - Submit pull requests for review
   - Merge to `main` only after testing

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributors

- Albert Jidebayev - Project Lead
