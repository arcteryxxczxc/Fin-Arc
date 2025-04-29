from flask import Blueprint, request, jsonify, current_app, render_template, redirect, url_for, flash
from flask_jwt_extended import jwt_required, get_jwt_identity
from flask_login import login_required, current_user
from app import db
from app.models.expense import Expense
from app.models.category import Category
from app.models.user import User
from app.forms.expenses import ExpenseForm, ExpenseFilterForm, ExpenseBulkActionForm
from sqlalchemy import or_, and_, func
from datetime import datetime, timedelta
import csv
import io
import logging

# Set up logger
logger = logging.getLogger(__name__)

# Create a blueprint for expense routes
expense_routes = Blueprint('expenses', __name__, url_prefix='/expenses')

@expense_routes.route('/')
@login_required
def index():
    """
    Display a list of expenses with filtering options
    """
    # Initialize the filter form
    filter_form = ExpenseFilterForm()
    bulk_action_form = ExpenseBulkActionForm()
    
    # Get categories for the form dropdowns
    categories = Category.query.filter_by(
        user_id=current_user.id,
        is_income=False,
        is_active=True
    ).order_by(Category.name).all()
    
    filter_form.category_id.choices = [(-1, 'All Categories')] + [(c.id, c.name) for c in categories]
    bulk_action_form.target_category_id.choices = [(c.id, c.name) for c in categories]
    
    # Handle filter parameters
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    
    # Build query
    query = Expense.query.filter_by(user_id=current_user.id)
    
    # Apply filters from request parameters
    category_id = request.args.get('category_id', type=int)
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    payment_method = request.args.get('payment_method')
    min_amount = request.args.get('min_amount', type=float)
    max_amount = request.args.get('max_amount', type=float)
    search = request.args.get('search')
    
    # Pre-fill form with query params
    if start_date:
        filter_form.start_date.data = datetime.strptime(start_date, '%Y-%m-%d').date()
        query = query.filter(Expense.date >= filter_form.start_date.data)
        
    if end_date:
        filter_form.end_date.data = datetime.strptime(end_date, '%Y-%m-%d').date()
        query = query.filter(Expense.date <= filter_form.end_date.data)
        
    if category_id and category_id > 0:
        filter_form.category_id.data = category_id
        query = query.filter(Expense.category_id == category_id)
        
    if payment_method:
        filter_form.payment_method.data = payment_method
        query = query.filter(Expense.payment_method == payment_method)
        
    if min_amount:
        filter_form.min_amount.data = min_amount
        query = query.filter(Expense.amount >= min_amount)
        
    if max_amount:
        filter_form.max_amount.data = max_amount
        query = query.filter(Expense.amount <= max_amount)
        
    if search:
        filter_form.search.data = search
        search_term = f'%{search}%'
        query = query.filter(
            or_(
                Expense.description.ilike(search_term),
                Expense.notes.ilike(search_term),
                Expense.location.ilike(search_term)
            )
        )
    
    # Order by date (newest first)
    query = query.order_by(Expense.date.desc(), Expense.id.desc())
    
    # Paginate results
    expenses = query.paginate(page=page, per_page=per_page, error_out=False)
    
    # Calculate totals for filtered expenses
    total_amount = db.session.query(func.sum(Expense.amount)).filter(
        Expense.user_id == current_user.id
    ).scalar() or 0
    
    filtered_total = db.session.query(func.sum(Expense.amount)).filter(
        query.whereclause
    ).scalar() or 0
    
    # Get quick stats for sidebar
    today = datetime.now().date()
    start_of_week = today - timedelta(days=today.weekday())
    start_of_month = today.replace(day=1)
    
    today_total = db.session.query(func.sum(Expense.amount)).filter(
        Expense.user_id == current_user.id,
        Expense.date == today
    ).scalar() or 0
    
    week_total = db.session.query(func.sum(Expense.amount)).filter(
        Expense.user_id == current_user.id,
        Expense.date >= start_of_week
    ).scalar() or 0
    
    month_total = db.session.query(func.sum(Expense.amount)).filter(
        Expense.user_id == current_user.id,
        Expense.date >= start_of_month
    ).scalar() or 0
    
    stats = {
        'today': float(today_total),
        'week': float(week_total),
        'month': float(month_total),
        'total': float(total_amount),
        'filtered': float(filtered_total)
    }
    
    return render_template(
        'expenses/index.html',
        expenses=expenses,
        filter_form=filter_form,
        bulk_action_form=bulk_action_form,
        stats=stats,
        title='Expenses'
    )

