# backend/routes/reports.py

from flask import Blueprint, render_template, request, jsonify, current_app
from flask_login import login_required, current_user
from app import db
from models.expense import Expense
from models.income import Income
from models.category import Category
from sqlalchemy import func, extract, and_
from datetime import datetime, timedelta, date
import calendar
import csv
import io
import logging

# Set up logging
logger = logging.getLogger(__name__)

# Create a Blueprint for report routes
report_routes = Blueprint('reports', __name__, url_prefix='/reports')

@report_routes.route('/dashboard')
@login_required
def dashboard():
    """Main dashboard with overview of financial data"""
    # Get today's date and calculate start dates for different periods
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday())
    start_of_month = date(today.year, today.month, 1)
    
    # Calculate start date for year-to-date
    start_of_year = date(today.year, 1, 1)
    
    # Get expense and income totals for different time periods
    stats = {
        'today': {
            'expenses': get_expense_total(today, today),
            'income': get_income_total(today, today)
        },
        'week': {
            'expenses': get_expense_total(start_of_week, today),
            'income': get_income_total(start_of_week, today)
        },
        'month': {
            'expenses': get_expense_total(start_of_month, today),
            'income': get_income_total(start_of_month, today)
        },
        'year': {
            'expenses': get_expense_total(start_of_year, today),
            'income': get_income_total(start_of_year, today)
        }
    }
    
    # Calculate balance for each period
    for period in stats:
        stats[period]['balance'] = stats[period]['income'] - stats[period]['expenses']
    
    # Get top 5 expense categories this month
    top_categories = db.session.query(
        Category.id,
        Category.name,
        Category.color_code,
        func.sum(Expense.amount).label('total')
    ).join(
        Expense, Expense.category_id == Category.id
    ).filter(
        Expense.user_id == current_user.id,
        Expense.date >= start_of_month,
        Expense.date <= today
    ).group_by(
        Category.id, Category.name, Category.color_code
    ).order_by(
        func.sum(Expense.amount).desc()
    ).limit(5).all()
    
    # Format category data for chart
    category_data = []
    for cat_id, cat_name, cat_color, cat_total in top_categories:
        category_data.append({
            'id': cat_id,
            'name': cat_name,
            'color': cat_color,
            'total': float(cat_total)
        })
    
    # Get monthly expense and income for the past 6 months for trend chart
    months_to_show = 6
    trend_data = get_monthly_trend(months_to_show)
    
    # Get latest expenses and income
    recent_expenses = Expense.query.filter_by(
        user_id=current_user.id
    ).order_by(
        Expense.date.desc(), Expense.id.desc()
    ).limit(5).all()
    
    recent_income = Income.query.filter_by(
        user_id=current_user.id
    ).order_by(
        Income.date.desc(), Income.id.desc()
    ).limit(5).all()
    
    # Get categories with budget limits and their current spending
    budget_categories = db.session.query(Category).filter(
        Category.user_id == current_user.id,
        Category.is_active == True,
        Category.is_income == False,
        Category.budget_limit.isnot(None)
    ).order_by(
        Category.name
    ).all()
    
    # Calculate savings rate
    savings_rate = current_user.get_savings_rate(months=3)
    
    return render_template(
        'reports/dashboard.html',
        stats=stats,
        category_data=category_data,
        trend_data=trend_data,
        recent_expenses=recent_expenses,
        recent_income=recent_income,
        budget_categories=budget_categories,
        savings_rate=savings_rate,
        title='Dashboard'
    )

