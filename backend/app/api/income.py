# backend/routes/income.py

from flask import Blueprint, render_template, redirect, url_for, flash, request, jsonify, current_app
from flask_login import login_required, current_user
from app import db
from models.income import Income
from models.category import Category
from forms.income import IncomeForm, IncomeFilterForm, IncomeBulkActionForm, RecurringIncomeForm
from sqlalchemy import or_, and_, func
from datetime import datetime, timedelta
import csv
import io
import logging

# Set up logging
logger = logging.getLogger(__name__)

# Create a Blueprint for income routes
income_routes = Blueprint('income', __name__, url_prefix='/income')

@income_routes.route('/')
@login_required
def index():
    """Display list of income entries with filters"""
    # Initialize the filter form
    filter_form = IncomeFilterForm()
    bulk_action_form = IncomeBulkActionForm()
    
    # Get categories for the filter and bulk action forms
    categories = Category.query.filter_by(
        user_id=current_user.id,
        is_income=True,
        is_active=True
    ).order_by(Category.name).all()
    
    filter_form.category_id.choices = [(-1, 'All Categories')] + [(c.id, c.name) for c in categories]
    bulk_action_form.target_category_id.choices = [(c.id, c.name) for c in categories]
    
    # Get unique sources for dropdown
    sources = db.session.query(Income.source).filter_by(
        user_id=current_user.id
    ).distinct().order_by(Income.source).all()
    
    filter_form.source.choices = [('', 'All Sources')] + [(s.source, s.source) for s in sources]
    
    # Handle filter parameters
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    
    # Build query
    query = Income.query.filter_by(user_id=current_user.id)
    
    # Apply filters from request parameters
    category_id = request.args.get('category_id', type=int)
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    source = request.args.get('source')
    min_amount = request.args.get('min_amount', type=float)
    max_amount = request.args.get('max_amount', type=float)
    is_recurring = request.args.get('is_recurring', type=bool)
    search = request.args.get('search')
    
    # Pre-fill form with query params
    if start_date:
        filter_form.start_date.data = datetime.strptime(start_date, '%Y-%m-%d').date()
        query = query.filter(Income.date >= filter_form.start_date.data)
        
    if end_date:
        filter_form.end_date.data = datetime.strptime(end_date, '%Y-%m-%d').date()
        query = query.filter(Income.date <= filter_form.end_date.data)
        
    if category_id and category_id > 0:
        filter_form.category_id.data = category_id
        query = query.filter(Income.category_id == category_id)
        
    if source:
        filter_form.source.data = source
        query = query.filter(Income.source == source)
        
    if min_amount:
        filter_form.min_amount.data = min_amount
        query = query.filter(Income.amount >= min_amount)
        
    if max_amount:
        filter_form.max_amount.data = max_amount
        query = query.filter(Income.amount <= max_amount)
        
    if is_recurring:
        filter_form.is_recurring.data = True
        query = query.filter(Income.is_recurring == True)
        
    if search:
        filter_form.search.data = search
        search_term = f'%{search}%'
        query = query.filter(
            or_(
                Income.description.ilike(search_term),
                Income.source.ilike(search_term)
            )
        )
    
    # Order by date (newest first)
    query = query.order_by(Income.date.desc(), Income.id.desc())
    
    # Paginate results
    incomes = query.paginate(page=page, per_page=per_page, error_out=False)
    
    # Calculate totals for filtered income
    total_amount = db.session.query(func.sum(Income.amount)).filter(
        Income.user_id == current_user.id
    ).scalar() or 0
    
    filtered_total = db.session.query(func.sum(Income.amount)).filter(
        query.whereclause
    ).scalar() or 0
    
    # Get quick stats for sidebar
    today = datetime.now().date()
    start_of_week = today - timedelta(days=today.weekday())
    start_of_month = today.replace(day=1)
    
    today_total = db.session.query(func.sum(Income.amount)).filter(
        Income.user_id == current_user.id,
        Income.date == today
    ).scalar() or 0
    
    week_total = db.session.query(func.sum(Income.amount)).filter(
        Income.user_id == current_user.id,
        Income.date >= start_of_week
    ).scalar() or 0
    
    month_total = db.session.query(func.sum(Income.amount)).filter(
        Income.user_id == current_user.id,
        Income.date >= start_of_month
    ).scalar() or 0
    
    stats = {
        'today': float(today_total),
        'week': float(week_total),
        'month': float(month_total),
        'total': float(total_amount),
        'filtered': float(filtered_total)
    }
    
    return render_template(
        'income/index.html',
        incomes=incomes,
        filter_form=filter_form,
        bulk_action_form=bulk_action_form,
        stats=stats,
        title='Income'
    )

