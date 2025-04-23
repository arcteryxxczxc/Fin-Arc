from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.models import User, Expense, Income, Category
from app.services.currency import CurrencyService
from sqlalchemy import func
from datetime import datetime, timedelta
import calendar

@api_bp.route('/reports/monthly', methods=['GET'])
@jwt_required()
def monthly_report():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    year = request.args.get('year', type=int)
    month = request.args.get('month', type=int)
    currency = request.args.get('currency', default='UZS')
    
    # If year and month not provided, use current month
    if not year or not month:
        today = datetime.today()
        year = today.year
        month = today.month
    
    # Get first and last day of the month
    first_day = datetime(year, month, 1)
    last_day = datetime(year, month, calendar.monthrange(year, month)[1], 23, 59, 59)
    
    # Get all expenses for this month
    expenses = Expense.query.filter(
        Expense.user_id == user.id,
        Expense.date >= first_day,
        Expense.date <= last_day
    ).all()
    
    # Get all incomes for this month
    incomes = Income.query.filter(
        Income.user_id == user.id,
        Income.date >= first_day,
        Income.date <= last_day
    ).all()
    
    # Calculate totals
    total_expense = 0
    total_income = 0
    expense_by_category = {}
    
    for expense in expenses:
        # Convert amount to requested currency if needed
        amount = expense.amount
        if expense.currency != currency:
            amount = CurrencyService.convert_amount(amount, expense.currency, currency)
        
        total_expense += amount
        
        # Group by category
        category_name = expense.category.name if expense.category else "Uncategorized"
        if category_name not in expense_by_category:
            expense_by_category[category_name] = 0
        expense_by_category[category_name] += amount
    
    for income in incomes:
        # Convert amount to requested currency if needed
        amount = income.amount
        if income.currency != currency:
            amount = CurrencyService.convert_amount(amount, income.currency, currency)
        
        total_income += amount
    
    # Calculate balance
    balance = total_income - total_expense
    
    # Check budget limits
    categories = Category.query.filter_by(user_id=user.id).all()
    budget_status = []
    
    for category in categories:
        spent = expense_by_category.get(category.name, 0)
        budget = category.budget_limit
        
        if budget:
            # Convert budget to requested currency if needed
            if currency != 'UZS':  # Assuming budget is stored in UZS
                budget = CurrencyService.convert_amount(budget, 'UZS', currency)
            
            budget_status.append({
                "category": category.name,
                "budget": budget,
                "spent": spent,
                "remaining": budget - spent,
                "percentage": round((spent / budget) * 100, 2) if budget > 0 else 0
            })
    
    return jsonify({
        "year": year,
        "month": month,
        "currency": currency,
        "total_income": total_income,
        "total_expense": total_expense,
        "balance": balance,
        "expense_by_category": expense_by_category,
        "budget_status": budget_status
    }), 200

@api_bp.route('/reports/category', methods=['GET'])
@jwt_required()
def category_report():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    category_id = request.args.get('category_id', type=int)
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    currency = request.args.get('currency', default='UZS')
    
    if not category_id:
        return jsonify({"msg": "Category ID is required"}), 400
    
    # Check if category exists and belongs to user
    category = Category.query.filter_by(id=category_id, user_id=user.id).first()
    if not category:
        return jsonify({"msg": "Category not found or doesn't belong to user"}), 404
    
    # Parse dates
    if start_date:
        try:
            start_date = datetime.strptime(start_date, '%Y-%m-%d')
        except ValueError:
            return jsonify({"msg": "Invalid start_date format. Use YYYY-MM-DD."}), 400
    else:
        # Default to 30 days ago
        start_date = datetime.utcnow() - timedelta(days=30)
    
    if end_date:
        try:
            end_date = datetime.strptime(end_date, '%Y-%m-%d')
        except ValueError:
            return jsonify({"msg": "Invalid end_date format. Use YYYY-MM-DD."}), 400
    else:
        # Default to today
        end_date = datetime.utcnow()
    
    # Get expenses for this category in date range
    expenses = Expense.query.filter(
        Expense.user_id == user.id,
        Expense.category_id == category_id,
        Expense.date >= start_date,
        Expense.date <= end_date
    ).order_by(Expense.date.desc()).all()
    
    # Calculate total expense for this category
    total = 0
    expense_list = []
    
    for expense in expenses:
        # Convert amount to requested currency if needed
        amount = expense.amount
        if expense.currency != currency:
            amount = CurrencyService.convert_amount(amount, expense.currency, currency)
        
        total += amount
        
        expense_list.append({
            "id": expense.id,
            "date": expense.date.strftime('%Y-%m-%d'),
            "description": expense.description,
            "amount": amount,
            "original_amount": expense.amount,
            "original_currency": expense.currency
        })
    
    # Get daily expenses for this category
    daily_totals = db.session.query(
        func.date(Expense.date).label('day'),
        func.sum(Expense.amount).label('total')
    ).filter(
        Expense.user_id == user.id,
        Expense.category_id == category_id,
        Expense.date >= start_date,
        Expense.date <= end_date
    ).group_by(func.date(Expense.date)).all()
    
    # Format daily expenses for chart data
    daily_data = []
    for day, day_total in daily_totals:
        # Convert amount to requested currency if needed
        day_amount = day_total
        if currency != 'UZS':  # Assuming expenses are stored in UZS
            day_amount = CurrencyService.convert_amount(day_total, 'UZS', currency)
        
        daily_data.append({
            "date": day.strftime('%Y-%m-%d'),
            "amount": day_amount
        })
    
    # Check budget status
    budget = category.budget_limit
    if budget and currency != 'UZS':  # Assuming budget is stored in UZS
        budget = CurrencyService.convert_amount(budget, 'UZS', currency)
    
    budget_status = None
    if budget:
        budget_status = {
            "budget": budget,
            "spent": total,
            "remaining": budget - total,
            "percentage": round((total / budget) * 100, 2) if budget > 0 else 0
        }
    
    return jsonify({
        "category": {
            "id": category.id,
            "name": category.name,
            "color_code": category.color_code
        },
        "date_range": {
            "start": start_date.strftime('%Y-%m-%d'),
            "end": end_date.strftime('%Y-%m-%d')
        },
        "currency": currency,
        "total_expense": total,
        "expenses": expense_list,
        "daily_expenses": daily_data,
        "budget_status": budget_status
    }), 200