@report_routes.route('/monthly')
@login_required
def monthly():
    """Monthly report showing income, expenses and balance"""
    # Get month and year from request or use current month
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
    
    # Get total income and expenses for the month
    total_income = get_income_total(start_date, end_date)
    total_expenses = get_expense_total(start_date, end_date)
    balance = total_income - total_expenses
    
    # Get expense breakdown by category
    category_expenses = db.session.query(
        Category.id,
        Category.name,
        Category.color_code,
        func.sum(Expense.amount).label('total')
    ).outerjoin(
        Expense, and_(
            Expense.category_id == Category.id,
            Expense.date >= start_date,
            Expense.date <= end_date,
            Expense.user_id == current_user.id
        )
    ).filter(
        Category.user_id == current_user.id,
        Category.is_income == False,
        Category.is_active == True
    ).group_by(
        Category.id, Category.name, Category.color_code
    ).order_by(
        func.sum(Expense.amount).desc()
    ).all()
    
    # Format category data
    categories = []
    for cat_id, cat_name, cat_color, cat_total in category_expenses:
        if cat_total is not None and cat_total > 0:
            categories.append({
                'id': cat_id,
                'name': cat_name,
                'color': cat_color,
                'total': float(cat_total),
                'percentage': (float(cat_total) / total_expenses * 100) if total_expenses > 0 else 0
            })
    
    # Get income breakdown by source
    income_sources = db.session.query(
        Income.source,
        func.sum(Income.amount).label('total')
    ).filter(
        Income.user_id == current_user.id,
        Income.date >= start_date,
        Income.date <= end_date
    ).group_by(
        Income.source
    ).order_by(
        func.sum(Income.amount).desc()
    ).all()
    
    # Format income data
    sources = []
    for source, total in income_sources:
        # Generate a color for this source
        import hashlib
        hash_object = hashlib.md5(source.encode())
        hashed = hash_object.hexdigest()
        color = f'#{hashed[:6]}'
        
        sources.append({
            'name': source,
            'total': float(total),
            'color': color,
            'percentage': (float(total) / total_income * 100) if total_income > 0 else 0
        })
    
    # Get day-by-day data for line chart
    daily_data = []
    for day in range(1, days_in_month + 1):
        current_date = date(year, month, day)
        
        # Skip days in the future
        if current_date > datetime.now().date():
            break
            
        day_expenses = db.session.query(
            func.sum(Expense.amount)
        ).filter(
            Expense.user_id == current_user.id,
            Expense.date == current_date
        ).scalar() or 0
        
        day_income = db.session.query(
            func.sum(Income.amount)
        ).filter(
            Income.user_id == current_user.id,
            Income.date == current_date
        ).scalar() or 0
        
        daily_data.append({
            'date': current_date.strftime('%d'),
            'expenses': float(day_expenses),
            'income': float(day_income)
        })
    
    # Calculate previous and next month for navigation
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
    
    # Format month name
    month_name = calendar.month_name[month]
    
    return render_template(
        'reports/monthly.html',
        month=month,
        year=year,
        month_name=month_name,
        prev_month=prev_month,
        prev_year=prev_year,
        next_month=next_month,
        next_year=next_year,
        total_income=total_income,
        total_expenses=total_expenses,
        balance=balance,
        categories=categories,
        sources=sources,
        daily_data=daily_data,
        start_date=start_date.strftime('%Y-%m-%d'),
        end_date=end_date.strftime('%Y-%m-%d'),
        title=f'Monthly Report: {month_name} {year}'
    )

@report_routes.route('/annual')
@login_required
def annual():
    """Annual report showing income, expenses and balance by month"""
    # Get year from request or use current year
    year = request.args.get('year', datetime.now().year, type=int)
    
    # Validate year
    if year < 2000 or year > 2100:
        year = datetime.now().year
    
    # Initialize data arrays for each month
    months = []
    income_data = []
    expense_data = []
    balance_data = []
    
    # Current month (to avoid showing future months)
    current_month = datetime.now().month if datetime.now().year == year else 12
    
    # Calculate totals for each month
    yearly_income = 0
    yearly_expenses = 0
    
    for month in range(1, current_month + 1):
        # Calculate start and end dates for the month
        _, days_in_month = calendar.monthrange(year, month)
        start_date = date(year, month, 1)
        end_date = date(year, month, days_in_month)
        
        # Get monthly totals
        month_income = get_income_total(start_date, end_date)
        month_expenses = get_expense_total(start_date, end_date)
        month_balance = month_income - month_expenses
        
        # Add to yearly totals
        yearly_income += month_income
        yearly_expenses += month_expenses
        
        # Add data to arrays
        months.append(calendar.month_abbr[month])
        income_data.append(month_income)
        expense_data.append(month_expenses)
        balance_data.append(month_balance)
    
    # Calculate yearly balance
    yearly_balance = yearly_income - yearly_expenses
    
    # Calculate savings rate for the year
    savings_rate = (yearly_balance / yearly_income * 100) if yearly_income > 0 else 0
    
    # Get top 5 expense categories for the year
    top_categories = db.session.query(
        Category.id,
        Category.name,
        Category.color_code,
        func.sum(Expense.amount).label('total')
    ).join(
        Expense, Expense.category_id == Category.id
    ).filter(
        Expense.user_id == current_user.id,
        extract('year', Expense.date) == year
    ).group_by(
        Category.id, Category.name, Category.color_code
    ).order_by(
        func.sum(Expense.amount).desc()
    ).limit(5).all()
    
    # Format category data
    category_data = []
    for cat_id, cat_name, cat_color, cat_total in top_categories:
        category_data.append({
            'id': cat_id,
            'name': cat_name,
            'color': cat_color,
            'total': float(cat_total),
            'percentage': (float(cat_total) / yearly_expenses * 100) if yearly_expenses > 0 else 0
        })
    
    # Calculate previous and next year for navigation
    prev_year = year - 1
    next_year = year + 1 if year < datetime.now().year else None
    
    return render_template(
        'reports/annual.html',
        year=year,
        prev_year=prev_year,
        next_year=next_year,
        months=months,
        income_data=income_data,
        expense_data=expense_data,
        balance_data=balance_data,
        yearly_income=yearly_income,
        yearly_expenses=yearly_expenses,
        yearly_balance=yearly_balance,
        savings_rate=savings_rate,
        category_data=category_data,
        title=f'Annual Report: {year}'
    )

