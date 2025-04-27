# Fin-Arc Personal Finance Application

A cross-platform personal finance application for tracking expenses, managing budgets, and gaining insights into financial health.

## Project Overview

Fin-Arc is a comprehensive personal finance management system that provides the following features:

- **Secure User Authentication**: With login attempt tracking and account lockout protection
- **Expense Tracking**: Log and categorize expenses with detailed information
- **Income Management**: Track various income sources with tax calculations
- **Custom Categories**: Create personalized categories with budget limits
- **Budget Management**: Set and monitor spending limits by category
- **Financial Reports**: Generate insights with visualizations and analysis
- **Responsive Design**: Works across web and mobile platforms

## Technology Stack

- **Backend**: Flask (Python)
- **Database**: PostgreSQL
- **Frontend**: HTML/CSS/JavaScript with Bootstrap 5
- **ORM**: SQLAlchemy
- **Authentication**: Flask-Login, Bcrypt
- **Form Handling**: Flask-WTF
- **Migration**: Flask-Migrate
- **Containerization**: Docker (planned)

## Installation

### Prerequisites

- Python 3.10+
- PostgreSQL
- pip

### Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/arcteryxxczxc/Fin-Arc.git
   cd Fin-Arc
   ```

2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install the required packages:
   ```bash
   pip install -r requirements.txt
   ```

4. Set up environment variables:
   Create a `.env` file in the project root with the following variables:
   ```
   SECRET_KEY=your_secret_key
   DATABASE_URL=postgresql://username:password@localhost/fin_arc
   FLASK_ENV=development
   ```

5. Initialize the database:
   ```bash
   flask db init
   flask db migrate -m "Initial migration"
   flask db upgrade
   ```

6. Run the application:
   ```bash
   python run.py
   ```

7. Access the application at `http://localhost:5000`

## Project Structure

```
Fin-Arc/
├── backend/
│   ├── app.py                      # Main Flask application
│   ├── config.py                   # Configuration settings
│   ├── models/                     # Database models
│   ├── routes/                     # API endpoints
│   ├── forms/                      # Form validation
│   ├── utils/                      # Helper functions
│   ├── static/                     # Static files
│   └── templates/                  # HTML templates
├── frontend/                       # Frontend assets
├── migrations/                     # Database migrations
├── tests/                          # Unit and integration tests
├── docker/                         # Docker configuration
├── requirements.txt                # Python dependencies
└── README.md                       # Project documentation
```

## Features

### Authentication

- User registration with strong password requirements
- Secure login with attempt tracking
- Account lockout after multiple failed attempts
- Password reset functionality

### Expense Management

- Add, edit, delete, and view expenses
- Categorize expenses
- Filter and search expenses
- Upload and store receipts
- Track recurring expenses

### Category Management

- Create custom expense categories
- Assign colors and icons
- Set budget limits
- Track spending by category

### Income Tracking

- Record income from various sources
- Track taxable and non-taxable income
- Calculate after-tax income
- Monitor recurring income

### Reporting and Analysis

- Monthly and annual summaries
- Expense breakdown by category
- Income vs. expense comparisons
- Budget performance tracking
- Cash flow analysis

## Future Enhancements

- Mobile application using Flutter
- Docker containerization
- Bank account integration
- Investment tracking
- Financial goal setting
- Debt management
- Multi-currency support

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b new-feature`
3. Commit your changes: `git commit -am 'Add new feature'`
4. Push to the branch: `git push origin new-feature`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- University of Northampton
- Professor [Supervisor Name]
- [Any other acknowledgements]