@income_routes.route('/add', methods=['GET', 'POST'])
@login_required
def add():
    """Add a new income entry"""
    form = IncomeForm()
    
    # Get income categories for the form dropdown
    categories = Category.query.filter_by(
        user_id=current_user.id,
        is_income=True,
        is_active=True
    ).order_by(Category.name).all()
    
    form.category_id.choices = [(0, 'Select Category')] + [(c.id, c.name) for c in categories]
    
    if form.validate_on_submit():
        try:
            # Create new income entry
            income = Income(
                user_id=current_user.id,
                amount=form.amount.data,
                source=form.source.data,
                description=form.description.data,
                date=form.date.data,
                is_recurring=form.is_recurring.data,
                recurring_type=form.recurring_type.data if form.is_recurring.data else None,
                recurring_day=form.recurring_day.data if form.is_recurring.data else None,
                is_taxable=form.is_taxable.data,
                tax_rate=form.tax_rate.data if form.is_taxable.data else None
            )
            
            # Handle category
            if form.category_id.data > 0:
                income.category_id = form.category_id.data
            
            # Add to database
            db.session.add(income)
            db.session.commit()
            
            flash('Income added successfully!', 'success')
            return redirect(url_for('income.index'))
        
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error adding income: {str(e)}")
            flash('An error occurred while adding the income. Please try again.', 'danger')
    
    return render_template('income/add.html', form=form, title='Add Income')

@income_routes.route('/add-recurring', methods=['GET', 'POST'])
@login_required
def add_recurring():
    """Add a new recurring income"""
    form = RecurringIncomeForm()
    
    # Get income categories for the form dropdown
    categories = Category.query.filter_by(
        user_id=current_user.id,
        is_income=True,
        is_active=True
    ).order_by(Category.name).all()
    
    form.category_id.choices = [(0, 'Select Category')] + [(c.id, c.name) for c in categories]
    
    if form.validate_on_submit():
        try:
            # Create new recurring income entry
            income = Income(
                user_id=current_user.id,
                amount=form.amount.data,
                source=form.source.data,
                description=form.description.data,
                date=form.start_date.data,
                is_recurring=True,
                recurring_type=form.recurring_type.data,
                recurring_day=form.recurring_day.data,
                is_taxable=form.is_taxable.data,
                tax_rate=form.tax_rate.data if form.is_taxable.data else None
            )
            
            # Handle category
            if form.category_id.data > 0:
                income.category_id = form.category_id.data
            
            # Add to database
            db.session.add(income)
            db.session.commit()
            
            flash('Recurring income added successfully!', 'success')
            return redirect(url_for('income.index'))
        
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error adding recurring income: {str(e)}")
            flash('An error occurred while adding the recurring income. Please try again.', 'danger')
    
    return render_template('income/add_recurring.html', form=form, title='Add Recurring Income')

@income_routes.route('/edit/<int:id>', methods=['GET', 'POST'])
@login_required
def edit(id):
    """Edit an existing income entry"""
    income = Income.query.filter_by(id=id, user_id=current_user.id).first_or_404()
    
    # Choose form based on whether income is recurring
    if income.is_recurring:
        form = RecurringIncomeForm(obj=income)
        form.start_date.data = income.date
    else:
        form = IncomeForm(obj=income)
    
    # Get income categories for the form dropdown
    categories = Category.query.filter_by(
        user_id=current_user.id,
        is_income=True,
        is_active=True
    ).order_by(Category.name).all()
    
    form.category_id.choices = [(0, 'Select Category')] + [(c.id, c.name) for c in categories]
    
    if form.validate_on_submit():
        try:
            # Update income data
            income.amount = form.amount.data
            income.source = form.source.data
            income.description = form.description.data
            income.is_taxable = form.is_taxable.data
            income.tax_rate = form.tax_rate.data if form.is_taxable.data else None
            
            # Handle different forms
            if income.is_recurring:
                income.date = form.start_date.data
                income.recurring_type = form.recurring_type.data
                income.recurring_day = form.recurring_day.data
            else:
                income.date = form.date.data
                income.is_recurring = form.is_recurring.data
                income.recurring_type = form.recurring_type.data if form.is_recurring.data else None
                income.recurring_day = form.recurring_day.data if form.is_recurring.data else None
            
            # Handle category
            if form.category_id.data > 0:
                income.category_id = form.category_id.data
            else:
                income.category_id = None
            
            # Save changes
            db.session.commit()
            
            flash('Income updated successfully!', 'success')
            return redirect(url_for('income.index'))
        
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error updating income: {str(e)}")
            flash('An error occurred while updating the income. Please try again.', 'danger')
    
    return render_template('income/edit.html', form=form, income=income, title='Edit Income')