@report_routes.route('/budget')
@login_required
def budget():
    """Budget performance report"""
    # Get categories with budget limits
    budget_categories = db.session.query(Category).filter(
        Category.user_id == current_user.id,
        Category.is_active == True,
        Category.is_income == False,
        Category.budget_limit.isnot(None)
    ).order_by(
        Category.name
    ).all()
    
    # Calculate budget stats
    budget_data = []
    total_budget = 0
    total_spent = 0
    
    for category in budget_categories:
        spent = category.current_spending
        budget = float(category.budget_limit) if category.budget_limit else 0
        percentage = (spent / budget * 100) if budget > 0 else 0
        
        total_budget += budget
        total_spent += spent
        
        status = 'success'
        if percentage >= 100:
            status = 'danger'
        elif percentage >= 90:
            status = 'warning'
        
        budget_data.append({
            'id': category.id,
            'name': category.name,
            'color': category.color_code,
            'budget': budget,
            'spent': spent,
            'remaining': budget - spent if budget > spent else 0,
            'over': spent - budget if spent > budget else 0,
            'percentage': min(percentage, 100),  # Cap at 100% for display
            'status': status
        })
    
    # Calculate overall budget performance
    overall_percentage = (total_spent / total_budget * 100) if total_budget > 0 else 0
    overall_status = 'success'
    if overall_percentage >= 100:
        overall_status = 'danger'
    elif overall_percentage >= 90:
        overall_status = 'warning'
    
    # Get no-budget expense categories and their spending
    no_budget_categories = db.session.query(
        Category.id,
        Category.name,
        Category.color_code,
        func.sum(Expense.amount).label('total')
    ).join(
        Expense, Expense.category_id == Category.id
    ).filter(
        Category.user_id == current_user.id,
        Category.is_active == True,
        Category.is_income == False,
        Category.budget_limit.is_(None)
    ).group_by(
        Category.id, Category.name, Category.color_code
    ).order_by(
        func.sum(Expense.amount).desc()
    ).all()
    
    # Format no-budget category data
    no_budget_data = []
    total_no_budget = 0
    
    for cat_id, cat_name, cat_color, cat_total in no_budget_categories:
        if cat_total is not None and cat_total > 0:
            no_budget_data.append({
                'id': cat_id,
                'name': cat_name,
                'color': cat_color,
                'total': float(cat_total)
            })
            total_no_budget += float(cat_total) if cat_total else 0
    
    # Get current month income for income vs. budget comparison
    now = datetime.now()
    start_of_month = date(now.year, now.month, 1)
    end_of_month = date(now.year, now.month, calendar.monthrange(now.year, now.month)[1])
    
    month_income = get_income_total(start_of_month, end_of_month)
    
    # Calculate how much budget is left compared to income
    income_vs_budget = {
        'income': month_income,
        'budget': total_budget,
        'difference': month_income - total_budget,
        'percentage': (month_income / total_budget * 100) if total_budget > 0 else 0
    }
    
    return render_template(
        'reports/budget.html',
        budget_data=budget_data,
        no_budget_data=no_budget_data,
        total_budget=total_budget,
        total_spent=total_spent,
        total_no_budget=total_no_budget,
        overall_percentage=overall_percentage,
        overall_status=overall_status,
        income_vs_budget=income_vs_budget,
        title='Budget Report'
    )

