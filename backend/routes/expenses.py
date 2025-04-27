# backend/routes/expenses.py

from flask import Blueprint, render_template, redirect, url_for, flash, request, jsonify, current_app
from flask_login import login_required, current_user
from werkzeug.utils import secure_filename
from backend.app import db
from backend.models.expense import Expense
from backend.models.category import Category
from backend.forms.expenses import ExpenseForm, ExpenseFilterForm, ExpenseBulkActionForm
import os
from datetime import datetime, timedelta
from sqlalchemy import or_, and_
import csv
import io
import logging

# Set up logging
logger = logging.getLogger(__name__)

# Create a Blueprint for expense routes
expense_routes = Blueprint('expenses', __name__, url_prefix='/expenses')

@expense_routes.route('/')
@login_required
def index():
    """Display list of expenses with filters"""
    # Initialize the filter form
    filter_form = ExpenseFilterForm()
    bulk_action_form = ExpenseBulkActionForm()
    
    # Get categories for the filter and bulk action forms
    categories = Category.get_user_categories(current_user.id)
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
    min_amount = request.args.get('min_amount', type=float)
    max_amount = request.args.get('max_amount', type=float)
    payment_method = request.args.get('payment_method')
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
        
    if min_amount:
        filter_form.min_amount.data = min_amount
        query = query.filter(Expense.amount >= min_amount)
        
    if max_amount:
        filter_form.max_amount.data = max_amount
        query = query.filter(Expense.amount <= max_amount)
        
    if payment_method:
        filter_form.payment_method.data = payment_method
        query = query.filter(Expense.payment_method == payment_method)
        
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
    query = query.order_by(Expense.date.desc(), Expense.time.desc() if Expense.time else Expense.id.desc())
    
    # Paginate results
    expenses = query.paginate(page=page, per_page=per_page, error_out=False)
    
    # Calculate totals for filtered expenses
    total_amount = db.session.query(db.func.sum(Expense.amount)).filter(
        Expense.user_id == current_user.id
    ).scalar() or 0
    
    filtered_total = db.session.query(db.func.sum(Expense.amount)).filter(
        query.whereclause
    ).scalar() or 0
    
    # Get quick stats for sidebar
    today = datetime.now().date()
    start_of_week = today - timedelta(days=today.weekday())
    start_of_month = today.replace(day=1)
    
    today_total = db.session.query(db.func.sum(Expense.amount)).filter(
        Expense.user_id == current_user.id,
        Expense.date == today
    ).scalar() or 0
    
    week_total = db.session.query(db.func.sum(Expense.amount)).filter(
        Expense.user_id == current_user.id,
        Expense.date >= start_of_week
    ).scalar() or 0
    
    month_total = db.session.query(db.func.sum(Expense.amount)).filter(
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
    categories = Category.get_user_categories(current_user.id)
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
                location=form.location.data,
                payment_method=form.payment_method.data,
                is_recurring=form.is_recurring.data,
                recurring_type=form.recurring_type.data if form.is_recurring.data else None,
                notes=form.notes.data
            )
            
            # Handle category
            if form.category_id.data > 0:
                expense.category_id = form.category_id.data
            
            # Handle receipt upload
            if form.receipt.data:
                filename = secure_filename(form.receipt.data.filename)
                # Create unique filename
                unique_filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}_{filename}"
                
                # Get upload folder
                upload_folder = current_app.config.get('UPLOAD_FOLDER', 'uploads')
                receipt_dir = os.path.join(upload_folder, 'receipts', str(current_user.id))
                
                # Create directory if it doesn't exist
                os.makedirs(receipt_dir, exist_ok=True)
                
                # Save file
                file_path = os.path.join(receipt_dir, unique_filename)
                form.receipt.data.save(file_path)
                
                # Update expense with receipt info
                expense.has_receipt = True
                expense.receipt_path = os.path.join('receipts', str(current_user.id), unique_filename)
            
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
    categories = Category.get_user_categories(current_user.id)
    form.category_id.choices = [(0, 'Select Category')] + [(c.id, c.name) for c in categories]
    
    if form.validate_on_submit():
        try:
            # Update expense data
            expense.amount = form.amount.data
            expense.description = form.description.data
            expense.date = form.date.data
            expense.time = form.time.data
            expense.location = form.location.data
            expense.payment_method = form.payment_method.data
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
                # Delete old receipt if it exists
                if expense.has_receipt and expense.receipt_path:
                    old_path = os.path.join(current_app.config.get('UPLOAD_FOLDER', 'uploads'), expense.receipt_path)
                    if os.path.exists(old_path):
                        os.remove(old_path)
                
                filename = secure_filename(form.receipt.data.filename)
                # Create unique filename
                unique_filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}_{filename}"
                
                # Get upload folder
                upload_folder = current_app.config.get('UPLOAD_FOLDER', 'uploads')
                receipt_dir = os.path.join(upload_folder, 'receipts', str(current_user.id))
                
                # Create directory if it doesn't exist
                os.makedirs(receipt_dir, exist_ok=True)
                
                # Save file
                file_path = os.path.join(receipt_dir, unique_filename)
                form.receipt.data.save(file_path)
                
                # Update expense with receipt info
                expense.has_receipt = True
                expense.receipt_path = os.path.join('receipts', str(current_user.id), unique_filename)
            
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
        # Delete receipt file if it exists
        if expense.has_receipt and expense.receipt_path:
            file_path = os.path.join(current_app.config.get('UPLOAD_FOLDER', 'uploads'), expense.receipt_path)
            if os.path.exists(file_path):
                os.remove(file_path)
        
        # Delete expense from database
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
    categories = Category.get_user_categories(current_user.id)
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
                    # Delete receipt file if it exists
                    if expense.has_receipt and expense.receipt_path:
                        file_path = os.path.join(current_app.config.get('UPLOAD_FOLDER', 'uploads'), 
                                               expense.receipt_path)
                        if os.path.exists(file_path):
                            os.remove(file_path)
                    
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
        
        writer.writerow([
            expense.id,
            expense.formatted_date,
            expense.time.strftime('%H:%M') if expense.time else '',
            expense.description,
            expense.formatted_amount,
            category_name,
            expense.payment_method,
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

@expense_routes.route('/receipt/<int:id>')
@login_required
def view_receipt(id):
    """View an expense receipt"""
    expense = Expense.query.filter_by(id=id, user_id=current_user.id).first_or_404()
    
    if not expense.has_receipt or not expense.receipt_path:
        flash('This expense does not have a receipt.', 'warning')
        return redirect(url_for('expenses.view', id=id))
    
    # Get file path
    file_path = os.path.join(current_app.config.get('UPLOAD_FOLDER', 'uploads'), expense.receipt_path)
    
    # Check if file exists
    if not os.path.exists(file_path):
        flash('Receipt file not found.', 'warning')
        return redirect(url_for('expenses.view', id=id))
    
    # Determine file type and serve appropriately
    # This is a simplified approach - in production you might want to use send_file with appropriate mime type
    return render_template('expenses/receipt.html', expense=expense, title='View Receipt')

@expense_routes.route('/calendar')
@login_required
def calendar():
    """View expenses in a calendar format"""
    # Get categories for filtering
    categories = Category.get_user_categories(current_user.id)
    
    return render_template(
        'expenses/calendar.html',
        categories=categories,
        title='Expense Calendar'
    )

@expense_routes.route('/api/calendar-data')
@login_required
def calendar_data():
    """API endpoint to get expense data for calendar"""
    # Get date range from request
    start = request.args.get('start')
    end = request.args.get('end')
    category_id = request.args.get('category_id', type=int)
    
    # Parse dates
    try:
        start_date = datetime.fromisoformat(start.replace('Z', '+00:00')).date()
        end_date = datetime.fromisoformat(end.replace('Z', '+00:00')).date()
    except (ValueError, AttributeError):
        # Default to current month if dates are invalid
        today = datetime.now()
        start_date = datetime(today.year, today.month, 1).date()
        end_date = datetime(today.year, today.month + 1, 1).date() - timedelta(days=1)
    
    # Query expenses in date range
    query = Expense.query.filter(
        Expense.user_id == current_user.id,
        Expense.date >= start_date,
        Expense.date <= end_date
    )
    
    # Apply category filter if provided
    if category_id:
        query = query.filter(Expense.category_id == category_id)
    
    expenses = query.all()
    
    # Format data for calendar
    events = []
    for expense in expenses:
        category_color = expense.category.color_code if expense.category else '#757575'
        
        event = {
            'id': expense.id,
            'title': f"{expense.description or 'Expense'}: {expense.formatted_amount}",
            'start': expense.formatted_date,
            'url': url_for('expenses.view', id=expense.id),
            'backgroundColor': category_color,
            'borderColor': category_color
        }
        events.append(event)
    
    return jsonify(events)

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
    
    # Get categories for the current user
    categories = Category.query.filter_by(user_id=current_user.id, is_active=True).all()
    
    # Get expense breakdown by category
    category_breakdown = Expense.get_total_by_category(current_user.id, start_date)
    
    # Get monthly expense trend
    monthly_trend = Expense.get_total_by_month(current_user.id)
    
    # Format data for charts
    category_data = []
    for category_id, category_name, total in category_breakdown:
        color = '#757575'  # Default color
        for cat in categories:
            if cat.id == category_id:
                color = cat.color_code
                break
        
        category_data.append({
            'id': category_id,
            'name': category_name or 'Uncategorized',
            'total': float(total),
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