@expense_routes.route('/add', methods=['GET', 'POST'])
@login_required
def add():
    """Add a new expense"""
    form = ExpenseForm()
    
    # Get categories for the form dropdown
    categories = Category.query.filter_by(
        user_id=current_user.id,
        is_income=False,
        is_active=True
    ).order_by(Category.name).all()
    
    form.category_id.choices = [(0, 'Select Category')] + [(c.id, c.name) for c in categories]
    
    if form.validate_on_submit():
        try:
            # Create new expense
            expense = Expense(
                user_id=current_user.id,
                amount=form.amount.data,
                description=form.description.data,
                date=form.date.data,
                time=form.time.data,
                payment_method=form.payment_method.data,
                location=form.location.data,
                is_recurring=form.is_recurring.data,
                recurring_type=form.recurring_type.data if form.is_recurring.data else None,
                notes=form.notes.data
            )
            
            # Handle category
            if form.category_id.data > 0:
                expense.category_id = form.category_id.data
            
            # Handle receipt upload
            if form.receipt.data:
                # Save receipt file
                # This is a placeholder - actual file saving would be implemented here
                expense.has_receipt = True
                expense.receipt_path = "path/to/receipt.jpg"  # Replace with actual path
            
            # Add to database
            db.session.add(expense)
            db.session.commit()
            
            flash('Expense added successfully!', 'success')
            return redirect(url_for('expenses.index'))
        
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error adding expense: {str(e)}")
            flash('An error occurred while adding the expense. Please try again.', 'danger')
    
    return render_template('expenses/add.html', form=form, title='Add Expense')

@expense_routes.route('/edit/<int:id>', methods=['GET', 'POST'])
@login_required
def edit(id):
    """Edit an existing expense"""
    expense = Expense.query.filter_by(id=id, user_id=current_user.id).first_or_404()
    form = ExpenseForm(obj=expense)
    
    # Get categories for the form dropdown
    categories = Category.query.filter_by(
        user_id=current_user.id,
        is_income=False,
        is_active=True
    ).order_by(Category.name).all()
    
    form.category_id.choices = [(0, 'Select Category')] + [(c.id, c.name) for c in categories]
    
    if form.validate_on_submit():
        try:
            # Update expense data
            expense.amount = form.amount.data
            expense.description = form.description.data
            expense.date = form.date.data
            expense.time = form.time.data
            expense.payment_method = form.payment_method.data
            expense.location = form.location.data
            expense.is_recurring = form.is_recurring.data
            expense.recurring_type = form.recurring_type.data if form.is_recurring.data else None
            expense.notes = form.notes.data
            
            # Handle category
            if form.category_id.data > 0:
                expense.category_id = form.category_id.data
            else:
                expense.category_id = None
            
            # Handle receipt upload
            if form.receipt.data:
                # Save receipt file
                # This is a placeholder - actual file saving would be implemented here
                expense.has_receipt = True
                expense.receipt_path = "path/to/receipt.jpg"  # Replace with actual path
            
            # Save changes
            db.session.commit()
            
            flash('Expense updated successfully!', 'success')
            return redirect(url_for('expenses.index'))
        
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error updating expense: {str(e)}")
            flash('An error occurred while updating the expense. Please try again.', 'danger')
    
    return render_template('expenses/edit.html', form=form, expense=expense, title='Edit Expense')