@report_routes.route('/cashflow')
@login_required
def cashflow():
    """Cash flow report showing income vs expenses over time"""
    # Get date range from request or use default (last 12 months)
    months = request.args.get('months', 12, type=int)
    
    # Get monthly trend data
    trend_data = get_monthly_trend(months)
    
    # Calculate cumulative cash flow
    cumulative_data = []
    cumulative_balance = 0
    
    for item in trend_data:
        cumulative_balance += item['income'] - item['expenses']
        cumulative_data.append({
            'month': item['month'],
            'balance': cumulative_balance
        })
    
    # Calculate statistics
    total_income = sum(item['income'] for item in trend_data)
    total_expenses = sum(item['expenses'] for item in trend_data)
    total_balance = total_income - total_expenses
    average_monthly_income = total_income / len(trend_data) if trend_data else 0
    average_monthly_expenses = total_expenses / len(trend_data) if trend_data else 0
    average_monthly_balance = average_monthly_income - average_monthly_expenses
    
    # Count positive and negative months
    positive_months = sum(1 for item in trend_data if item['income'] > item['expenses'])
    negative_months = len(trend_data) - positive_months
    
    # Calculate savings rate
    savings_rate = (total_balance / total_income * 100) if total_income > 0 else 0
    
    return render_template(
        'reports/cashflow.html',
        trend_data=trend_data,
        cumulative_data=cumulative_data,
        total_income=total_income,
        total_expenses=total_expenses,
        total_balance=total_balance,
        average_monthly_income=average_monthly_income,
        average_monthly_expenses=average_monthly_expenses,
        average_monthly_balance=average_monthly_balance,
        positive_months=positive_months,
        negative_months=negative_months,
        savings_rate=savings_rate,
        months=months,
        title='Cash Flow Report'
    )

@report_routes.route('/export')
@login_required
def export():
    """Export financial data report"""
    # Get report type and date range
    report_type = request.args.get('type', 'monthly')
    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')
    
    # Parse dates or use defaults (current month)
    try:
        if start_date_str:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
        else:
            # Default to start of current month
            today = date.today()
            start_date = date(today.year, today.month, 1)
            
        if end_date_str:
            end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
        else:
            # Default to today
            end_date = date.today()
    except ValueError:
        # Handle invalid date format
        flash('Invalid date format. Using default date range.', 'warning')
        today = date.today()
        start_date = date(today.year, today.month, 1)
        end_date = date.today()
    
    # Generate report based on type
    if report_type == 'expenses':
        return export_expenses_report(start_date, end_date)
    elif report_type == 'income':
        return export_income_report(start_date, end_date)
    elif report_type == 'cashflow':
        return export_cashflow_report(start_date, end_date)
    else:  # Default to monthly report
        return export_monthly_report(start_date, end_date)

# Helper functions for reports

def get_expense_total(start_date, end_date):
    """Get total expenses for a date range"""
    total = db.session.query(func.sum(Expense.amount)).filter(
        Expense.user_id == current_user.id,
        Expense.date >= start_date,
        Expense.date <= end_date
    ).scalar() or 0
    
    return float(total)

def get_income_total(start_date, end_date):
    """Get total income for a date range"""
    total = db.session.query(func.sum(Income.amount)).filter(
        Income.user_id == current_user.id,
        Income.date >= start_date,
        Income.date <= end_date
    ).scalar() or 0
    
    return float(total)

def get_monthly_trend(months=6):
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
    
    # Get expense data by month
    expense_data = db.session.query(
        func.date_trunc('month', Expense.date).label('month'),
        func.sum(Expense.amount).label('total')
    ).filter(
        Expense.user_id == current_user.id,
        Expense.date >= start_date
    ).group_by(
        func.date_trunc('month', Expense.date)
    ).order_by(
        func.date_trunc('month', Expense.date)
    ).all()
    
    # Get income data by month
    income_data = db.session.query(
        func.date_trunc('month', Income.date).label('month'),
        func.sum(Income.amount).label('total')
    ).filter(
        Income.user_id == current_user.id,
        Income.date >= start_date
    ).group_by(
        func.date_trunc('month', Income.date)
    ).order_by(
        func.date_trunc('month', Income.date)
    ).all()
    
    # Create a dictionary of expense data by month
    expense_dict = {}
    for month_date, total in expense_data:
        if month_date:
            month_key = month_date.strftime('%Y-%m')
            expense_dict[month_key] = float(total)
    
    # Create a dictionary of income data by month
    income_dict = {}
    for month_date, total in income_data:
        if month_date:
            month_key = month_date.strftime('%Y-%m')
            income_dict[month_key] = float(total)
    
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
    
    # Combine data into a single list
    result = []
    for month in months_list:
        month_key = month['key']
        result.append({
            'month': month['label'],
            'expenses': expense_dict.get(month_key, 0),
            'income': income_dict.get(month_key, 0),
            'balance': income_dict.get(month_key, 0) - expense_dict.get(month_key, 0)
        })
    
    return result

