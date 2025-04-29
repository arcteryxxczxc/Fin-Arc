from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.models.user import User
from app.models.expense import Expense
from app.models.income import Income
from app.models.category import Category
from sqlalchemy import func, extract, and_
from datetime import datetime, timedelta, date
import calendar
import logging
import hashlib

# Set up logging
logger = logging.getLogger(__name__)

@api_bp.route('/reports/dashboard', methods=['GET'])
@jwt_required()
def get_dashboard_data():
    """
    Get dashboard overview data including key stats, trends, 
    and budget information
    
    Returns:
        JSON response with dashboard data
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return jsonify({"error": "User not found"}), 404
        
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
        
    except Exception as e:
        logger.error(f"Error getting dashboard data: {str(e)}")
        return jsonify({"error": "An error occurred while retrieving dashboard data"}), 500

@api_bp.route('/reports/monthly', methods=['GET'])
@jwt_required()
def get_monthly_report():
    """
    Get detailed monthly report data
    
    Query parameters:
    - month: Month number (1-12, default: current month)
    - year: Year (default: current year)
    
    Returns:
        JSON response with monthly report data
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return jsonify({"error": "User not found"}), 404
        
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
        
    except Exception as e:
        logger.error(f"Error getting monthly report: {str(e)}")
        return jsonify({"error": "An error occurred while retrieving monthly report data"}), 500