@expense_routes.route('/delete/<int:id>', methods=['POST'])
@login_required
def delete(id):
    """Delete an expense"""
    expense = Expense.query.filter_by(id=id, user_id=current_user.id).first_or_404()
    
    try:
        # Delete expense
        db.session.delete(expense)
        db.session.commit()
        
        flash('Expense deleted successfully!', 'success')
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error deleting expense: {str(e)}")
        flash('An error occurred while deleting the expense.', 'danger')
    
    return redirect(url_for('expenses.index'))

@expense_routes.route('/view/<int:id>')
@login_required
def view(id):
    """View expense details"""
    expense = Expense.query.filter_by(id=id, user_id=current_user.id).first_or_404()
    return render_template('expenses/view.html', expense=expense, title='Expense Details')

@expense_routes.route('/bulk-action', methods=['POST'])
@login_required
def bulk_action():
    """Perform bulk actions on selected expenses"""
    form = ExpenseBulkActionForm()
    
    # Get categories for the form dropdown
    categories = Category.query.filter_by(
        user_id=current_user.id,
        is_income=False,
        is_active=True
    ).order_by(Category.name).all()
    
    form.target_category_id.choices = [(c.id, c.name) for c in categories]
    
    if form.validate_on_submit():
        selected_ids = form.selected_expenses.data.split(',')
        action = form.action.data
        
        if not selected_ids:
            flash('No expenses selected.', 'warning')
            return redirect(url_for('expenses.index'))
        
        try:
            # Convert IDs to integers and filter by user_id for security
            expense_ids = [int(id) for id in selected_ids if id]
            expenses = Expense.query.filter(
                Expense.id.in_(expense_ids),
                Expense.user_id == current_user.id
            ).all()
            
            if not expenses:
                flash('No valid expenses selected.', 'warning')
                return redirect(url_for('expenses.index'))
            
            if action == 'delete':
                # Delete expenses
                for expense in expenses:
                    db.session.delete(expense)
                
                db.session.commit()
                flash(f'{len(expenses)} expenses deleted successfully!', 'success')
                
            elif action == 'change_category':
                # Change category for all selected expenses
                target_category_id = form.target_category_id.data
                
                for expense in expenses:
                    expense.category_id = target_category_id
                
                db.session.commit()
                flash(f'Category updated for {len(expenses)} expenses!', 'success')
                
            elif action == 'export':
                # Export selected expenses as CSV
                return export_expenses_csv(expenses)
            
            else:
                flash('Invalid action selected.', 'warning')
        
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error in bulk action: {str(e)}")
            flash('An error occurred while processing the bulk action.', 'danger')
    
    return redirect(url_for('expenses.index'))

@expense_routes.route('/export')
@login_required
def export():
    """Export all expenses as CSV"""
    # Get all expenses for the current user
    expenses = Expense.query.filter_by(user_id=current_user.id).order_by(Expense.date.desc()).all()
    return export_expenses_csv(expenses)