def export_expenses_report(start_date, end_date):
    """Export detailed expenses report as CSV"""
    # Get expenses in date range
    expenses = Expense.query.filter(
        Expense.user_id == current_user.id,
        Expense.date >= start_date,
        Expense.date <= end_date
    ).order_by(Expense.date.desc()).all()
    
    # Create CSV file
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Write header row
    writer.writerow([
        'Date', 'Description', 'Category', 'Amount', 'Payment Method', 
        'Location', 'Recurring', 'Notes'
    ])
    
    # Write data rows
    for expense in expenses:
        category_name = expense.category.name if expense.category else 'Uncategorized'
        
        writer.writerow([
            expense.formatted_date,
            expense.description or '',
            category_name,
            expense.formatted_amount,
            expense.payment_method or '',
            expense.location or '',
            'Yes' if expense.is_recurring else 'No',
            expense.notes or ''
        ])
    
    # Create response
    output.seek(0)
    return current_app.response_class(
        output.getvalue(),
        mimetype='text/csv',
        headers={
            'Content-Disposition': f'attachment;filename=expenses_report_{start_date.strftime("%Y%m%d")}-{end_date.strftime("%Y%m%d")}.csv'
        }
    )

def export_income_report(start_date, end_date):
    """Export detailed income report as CSV"""
    # Get income entries in date range
    incomes = Income.query.filter(
        Income.user_id == current_user.id,
        Income.date >= start_date,
        Income.date <= end_date
    ).order_by(Income.date.desc()).all()
    
    # Create CSV file
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Write header row
    writer.writerow([
        'Date', 'Source', 'Description', 'Amount', 'After-Tax Amount',
        'Category', 'Recurring', 'Taxable', 'Tax Rate (%)'
    ])
    
    # Write data rows
    for income in incomes:
        category_name = income.category.name if income.category else 'Uncategorized'
        
        writer.writerow([
            income.formatted_date,
            income.source,
            income.description or '',
            income.formatted_amount,
            "{:.2f}".format(income.after_tax_amount),
            category_name,
            'Yes' if income.is_recurring else 'No',
            'Yes' if income.is_taxable else 'No',
            income.tax_rate or ''
        ])
    
    # Create response
    output.seek(0)
    return current_app.response_class(
        output.getvalue(),
        mimetype='text/csv',
        headers={
            'Content-Disposition': f'attachment;filename=income_report_{start_date.strftime("%Y%m%d")}-{end_date.strftime("%Y%m%d")}.csv'
        }
    )

def export_monthly_report(start_date, end_date):
    """Export monthly summary report as CSV"""
    # Create CSV file
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Write header row
    writer.writerow([
        'Month', 'Income', 'Expenses', 'Net Balance', 'Savings Rate (%)'
    ])
    
    # Generate monthly data
    current_date = date(start_date.year, start_date.month, 1)
    end_month_date = date(end_date.year, end_date.month, 1)
    
    while current_date <= end_month_date:
        # Calculate month end date
        _, days_in_month = calendar.monthrange(current_date.year, current_date.month)
        month_end = date(current_date.year, current_date.month, days_in_month)
        
        # Get monthly totals
        month_income = get_income_total(current_date, month_end)
        month_expenses = get_expense_total(current_date, month_end)
        month_balance = month_income - month_expenses
        
        # Calculate savings rate
        savings_rate = (month_balance / month_income * 100) if month_income > 0 else 0
        
        # Write row
        writer.writerow([
            current_date.strftime('%B %Y'),
            "{:.2f}".format(month_income),
            "{:.2f}".format(month_expenses),
            "{:.2f}".format(month_balance),
            "{:.2f}".format(savings_rate)
        ])
        
        # Move to next month
        if current_date.month == 12:
            current_date = date(current_date.year + 1, 1, 1)
        else:
            current_date = date(current_date.year, current_date.month + 1, 1)
    
    # Write overall totals
    total_income = get_income_total(start_date, end_date)
    total_expenses = get_expense_total(start_date, end_date)
    total_balance = total_income - total_expenses
    overall_savings_rate = (total_balance / total_income * 100) if total_income > 0 else 0
    
    # Add a blank row and then totals
    writer.writerow([])
    writer.writerow([
        'TOTAL',
        "{:.2f}".format(total_income),
        "{:.2f}".format(total_expenses),
        "{:.2f}".format(total_balance),
        "{:.2f}".format(overall_savings_rate)
    ])
    
    # Create response
    output.seek(0)
    return current_app.response_class(
        output.getvalue(),
        mimetype='text/csv',
        headers={
            'Content-Disposition': f'attachment;filename=monthly_report_{start_date.strftime("%Y%m%d")}-{end_date.strftime("%Y%m%d")}.csv'
        }
    )

