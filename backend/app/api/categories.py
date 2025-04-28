# backend/routes/categories.py

from flask import Blueprint, render_template, redirect, url_for, flash, request, jsonify
from flask_login import login_required, current_user
from app import db
from models.category import Category
from models.expense import Expense
from forms.categories import CategoryForm, CategoryBulkActionForm, CategoryBudgetForm
from sqlalchemy import func
import logging

# Set up logging
logger = logging.getLogger(__name__)

# Create a Blueprint for category routes
category_routes = Blueprint('categories', __name__, url_prefix='/categories')

@category_routes.route('/')
@login_required
def index():
    """Display list of categories"""
    # Get categories for the current user
    categories = Category.query.filter_by(user_id=current_user.id).order_by(Category.name).all()
    
    # Initialize bulk action form
    bulk_action_form = CategoryBulkActionForm()
    
    # Get expense counts and totals for each category
    category_stats = {}
    for category in categories:
        # Count expenses in this category
        expense_count = Expense.query.filter_by(
            user_id=current_user.id,
            category_id=category.id
        ).count()
        
        # Get total expenses for this category
        total_expenses = db.session.query(func.sum(Expense.amount)).filter_by(
            user_id=current_user.id,
            category_id=category.id
        ).scalar() or 0
        
        # Add to stats dictionary
        category_stats[category.id] = {
            'expense_count': expense_count,
            'total_expenses': float(total_expenses),
            'current_spending': category.current_spending,
            'budget_percentage': category.budget_percentage,
            'budget_status': category.budget_status
        }
    
    return render_template(
        'categories/index.html',
        categories=categories,
        category_stats=category_stats,
        bulk_action_form=bulk_action_form,
        title='Categories'
    )

@category_routes.route('/add', methods=['GET', 'POST'])
@login_required
def add():
    """Add a new category"""
    form = CategoryForm()
    
    if form.validate_on_submit():
        try:
            # Check if category name already exists for this user
            existing_category = Category.query.filter_by(
                user_id=current_user.id,
                name=form.name.data
            ).first()
            
            if existing_category:
                flash('A category with this name already exists.', 'danger')
                return render_template('categories/add.html', form=form, title='Add Category')
            
            # Create new category
            category = Category(
                user_id=current_user.id,
                name=form.name.data,
                description=form.description.data,
                color_code=form.color_code.data,
                icon=form.icon.data,
                budget_limit=form.budget_limit.data,
                budget_start_day=form.budget_start_day.data or 1,
                is_income=form.is_income.data,
                is_active=form.is_active.data
            )
            
            # Add to database
            db.session.add(category)
            db.session.commit()
            
            flash('Category added successfully!', 'success')
            return redirect(url_for('categories.index'))
        
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error adding category: {str(e)}")
            flash('An error occurred while adding the category. Please try again.', 'danger')
    
    return render_template('categories/add.html', form=form, title='Add Category')

@category_routes.route('/edit/<int:id>', methods=['GET', 'POST'])
@login_required
def edit(id):
    """Edit an existing category"""
    category = Category.query.filter_by(id=id, user_id=current_user.id).first_or_404()
    form = CategoryForm(obj=category)
    
    if form.validate_on_submit():
        try:
            # Check if new name conflicts with existing categories (excluding this one)
            existing_category = Category.query.filter(
                Category.user_id == current_user.id,
                Category.name == form.name.data,
                Category.id != id
            ).first()
            
            if existing_category:
                flash('A category with this name already exists.', 'danger')
                return render_template('categories/edit.html', form=form, category=category, title='Edit Category')
            
            # Update category data
            category.name = form.name.data
            category.description = form.description.data
            category.color_code = form.color_code.data
            category.icon = form.icon.data
            category.budget_limit = form.budget_limit.data
            category.budget_start_day = form.budget_start_day.data or 1
            category.is_income = form.is_income.data
            category.is_active = form.is_active.data
            
            # Save changes
            db.session.commit()
            
            flash('Category updated successfully!', 'success')
            return redirect(url_for('categories.index'))
        
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error updating category: {str(e)}")
            flash('An error occurred while updating the category. Please try again.', 'danger')
    
    return render_template('categories/edit.html', form=form, category=category, title='Edit Category')

@category_routes.route('/delete/<int:id>', methods=['POST'])
@login_required
def delete(id):
    """Delete a category"""
    category = Category.query.filter_by(id=id, user_id=current_user.id).first_or_404()
    
    # Check if category is in use
    expense_count = Expense.query.filter_by(
        user_id=current_user.id,
        category_id=category.id
    ).count()
    
    if expense_count > 0:
        flash(f'Cannot delete category "{category.name}" because it is used by {expense_count} expenses.', 'danger')
        return redirect(url_for('categories.index'))
    
    try:
        # Delete category
        db.session.delete(category)
        db.session.commit()
        
        flash('Category deleted successfully!', 'success')
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error deleting category: {str(e)}")
        flash('An error occurred while deleting the category.', 'danger')
    
    return redirect(url_for('categories.index'))