def export_expenses_csv(expenses):
    """Helper function to export expenses as CSV"""
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Write header row
    writer.writerow([
        'ID', 'Date', 'Time', 'Description', 'Amount', 'Category',
        'Payment Method', 'Location', 'Recurring', 'Notes'
    ])
    
    # Write data rows
    for expense in expenses:
        category_name = expense.category.name if expense.category else 'Uncategorized'
        time_str = expense.time.strftime('%H:%M') if expense.time else ''
        
        writer.writerow([
            expense.id,
            expense.formatted_date,
            time_str,
            expense.description or '',
            expense.formatted_amount,
            category_name,
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
        headers={'Content-Disposition': f'attachment;filename=expenses_{datetime.now().strftime("%Y%m%d")}.csv'}
    )

@expense_routes.route('/stats')
@login_required
def stats():
    """View expense statistics and trends"""
    # Get date range from request or use default (last 6 months)
    months = request.args.get('months', 6, type=int)
    
    # Calculate start date
    today = datetime.now()
    start_month = today.month - months
    start_year = today.year
    
    # Adjust for previous year
    while start_month <= 0:
        start_month += 12
        start_year -= 1
        
    start_date = datetime(start_year, start_month, 1).date()
    
    # Get expense breakdown by category
    category_breakdown = Expense.get_total_by_category(current_user.id, start_date)
    
    # Get monthly expense trend
    monthly_trend = Expense.get_total_by_month(current_user.id)
    
    # Format data for charts
    category_data = []
    for category_id, category_name, category_total in category_breakdown:
        # Get category color or use default
        color = "#757575"  # Default color
        if category_id:
            category = Category.query.get(category_id)
            if category:
                color = category.color_code
        
        category_data.append({
            'id': category_id,
            'name': category_name or "Uncategorized",
            'total': float(category_total),
            'color': color
        })
    
    monthly_data = []
    for month_date, total in monthly_trend:
        if month_date:
            month_str = month_date.strftime('%b %Y')
            monthly_data.append({
                'month': month_str,
                'total': float(total)
            })
    
    return render_template(
        'expenses/stats.html',
        category_data=category_data,
        monthly_data=monthly_data,
        months=months,
        title='Expense Statistics'
    )

# API endpoints for expenses
@expense_routes.route('/api/expenses', methods=['GET'])
@jwt_required()
def get_expenses():
    """
    Get a list of expenses for the current user via API
    
    Query parameters:
    - page: Page number (default: 1)
    - per_page: Items per page (default: 10)
    - category_id: Filter by category
    - start_date: Filter by start date (YYYY-MM-DD)
    - end_date: Filter by end date (YYYY-MM-DD)
    - min_amount: Filter by minimum amount
    - max_amount: Filter by maximum amount
    - payment_method: Filter by payment method
    - search: Search in description, notes, or location
    
    Returns:
        JSON response with a list of expenses and pagination info
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return jsonify({"msg": "User not found"}), 404
        
        # Get pagination parameters
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        
        # Build the query
        query = Expense.query.filter_by(user_id=user.id)
        
        # Apply filters
        category_id = request.args.get('category_id', type=int)
        if category_id:
            query = query.filter(Expense.category_id == category_id)
        
        start_date = request.args.get('start_date')
        if start_date:
            query = query.filter(Expense.date >= datetime.strptime(start_date, '%Y-%m-%d').date())
        
        end_date = request.args.get('end_date')
        if end_date:
            query = query.filter(Expense.date <= datetime.strptime(end_date, '%Y-%m-%d').date())
        
        min_amount = request.args.get('min_amount', type=float)
        if min_amount:
            query = query.filter(Expense.amount >= min_amount)
        
        max_amount = request.args.get('max_amount', type=float)
        if max_amount:
            query = query.filter(Expense.amount <= max_amount)
        
        payment_method = request.args.get('payment_method')
        if payment_method:
            query = query.filter(Expense.payment_method == payment_method)
        
        search = request.args.get('search')
        if search:
            search_term = f"%{search}%"
            query = query.filter(
                or_(
                    Expense.description.ilike(search_term),
                    Expense.notes.ilike(search_term),
                    Expense.location.ilike(search_term)
                )
            )
        
        # Order by date (newest first)
        query = query.order_by(Expense.date.desc(), Expense.id.desc())
        
        # Paginate
        expenses_page = query.paginate(page=page, per_page=per_page, error_out=False)
        
        # Format response
        result = {
            "expenses": [{
                "id": expense.id,
                "amount": float(expense.amount),
                "formatted_amount": expense.formatted_amount,
                "description": expense.description,
                "date": expense.formatted_date,
                "category_id": expense.category_id,
                "category_name": expense.category.name if expense.category else "Uncategorized",
                "payment_method": expense.payment_method,
                "location": expense.location,
                "has_receipt": expense.has_receipt,
                "is_recurring": expense.is_recurring,
                "recurring_type": expense.recurring_type,
                "notes": expense.notes
            } for expense in expenses_page.items],
            "pagination": {
                "page": expenses_page.page,
                "per_page": expenses_page.per_page,
                "total_pages": expenses_page.pages,
                "total_items": expenses_page.total
            }
        }
        
        return jsonify(result), 200
        
    except Exception as e:
        logger.error(f"Error getting expenses: {str(e)}")
        return jsonify({"msg": "An error occurred while retrieving expenses"}), 500