def export_cashflow_report(start_date, end_date):
    """Export cash flow report as CSV"""
    # Create CSV file
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Write header row
    writer.writerow([
        'Month', 'Income', 'Expenses', 'Monthly Balance', 'Cumulative Balance'
    ])
    
    # Generate monthly data
    current_date = date(start_date.year, start_date.month, 1)
    end_month_date = date(end_date.year, end_date.month, 1)
    
    cumulative_balance = 0
    
    while current_date <= end_month_date:
        # Calculate month end date
        _, days_in_month = calendar.monthrange(current_date.year, current_date.month)
        month_end = date(current_date.year, current_date.month, days_in_month)
        
        # Get monthly totals
        month_income = get_income_total(current_date, month_end)
        month_expenses = get_expense_total(current_date, month_end)
        month_balance = month_income - month_expenses
        
        # Update cumulative balance
        cumulative_balance += month_balance
        
        # Write row
        writer.writerow([
            current_date.strftime('%B %Y'),
            "{:.2f}".format(month_income),
            "{:.2f}".format(month_expenses),
            "{:.2f}".format(month_balance),
            "{:.2f}".format(cumulative_balance)
        ])
        
        # Move to next month
        if current_date.month == 12:
            current_date = date(current_date.year + 1, 1, 1)
        else:
            current_date = date(current_date.year, current_date.month + 1, 1)
    
    # Create response
    output.seek(0)
    return current_app.response_class(
        output.getvalue(),
        mimetype='text/csv',
        headers={
            'Content-Disposition': f'attachment;filename=cashflow_report_{start_date.strftime("%Y%m%d")}-{end_date.strftime("%Y%m%d")}.csv'
        }
    )

@report_routes.route('/api/dashboard-data')
@login_required
def dashboard_data():
    """API endpoint to get dashboard data"""
    # Get today's date and calculate start dates for different periods
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday())
    start_of_month = date(today.year, today.month, 1)
    
    # Get expense and income totals for different time periods
    stats = {
        'today': {
            'expenses': get_expense_total(today, today),
            'income': get_income_total(today, today)
        },
        'week': {
            'expenses': get_expense_total(start_of_week, today),
            'income': get_income_total(start_of_week, today)
        },
        'month': {
            'expenses': get_expense_total(start_of_month, today),
            'income': get_income_total(start_of_month, today)
        }
    }
    
    # Calculate balance for each period
    for period in stats:
        stats[period]['balance'] = stats[period]['income'] - stats[period]['expenses']
    
    # Get monthly trend data
    trend_data = get_monthly_trend(6)  # Last 6 months
    
    # Format data for JSON response
    response = {
        'stats': stats,
        'trend': trend_data
    }
    
    return jsonify(response)

@report_routes.route('/net-worth')
@login_required
def net_worth():
    """Net worth tracking report (placeholder - for future implementation)"""
    # This is a placeholder for future net worth tracking feature
    return render_template(
        'reports/coming_soon.html',
        feature_name='Net Worth Tracking',
        feature_description='Track your assets, liabilities, and overall net worth over time.',
        title='Net Worth Report'
    )

@report_routes.route('/tax')
@login_required
def tax():
    """Tax report (placeholder - for future implementation)"""
    # This is a placeholder for future tax reporting feature
    return render_template(
        'reports/coming_soon.html',
        feature_name='Tax Reporting',
        feature_description='Generate reports for tax filing with income and expense categories relevant for tax purposes.',
        title='Tax Report'
    )