@api_bp.route('/reports/summary', methods=['GET'])
@jwt_required()
def summary_report():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    currency = request.args.get('currency', default='UZS')
    period = request.args.get('period', default='month')  # month, year, all
    
    today = datetime.utcnow()
    
    # Determine start date based on period
    if period == 'month':
        start_date = datetime(today.year, today.month, 1)
    elif period == 'year':
        start_date = datetime(today.year, 1, 1)
    else:  # all
        start_date = datetime(1900, 1, 1)  # Far in the past
    
    # Get totals
    total_expense = 0
    total_income = 0
    
    expenses = Expense.query.filter(
        Expense.user_id == user.id,
        Expense.date >= start_date
    ).all()
    
    incomes = Income.query.filter(
        Income.user_id == user.id,
        Income.date >= start_date
    ).all()
    
    for expense in expenses:
        # Convert amount to requested currency if needed
        amount = expense.amount
        if expense.currency != currency:
            amount = CurrencyService.convert_amount(amount, expense.currency, currency)
        total_expense += amount
    
    for income in incomes:
        # Convert amount to requested currency if needed
        amount = income.amount
        if income.currency != currency:
            amount = CurrencyService.convert_amount(amount, income.currency, currency)
        total_income += amount
    
    # Get expense by category
    categories = Category.query.filter_by(user_id=user.id).all()
    category_expenses = []
    
    for category in categories:
        cat_expenses = Expense.query.filter(
            Expense.user_id == user.id,
            Expense.category_id == category.id,
            Expense.date >= start_date
        ).all()
        
        cat_total = 0
        for expense in cat_expenses:
            # Convert amount to requested currency if needed
            amount = expense.amount
            if expense.currency != currency:
                amount = CurrencyService.convert_amount(amount, expense.currency, currency)
            cat_total += amount
        
        # Only include categories with expenses
        if cat_total > 0:
            category_expenses.append({
                "id": category.id,
                "name": category.name,
                "color_code": category.color_code,
                "total": cat_total,
                "percentage": round((cat_total / total_expense) * 100, 2) if total_expense > 0 else 0
            })
    
    # Sort categories by total expense (descending)
    category_expenses.sort(key=lambda x: x['total'], reverse=True)
    
    # Calculate balance
    balance = total_income - total_expense
    saving_rate = round((balance / total_income) * 100, 2) if total_income > 0 else 0
    
    # Get last 5 transactions
    last_expenses = Expense.query.filter_by(user_id=user.id).order_by(Expense.date.desc()).limit(5).all()
    last_incomes = Income.query.filter_by(user_id=user.id).order_by(Income.date.desc()).limit(5).all()
    
    recent_expenses = []
    for expense in last_expenses:
        # Convert amount to requested currency if needed
        amount = expense.amount
        if expense.currency != currency:
            amount = CurrencyService.convert_amount(amount, expense.currency, currency)
        
        recent_expenses.append({
            "id": expense.id,
            "date": expense.date.strftime('%Y-%m-%d'),
            "description": expense.description,
            "category": expense.category.name if expense.category else "Uncategorized",
            "amount": amount,
            "currency": currency
        })
    
    recent_incomes = []
    for income in last_incomes:
        # Convert amount to requested currency if needed
        amount = income.amount
        if income.currency != currency:
            amount = CurrencyService.convert_amount(amount, income.currency, currency)
        
        recent_incomes.append({
            "id": income.id,
            "date": income.date.strftime('%Y-%m-%d'),
            "source": income.source,
            "amount": amount,
            "currency": currency
        })
    
    return jsonify({
        "period": period,
        "currency": currency,
        "summary": {
            "total_income": total_income,
            "total_expense": total_expense,
            "balance": balance,
            "saving_rate": saving_rate
        },
        "category_expenses": category_expenses,
        "recent_transactions": {
            "expenses": recent_expenses,
            "incomes": recent_incomes
        }
    }), 200