@api_bp.route('/reports/annual', methods=['GET'])
@jwt_required()
def get_annual_report():
    """
    Get detailed annual report data
    
    Query parameters:
    - year: Year (default: current year)
    
    Returns:
        JSON response with annual report data
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        # Get year from request or use current
        year = request.args.get('year', datetime.now().year, type=int)
        
        # Validate year
        if year < 2000 or year > 2100:
            year = datetime.now().year
        
        # Calculate start and end dates
        start_date = date(year, 1, 1)
        end_date = date(year, 12, 31)
        
        # Get annual totals
        total_income = get_income_total(user.id, start_date, end_date)
        total_expenses = get_expense_total(user.id, start_date, end_date)
        balance = total_income - total_expenses
        
        # Get expense breakdown by category
        categories = get_expense_categories(user.id, start_date, end_date)
        
        # Get income breakdown by source
        income_sources = get_income_sources(user.id, start_date, end_date)
        
        # Get monthly breakdown
        monthly_data = []
        for month in range(1, 13):
            month_start = date(year, month, 1)
            _, days_in_month = calendar.monthrange(year, month)
            month_end = date(year, month, days_in_month)
            
            # Skip future months
            if month_start > datetime.now().date():
                break
            
            month_income = get_income_total(user.id, month_start, month_end)
            month_expenses = get_expense_total(user.id, month_start, month_end)
            
            monthly_data.append({
                'month': month,
                'month_name': calendar.month_name[month],
                'income': month_income,
                'expenses': month_expenses,
                'balance': month_income - month_expenses
            })
        
        # Get quarterly breakdown
        quarterly_data = []
        for quarter in range(1, 5):
            quarter_start = date(year, (quarter - 1) * 3 + 1, 1)
            quarter_end_month = quarter * 3
            _, days_in_month = calendar.monthrange(year, quarter_end_month)
            quarter_end = date(year, quarter_end_month, days_in_month)
            
            # Skip future quarters
            if quarter_start > datetime.now().date():
                break
            
            quarter_income = get_income_total(user.id, quarter_start, quarter_end)
            quarter_expenses = get_expense_total(user.id, quarter_start, quarter_end)
            
            quarterly_data.append({
                'quarter': quarter,
                'quarter_name': f"Q{quarter}",
                'start_date': quarter_start.strftime('%Y-%m-%d'),
                'end_date': quarter_end.strftime('%Y-%m-%d'),
                'income': quarter_income,
                'expenses': quarter_expenses,
                'balance': quarter_income - quarter_expenses
            })
        
        # Calculate prev/next year for navigation
        prev_year = year - 1
        next_year = year + 1 if year < datetime.now().year else None
        
        return jsonify({
            'year': year,
            'navigation': {
                'prev_year': prev_year,
                'next_year': next_year
            },
            'totals': {
                'income': total_income,
                'expenses': total_expenses,
                'balance': balance
            },
            'categories': categories,
            'income_sources': income_sources,
            'monthly_data': monthly_data,
            'quarterly_data': quarterly_data,
            'date_range': {
                'start_date': start_date.strftime('%Y-%m-%d'),
                'end_date': end_date.strftime('%Y-%m-%d')
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting annual report: {str(e)}")
        return jsonify({"error": "An error occurred while retrieving annual report data"}), 500

@api_bp.route('/reports/cashflow', methods=['GET'])
@jwt_required()
def get_cashflow_report():
    """
    Get cash flow report data
    
    Query parameters:
    - period: Report period (month, year, custom) - default: month
    - start_date: Start date for custom period (YYYY-MM-DD)
    - end_date: End date for custom period (YYYY-MM-DD)
    
    Returns:
        JSON response with cash flow report data
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        # Get period and dates
        period = request.args.get('period', 'month')
        today = datetime.now().date()
        
        if period == 'month':
            start_date = today.replace(day=1)
            end_date = today
        elif period == 'year':
            start_date = today.replace(month=1, day=1)
            end_date = today
        elif period == 'custom':
            # Get custom date range
            start_date_str = request.args.get('start_date')
            end_date_str = request.args.get('end_date')
            
            if not start_date_str or not end_date_str:
                return jsonify({"error": "Start date and end date are required for custom period"}), 400
                
            try:
                start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
                end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
            except ValueError:
                return jsonify({"error": "Invalid date format. Use YYYY-MM-DD"}), 400
                
            if start_date > end_date:
                return jsonify({"error": "Start date cannot be after end date"}), 400
        else:
            return jsonify({"error": "Invalid period. Use month, year, or custom"}), 400
        
        # Get income data
        income_data = db.session.query(
            Income.date,
            Income.source,
            Income.description,
            Income.amount
        ).filter(
            Income.user_id == user.id,
            Income.date >= start_date,
            Income.date <= end_date
        ).order_by(
            Income.date
        ).all()
        
        # Format income data
        income_entries = [{
            'date': income_date.strftime('%Y-%m-%d'),
            'source': source,
            'description': description or '',
            'amount': float(amount)
        } for income_date, source, description, amount in income_data]
        
        # Get expense data
        expense_data = db.session.query(
            Expense.date,
            Expense.description,
            Category.name,
            Expense.amount
        ).outerjoin(
            Category, Expense.category_id == Category.id
        ).filter(
            Expense.user_id == user.id,
            Expense.date >= start_date,
            Expense.date <= end_date
        ).order_by(
            Expense.date
        ).all()
        
        # Format expense data
        expense_entries = [{
            'date': expense_date.strftime('%Y-%m-%d'),
            'description': description or '',
            'category': category_name or 'Uncategorized',
            'amount': float(amount)
        } for expense_date, description, category_name, amount in expense_data]
        
        # Calculate totals
        total_income = sum(entry['amount'] for entry in income_entries)
        total_expenses = sum(entry['amount'] for entry in expense_entries)
        net_cashflow = total_income - total_expenses
        
        # Get cashflow by day
        daily_cashflow = []
        current_date = start_date
        while current_date <= end_date:
            # Get income for this day
            day_income = sum(entry['amount'] for entry in income_entries if entry['date'] == current_date.strftime('%Y-%m-%d'))
            
            # Get expenses for this day
            day_expenses = sum(entry['amount'] for entry in expense_entries if entry['date'] == current_date.strftime('%Y-%m-%d'))
            
            daily_cashflow.append({
                'date': current_date.strftime('%Y-%m-%d'),
                'income': day_income,
                'expenses': day_expenses,
                'net': day_income - day_expenses
            })
            
            current_date += timedelta(days=1)
        
        return jsonify({
            'period': period,
            'date_range': {
                'start_date': start_date.strftime('%Y-%m-%d'),
                'end_date': end_date.strftime('%Y-%m-%d')
            },
            'totals': {
                'income': total_income,
                'expenses': total_expenses,
                'net_cashflow': net_cashflow
            },
            'income_entries': income_entries,
            'expense_entries': expense_entries,
            'daily_cashflow': daily_cashflow
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting cashflow report: {str(e)}")
        return jsonify({"error": "An error occurred while retrieving cashflow report data"}), 500

@api_bp.route('/reports/budget', methods=['GET'])
@jwt_required()
def get_budget_report():
    """
    Get budget performance report data
    
    Query parameters:
    - month: Month number (1-12, default: current month)
    - year: Year (default: current year)
    
    Returns:
        JSON response with budget report data
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return jsonify({"error": "User not found"}), 404
        
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
        
        # Get budget categories (categories with budget limits)
        budget_categories = Category.query.filter(
            Category.user_id == user.id,
            Category.is_active == True,
            Category.is_income == False,
            Category.budget_limit.isnot(None)
        ).order_by(Category.name).all()
        
        # Get expenses by category
        expenses_by_category = db.session.query(
            Expense.category_id,
            func.sum(Expense.amount).label('total')
        ).filter(
            Expense.user_id == user.id,
            Expense.date >= start_date,
            Expense.date <= end_date
        ).group_by(
            Expense.category_id
        ).all()
        
        # Create a mapping of category IDs to expenses
        category_expenses = {cat_id: float(total) for cat_id, total in expenses_by_category}
        
        # Format budget data
        budget_data = []
        for category in budget_categories:
            spent = category_expenses.get(category.id, 0)
            budget = float(category.budget_limit)
            remaining = budget - spent
            percentage = (spent / budget * 100) if budget > 0 else 0
            
            status = 'under_budget'
            if percentage >= 100:
                status = 'over_budget'
            elif percentage >= 90:
                status = 'near_limit'
            
            budget_data.append({
                'id': category.id,
                'name': category.name,
                'color_code': category.color_code,
                'budget': budget,
                'spent': spent,
                'remaining': remaining,
                'percentage': percentage,
                'status': status
            })
        
        # Get categories without budget limits
        non_budget_categories = Category.query.filter(
            Category.user_id == user.id,
            Category.is_active == True,
            Category.is_income == False,
            Category.budget_limit.is_(None)
        ).order_by(Category.name).all()
        
        # Format non-budget category data
        non_budget_data = []
        for category in non_budget_categories:
            spent = category_expenses.get(category.id, 0)
            
            if spent > 0:
                non_budget_data.append({
                    'id': category.id,
                    'name': category.name,
                    'color_code': category.color_code,
                    'spent': spent
                })
        
        # Get uncategorized expenses
        uncategorized_expenses = db.session.query(
            func.sum(Expense.amount)
        ).filter(
            Expense.user_id == user.id,
            Expense.date >= start_date,
            Expense.date <= end_date,
            Expense.category_id.is_(None)
        ).scalar() or 0
        
        # Get budget summary
        total_budget = sum(float(category.budget_limit) for category in budget_categories)
        total_spent = sum(spent for _, _, _, _, spent, _, _, _ in budget_data)
        
        # Include non-budget and uncategorized expenses in total spent
        total_spent += sum(spent for _, _, _, spent in non_budget_data)
        total_spent += float(uncategorized_expenses)
        
        budget_remaining = total_budget - total_spent
        budget_percentage = (total_spent / total_budget * 100) if total_budget > 0 else 0
        
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
            'budget_summary': {
                'total_budget': total_budget,
                'total_spent': total_spent,
                'remaining': budget_remaining,
                'percentage': budget_percentage
            },
            'budget_categories': budget_data,
            'non_budget_categories': non_budget_data,
            'uncategorized_expenses': float(uncategorized_expenses),
            'date_range': {
                'start_date': start_date.strftime('%Y-%m-%d'),
                'end_date': end_date.strftime('%Y-%m-%d')
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting budget report: {str(e)}")
        return jsonify({"error": "An error occurred while retrieving budget report data"}), 500

# Helper functions for reports
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
    
    # Get uncategorized expenses
    uncategorized = db.session.query(
        func.sum(Expense.amount)
    ).filter(
        Expense.user_id == user_id,
        Expense.date >= start_date,
        Expense.date <= end_date,
        Expense.category_id.is_(None)
    ).scalar() or 0
    
    # Calculate total expenses
    total_expenses = sum(float(cat_total or 0) for _, _, _, cat_total in categories)
    total_expenses += float(uncategorized)
    
    result = []
    
    # Add categories with expenses
    for cat_id, cat_name, cat_color, cat_total in categories:
        if cat_total is not None and cat_total > 0:
            result.append({
                'id': cat_id,
                'name': cat_name,
                'color': cat_color,
                'total': float(cat_total),
                'percentage': (float(cat_total) / total_expenses * 100) if total_expenses > 0 else 0
            })
    
    # Add uncategorized expenses if any
    if uncategorized > 0:
        result.append({
            'id': None,
            'name': 'Uncategorized',
            'color': '#757575',
            'total': float(uncategorized),
            'percentage': (float(uncategorized) / total_expenses * 100) if total_expenses > 0 else 0
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
            'income': float(day_income),
            'balance': float(day_income) - float(day_expenses)
        })
    
    return result