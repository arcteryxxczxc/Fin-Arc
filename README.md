# Fin-Arc: Personal Finance Application

A comprehensive personal finance application with expense tracking, budgeting, and financial reporting.

## Project Structure

```
finance-app/
├── backend/              # Flask backend API
│   ├── app/              # Application code
│   │   ├── api/          # API endpoints
│   │   ├── models/       # Database models
│   │   ├── services/     # Business logic
│   │   └── utils/        # Utility functions
│   ├── logs/             # Application logs
│   ├── migrations/       # Database migrations
│   ├── .env              # Environment variables
│   ├── config.py         # Application configuration
│   └── run.py            # Application entry point
├── frontend/             # Flutter frontend
│   ├── lib/              # Application code
│   │   ├── api/          # API client code
│   │   ├── models/       # Data models
│   │   ├── providers/    # State management
│   │   ├── screens/      # UI screens
│   │   ├── utils/        # Utility functions
│   │   └── widgets/      # Reusable UI components
│   └── ... (other Flutter files)
└── README.md             # Project documentation
```

## Prerequisites

- [Python 3.8+](https://www.python.org/downloads/)
- [PostgreSQL 12+](https://www.postgresql.org/download/)
- [Flutter 3.0+](https://flutter.dev/docs/get-started/install)
- [Dart 2.17+](https://dart.dev/get-dart)

## Backend Setup

### 1. Database Setup

1. Install PostgreSQL if you haven't already
2. Create a new database:
   ```bash
   createdb fin_arc
   ```
   Or use pgAdmin to create a database named `fin_arc`

### 2. Environment Configuration

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create a virtual environment:
   ```bash
   python -m venv venv
   ```

3. Activate the virtual environment:
   - Windows: `venv\Scripts\activate`
   - Mac/Linux: `source venv/bin/activate`

4. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

5. Configure the `.env` file with your database credentials:
   ```
   # Database Configuration
   DB_USER=postgres
   DB_PASSWORD=your_postgres_password
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=fin_arc
   ```

### 3. Initialize the Database

1. Run the database test script to check connectivity:
   ```bash
   python db_test.py
   ```

2. Initialize the database with tables and sample data:
   ```bash
   python init_db.py
   ```

### 4. Run the Flask Backend

1. Start the Flask server:
   ```bash
   python run.py
   ```

2. The API will be available at http://localhost:8111/api

3. Run the diagnostic script to verify API functionality:
   ```bash
   python flask_diagnostic.py
   ```

## Frontend Setup

### 1. Configure API Connection

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Update the API URL in `lib/utils/constants.dart`:
   ```dart
   // For Android emulator
   static const String baseUrl = 'http://10.0.2.2:8111/api';
   
   // For web or iOS simulator
   // static const String baseUrl = 'http://localhost:8111/api';
   ```

3. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

### 2. Test API Connectivity

1. Run the API checker script:
   ```bash
   dart flutter_api_checker.dart
   ```

### 3. Run the Flutter App

1. Start the Flutter app:
   ```bash
   flutter run
   ```

## Troubleshooting

### Backend Issues

1. **Database Connection Error**
   - Verify PostgreSQL is running
   - Check your database credentials in `.env`
   - Run `python db_test.py` to diagnose connection issues

2. **API Endpoints Not Working**
   - Check Flask server logs in the `logs` directory
   - Run `python flask_diagnostic.py` to test API endpoints
   - Verify CORS settings if accessing from a different domain

### Frontend Issues

1. **API Connection Errors**
   - Verify the correct API URL in `lib/utils/constants.dart`
   - For Android emulator, use `10.0.2.2` instead of `localhost`
   - Run `dart flutter_api_checker.dart` to test API connectivity

2. **Authentication Issues**
   - Check token storage and refresh mechanism
   - Verify JWT settings in the backend config

## Development Workflows

### Adding New Features

1. **Backend**
   - Create new models in `app/models/`
   - Add new API endpoints in `app/api/`
   - Implement business logic in `app/services/`

2. **Frontend**
   - Create data models in `lib/models/`
   - Add API client methods in `lib/api/`
   - Implement screens in `lib/screens/`
   - Create state management in `lib/providers/`

### Testing

1. **Backend Tests**
   ```bash
   python -m unittest discover tests
   ```

2. **Frontend Tests**
   ```bash
   flutter test
   ```

## Deployment

### Backend Deployment

1. Set up a production server with PostgreSQL
2. Configure environment variables for production
3. Use Gunicorn as the WSGI server:
   ```bash
   gunicorn -w 4 -b 0.0.0.0:8111 "app:create_app()"
   ```

### Frontend Deployment

1. Build the Flutter web app:
   ```bash
   flutter build web
   ```

2. Deploy the `build/web` directory to your hosting provider

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.