@income_routes.route('/delete/<int:id>', methods=['POST'])
@login_required
def delete(id):
    """Delete an income entry"""
    income = Income.query.filter_by(id=id, user_id=current_user.id).first_or_404()
    
    try:
        # Delete income from database
        db.session.delete(income)
        db.session.commit()
        
        flash('Income deleted successfully!', 'success')
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error deleting income: {str(e)}")
        flash('An error occurred while deleting the income.', 'danger')
    
    return redirect(url_for('income.index'))

@income_routes.route('/view/<int:id>')
@login_required
def view(id):
    """View income details"""
    income = Income.query.filter_by(id=id, user_id=current_user.id).first_or_404()
    return render_template('income/view.html', income=income, title='Income Details')

@income_routes.route('/bulk-action', methods=['POST'])
@login_required
def bulk_action():
    """Perform bulk actions on selected income entries"""
    form = IncomeBulkActionForm()
    
    # Get categories for the form dropdown
    categories = Category.query.filter_by(
        user_id=current_user.id,
        is_income=True,
        is_active=True
    ).order_by(Category.name).all()
    
    form.target_category_id.choices = [(c.id, c.name) for c in categories]
    
    if form.validate_on_submit():
        selected_ids = form.selected_incomes.data.split(',')
        action = form.action.data
        
        if not selected_ids:
            flash('No income entries selected.', 'warning')
            return redirect(url_for('income.index'))
        
        try:
            # Convert IDs to integers and filter by user_id for security
            income_ids = [int(id) for id in selected_ids if id]
            incomes = Income.query.filter(
                Income.id.in_(income_ids),
                Income.user_id == current_user.id
            ).all()
            
            if not incomes:
                flash('No valid income entries selected.', 'warning')
                return redirect(url_for('income.index'))
            
            if action == 'delete':
                # Delete income entries
                for income in incomes:
                    db.session.delete(income)
                
                db.session.commit()
                flash(f'{len(incomes)} income entries deleted successfully!', 'success')
                
            elif action == 'change_category':
                # Change category for all selected income entries
                target_category_id = form.target_category_id.data
                
                for income in incomes:
                    income.category_id = target_category_id
                
                db.session.commit()
                flash(f'Category updated for {len(incomes)} income entries!', 'success')
                
            elif action == 'export':
                # Export selected income entries as CSV
                return export_income_csv(incomes)
            
            else:
                flash('Invalid action selected.', 'warning')
        
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error in bulk action: {str(e)}")
            flash('An error occurred while processing the bulk action.', 'danger')
    
    return redirect(url_for('income.index'))

@income_routes.route('/export')
@login_required
def export():
    """Export all income entries as CSV"""
    # Get all income entries for the current user
    incomes = Income.query.filter_by(user_id=current_user.id).order_by(Income.date.desc()).all()
    return export_income_csv(incomes)

def export_income_csv(incomes):
    """Helper function to export income entries as CSV"""
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Write header row
    writer.writerow([
        'ID', 'Date', 'Source', 'Description', 'Amount', 'After-Tax Amount',
        'Category', 'Recurring', 'Taxable', 'Tax Rate (%)', 'Notes'
    ])
    
    # Write data rows
    for income in incomes:
        category_name = income.category.name if income.category else 'Uncategorized'
        
        writer.writerow([
            income.id,
            income.formatted_date,
            income.source,
            income.description or '',
            income.formatted_amount,
            "{:.2f}".format(income.after_tax_amount),
            category_name,
            'Yes' if income.is_recurring else 'No',
            'Yes' if income.is_taxable else 'No',
            income.tax_rate or '',
            ''  # Notes placeholder
        ])
    
    # Create response
    output.seek(0)
    return current_app.response_class(
        output.getvalue(),
        mimetype='text/csv',
        headers={'Content-Disposition': f'attachment;filename=income_{datetime.now().strftime("%Y%m%d")}.csv'}
    )

@income_routes.route('/stats')
@login_required
def stats():
    """View income statistics and trends"""
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
    
    # Get income breakdown by source
    source_breakdown = Income.get_total_by_source(current_user.id, start_date)
    
    # Get monthly income trend
    monthly_trend = Income.get_total_by_month(current_user.id)
    
    # Calculate average monthly income
    avg_monthly_income = Income.calculate_monthly_average(current_user.id)
    
    # Format data for charts
    source_data = []
    for source, total in source_breakdown:
        # Generate a distinct color for each source
        import hashlib
        hash_object = hashlib.md5(source.encode())
        hashed = hash_object.hexdigest()
        color = f'#{hashed[:6]}'
        
        source_data.append({
            'source': source,
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
        'income/stats.html',
        source_data=source_data,
        monthly_data=monthly_data,
        avg_monthly_income=avg_monthly_income,
        months=months,
        title='Income Statistics'
    )