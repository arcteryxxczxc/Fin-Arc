# backend/app/api/reports.py

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models.user import User
from app.models.expense import Expense
from app.models.income import Income
from app.models.category import Category
from sqlalchemy import func, extract, and_
from datetime import datetime, timedelta, date
import calendar
import logging

# Set up logging
logger = logging.getLogger(__name__)

# Create blueprint for reports API routes
reports_api = Blueprint('reports_api', __name__, url_prefix='/api/reports')

@reports_api.route('/dashboard', methods=['GET'])
@jwt_required()
def get_dashboard_data():
    """Get dashboard overview data"""
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    # Get today's date and calculate start dates for different periods
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday())
    start_of_month = date(today.year, today.month, 1)
    start_of_year = date(today.year, 1, 1)
    
    # Calculate statistics for different periods
    stats = {
        'today': {
            'expenses': get_expense_total(user.id, today, today),
            'income': get_income_total(user.id, today, today)
        },
        'week': {
            'expenses': get_expense_total(user.id, start_of_week, today),
            'income': get_income_total(user.id, start_of_week, today)
        },
        'month': {
            'expenses': get_expense_total(user.id, start_of_month, today),
            'income': get_income_total(user.id, start_of_month, today)
        },
        'year': {
            'expenses': get_expense_total(user.id, start_of_year, today),
            'income': get_income_total(user.id, start_of_year, today)
        }
    }
    
    # Calculate balance for each period
    for period in stats:
        stats[period]['balance'] = stats[period]['income'] - stats[period]['expenses']
    
    # Get top expense categories this month
    category_data = get_top_categories(user.id, start_of_month, today, limit=5)
    
    # Get monthly trend for the past 6 months
    trend_data = get_monthly_trend(user.id, 6)
    
    # Get recent transactions
    recent_expenses = Expense.get_recent_expenses(user.id, limit=5)
    recent_income = Income.get_recent_incomes(user.id, limit=5)
    
    # Format recent transactions for API
    recent_transactions = {
        'expenses': [{
            'id': expense.id,
            'date': expense.formatted_date,
            'description': expense.description,
            'amount': float(expense.amount),
            'category': expense.category.name if expense.category else 'Uncategorized'
        } for expense in recent_expenses],
        'income': [{
            'id': income.id,
            'date': income.formatted_date,
            'source': income.source,
            'amount': float(income.amount)
        } for income in recent_income]
    }
    
    # Get budget overview
    budget_categories = Category.query.filter(
        Category.user_id == user.id,
        Category.is_active == True,
        Category.is_income == False,
        Category.budget_limit.isnot(None)
    ).order_by(Category.name).all()
    
    budget_overview = [{
        'id': category.id,
        'name': category.name,
        'budget': float(category.budget_limit),
        'spent': category.current_spending,
        'percentage': category.budget_percentage,
        'status': category.budget_status
    } for category in budget_categories]
    
    return jsonify({
        'stats': stats,
        'categories': category_data,
        'trend': trend_data,
        'recent_transactions': recent_transactions,
        'budget_overview': budget_overview
    }), 200

@reports_api.route('/monthly', methods=['GET'])
@jwt_required()
def get_monthly_report():
    """Get monthly report data"""
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    # Get month and year from request or use current
    month = request.args.get('month', datetime.now().month, type=int)
    year = request.args.get('year', datetime.now().year, type=int)
    
    # Validate month and year
    if month < 1 or month > 12:
        month = datetime.now().month
    
    if year < 2000 or year > 2100:
        year = datetime.now().year
    
    # Calculate start and end dates
    _, days_in_month = calendar.monthrange(year, month)
    start_date = date(year, month, 1)
    end_date = date(year, month, days_in_month)
    
    # Get totals
    total_income = get_income_total(user.id, start_date, end_date)
    total_expenses = get_expense_total(user.id, start_date, end_date)
    balance = total_income - total_expenses
    
    # Get expense breakdown by category
    categories = get_expense_categories(user.id, start_date, end_date)
    
    # Get income breakdown by source
    income_sources = get_income_sources(user.id, start_date, end_date)
    
    # Get daily data
    daily_data = get_daily_data(user.id, year, month)
    
    # Calculate prev/next month for navigation
    if month == 1:
        prev_month = 12
        prev_year = year - 1
    else:
        prev_month = month - 1
        prev_year = year
        
    if month == 12:
        next_month = 1
        next_year = year + 1
    else:
        next_month = month + 1
        next_year = year
    
    return jsonify({
        'month': month,
        'year': year,
        'month_name': calendar.month_name[month],
        'navigation': {
            'prev_month': prev_month,
            'prev_year': prev_year,
            'next_month': next_month,
            'next_year': next_year
        },
        'totals': {
            'income': total_income,
            'expenses': total_expenses,
            'balance': balance
        },
        'categories': categories,
        'income_sources': income_sources,
        'daily_data': daily_data,
        'date_range': {
            'start_date': start_date.strftime('%Y-%m-%d'),
            'end_date': end_date.strftime('%Y-%m-%d')
        }
    }), 200

# Helper functions
def get_expense_total(user_id, start_date, end_date):
    """Get total expenses for a date range"""
    total = Expense.query.with_entities(
        func.sum(Expense.amount)
    ).filter(
        Expense.user_id == user_id,
        Expense.date >= start_date,
        Expense.date <= end_date
    ).scalar() or 0
    
    return float(total)