@category_routes.route('/bulk-action', methods=['POST'])
@login_required
def bulk_action():
    """Perform bulk actions on selected categories"""
    form = CategoryBulkActionForm()
    
    if form.validate_on_submit():
        selected_ids = form.selected_categories.data.split(',')
        action = form.action.data
        
        if not selected_ids:
            flash('No categories selected.', 'warning')
            return redirect(url_for('categories.index'))
        
        try:
            # Convert IDs to integers and filter by user_id for security
            category_ids = [int(id) for id in selected_ids if id]
            categories = Category.query.filter(
                Category.id.in_(category_ids),
                Category.user_id == current_user.id
            ).all()
            
            if not categories:
                flash('No valid categories selected.', 'warning')
                return redirect(url_for('categories.index'))
            
            if action == 'delete':
                # Check if any categories are in use
                in_use = []
                for category in categories:
                    expense_count = Expense.query.filter_by(
                        user_id=current_user.id,
                        category_id=category.id
                    ).count()
                    
                    if expense_count > 0:
                        in_use.append(category.name)
                
                if in_use:
                    flash(f'Cannot delete categories in use: {", ".join(in_use)}', 'danger')
                    return redirect(url_for('categories.index'))
                
                # Delete categories
                for category in categories:
                    db.session.delete(category)
                
                db.session.commit()
                flash(f'{len(categories)} categories deleted successfully!', 'success')
                
            elif action == 'activate':
                # Activate selected categories
                for category in categories:
                    category.is_active = True
                
                db.session.commit()
                flash(f'{len(categories)} categories activated!', 'success')
                
            elif action == 'deactivate':
                # Deactivate selected categories
                for category in categories:
                    category.is_active = False
                
                db.session.commit()
                flash(f'{len(categories)} categories deactivated!', 'success')
            
            else:
                flash('Invalid action selected.', 'warning')
        
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error in bulk action: {str(e)}")
            flash('An error occurred while processing the bulk action.', 'danger')
    
    return redirect(url_for('categories.index'))

@category_routes.route('/budgets', methods=['GET', 'POST'])
@login_required
def budgets():
    """Manage category budgets in one place"""
    # Get expense categories for the current user
    categories = Category.query.filter_by(
        user_id=current_user.id,
        is_active=True,
        is_income=False
    ).order_by(Category.name).all()
    
    # Create form with dynamic fields for each category
    form = CategoryBudgetForm(categories=categories)
    
    if form.validate_on_submit():
        try:
            # Update budgets
            for category in categories:
                field_name = f'budget_{category.id}'
                if hasattr(form, field_name):
                    field = getattr(form, field_name)
                    category.budget_limit = field.data
            
            db.session.commit()
            flash('Budget limits updated successfully!', 'success')
            return redirect(url_for('categories.index'))
        
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error updating budgets: {str(e)}")
            flash('An error occurred while updating budgets. Please try again.', 'danger')
    
    # Calculate current spending for each category
    category_stats = {}
    for category in categories:
        category_stats[category.id] = {
            'current_spending': category.current_spending,
            'budget_percentage': category.budget_percentage,
            'budget_status': category.budget_status
        }
    
    return render_template(
        'categories/budgets.html',
        form=form,
        categories=categories,
        category_stats=category_stats,
        title='Manage Budgets'
    )

@category_routes.route('/api/categories')
@login_required
def api_categories():
    """API endpoint to get categories for the current user"""
    # Get query parameters
    include_inactive = request.args.get('include_inactive', 'false').lower() == 'true'
    only_expense = request.args.get('only_expense', 'true').lower() == 'true'
    
    # Get categories
    categories = Category.get_user_categories(
        current_user.id,
        include_inactive=include_inactive,
        only_expense=only_expense
    )
    
    # Format response
    result = []
    for category in categories:
        result.append({
            'id': category.id,
            'name': category.name,
            'color': category.color_code,
            'icon': category.icon,
            'budget': float(category.budget_limit) if category.budget_limit else None,
            'is_active': category.is_active
        })
    
    return jsonify(result)

@category_routes.route('/view/<int:id>')
@login_required
def view(id):
    """View category details including expenses"""
    category = Category.query.filter_by(id=id, user_id=current_user.id).first_or_404()
    
    # Get expenses for this category
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    
    expenses = Expense.query.filter_by(
        user_id=current_user.id,
        category_id=category.id
    ).order_by(Expense.date.desc()).paginate(page=page, per_page=per_page, error_out=False)
    
    # Get stats for this category
    total_expenses = db.session.query(func.sum(Expense.amount)).filter_by(
        user_id=current_user.id,
        category_id=category.id
    ).scalar() or 0
    
    expense_count = Expense.query.filter_by(
        user_id=current_user.id,
        category_id=category.id
    ).count()
    
    # Get monthly trend for this category
    monthly_data = db.session.query(
        func.date_trunc('month', Expense.date).label('month'),
        func.sum(Expense.amount).label('total')
    ).filter_by(
        user_id=current_user.id,
        category_id=category.id
    ).group_by(
        func.date_trunc('month', Expense.date)
    ).order_by(
        func.date_trunc('month', Expense.date)
    ).all()
    
    # Format monthly data for chart
    trend_data = []
    for month_date, total in monthly_data:
        if month_date:
            month_str = month_date.strftime('%b %Y')
            trend_data.append({
                'month': month_str,
                'total': float(total)
            })
    
    stats = {
        'total_expenses': float(total_expenses),
        'expense_count': expense_count,
        'current_spending': category.current_spending,
        'budget_percentage': category.budget_percentage,
        'budget_status': category.budget_status
    }
    
    return render_template(
        'categories/view.html',
        category=category,
        expenses=expenses,
        stats=stats,
        trend_data=trend_data,
        title=f'Category: {category.name}'
    )