def get_income_total(user_id, start_date, end_date):
    """Get total income for a date range"""
    total = Income.query.with_entities(
        func.sum(Income.amount)
    ).filter(
        Income.user_id == user_id,
        Income.date >= start_date,
        Income.date <= end_date
    ).scalar() or 0
    
    return float(total)

def get_top_categories(user_id, start_date, end_date, limit=5):
    """Get top expense categories for a date range"""
    categories = Category.query.join(
        Expense, Expense.category_id == Category.id
    ).with_entities(
        Category.id,
        Category.name,
        Category.color_code,
        func.sum(Expense.amount).label('total')
    ).filter(
        Expense.user_id == user_id,
        Expense.date >= start_date,
        Expense.date <= end_date
    ).group_by(
        Category.id, Category.name, Category.color_code
    ).order_by(
        func.sum(Expense.amount).desc()
    ).limit(limit).all()
    
    return [{
        'id': cat_id,
        'name': cat_name,
        'color': cat_color,
        'total': float(cat_total)
    } for cat_id, cat_name, cat_color, cat_total in categories]

def get_monthly_trend(user_id, months=6):
    """Get monthly income and expense data for trend charts"""
    # Calculate start date
    today = datetime.now()
    start_month = today.month - months
    start_year = today.year
    
    # Adjust for previous year
    while start_month <= 0:
        start_month += 12
        start_year -= 1
    
    start_date = date(start_year, start_month, 1)
    
    # Create a list of all months in the range
    months_list = []
    current_date = start_date
    while current_date <= date.today():
        month_key = current_date.strftime('%Y-%m')
        months_list.append({
            'key': month_key,
            'label': current_date.strftime('%b %Y')
        })
        
        # Move to next month
        if current_date.month == 12:
            current_date = date(current_date.year + 1, 1, 1)
        else:
            current_date = date(current_date.year, current_date.month + 1, 1)
    
    # Get expense data by month
    expense_data = {}
    expenses = Expense.get_total_by_month(user_id)
    for month_date, total in expenses:
        if month_date:
            month_key = month_date.strftime('%Y-%m')
            expense_data[month_key] = float(total)
    
    # Get income data by month
    income_data = {}
    incomes = Income.get_total_by_month(user_id)
    for month_date, total in incomes:
        if month_date:
            month_key = month_date.strftime('%Y-%m')
            income_data[month_key] = float(total)
    
    # Combine data into a single list
    result = []
    for month in months_list:
        month_key = month['key']
        result.append({
            'month': month['label'],
            'expenses': expense_data.get(month_key, 0),
            'income': income_data.get(month_key, 0),
            'balance': income_data.get(month_key, 0) - expense_data.get(month_key, 0)
        })
    
    return result

def get_expense_categories(user_id, start_date, end_date):
    """Get expense breakdown by category for a date range"""
    categories = Category.query.outerjoin(
        Expense, and_(
            Expense.category_id == Category.id,
            Expense.date >= start_date,
            Expense.date <= end_date,
            Expense.user_id == user_id
        )
    ).with_entities(
        Category.id,
        Category.name,
        Category.color_code,
        func.sum(Expense.amount).label('total')
    ).filter(
        Category.user_id == user_id,
        Category.is_income == False,
        Category.is_active == True
    ).group_by(
        Category.id, Category.name, Category.color_code
    ).order_by(
        func.sum(Expense.amount).desc()
    ).all()
    
    total_expenses = sum(float(cat_total or 0) for _, _, _, cat_total in categories)
    
    result = []
    for cat_id, cat_name, cat_color, cat_total in categories:
        if cat_total is not None and cat_total > 0:
            result.append({
                'id': cat_id,
                'name': cat_name,
                'color': cat_color,
                'total': float(cat_total),
                'percentage': (float(cat_total) / total_expenses * 100) if total_expenses > 0 else 0
            })
    
    return result

def get_income_sources(user_id, start_date, end_date):
    """Get income breakdown by source for a date range"""
    sources = Income.query.with_entities(
        Income.source,
        func.sum(Income.amount).label('total')
    ).filter(
        Income.user_id == user_id,
        Income.date >= start_date,
        Income.date <= end_date
    ).group_by(
        Income.source
    ).order_by(
        func.sum(Income.amount).desc()
    ).all()
    
    total_income = sum(float(total) for _, total in sources)
    
    result = []
    for source, total in sources:
        # Generate a color for this source
        import hashlib
        hash_object = hashlib.md5(source.encode())
        hashed = hash_object.hexdigest()
        color = f'#{hashed[:6]}'
        
        result.append({
            'name': source,
            'total': float(total),
            'color': color,
            'percentage': (float(total) / total_income * 100) if total_income > 0 else 0
        })
    
    return result

def get_daily_data(user_id, year, month):
    """Get day-by-day data for the month"""
    _, days_in_month = calendar.monthrange(year, month)
    result = []
    
    for day in range(1, days_in_month + 1):
        current_date = date(year, month, day)
        
        # Skip days in the future
        if current_date > datetime.now().date():
            break
            
        day_expenses = Expense.query.with_entities(
            func.sum(Expense.amount)
        ).filter(
            Expense.user_id == user_id,
            Expense.date == current_date
        ).scalar() or 0
        
        day_income = Income.query.with_entities(
            func.sum(Income.amount)
        ).filter(
            Income.user_id == user_id,
            Income.date == current_date
        ).scalar() or 0
        
        result.append({
            'date': current_date.strftime('%d'),
            'expenses': float(day_expenses),
            'income': float(day_income)
        })
    
    return result