from flask import request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app import db
from app.models.category import Category
from app.models.expense import Expense
from app.models.user import User
from app.utils.api import api_success, api_error
from app.utils.db import safe_commit
from app.utils.validation import validate_json, CATEGORY_SCHEMA
from sqlalchemy import func
from datetime import datetime
import logging

# Set up logging
logger = logging.getLogger(__name__)

@api_bp.route('/categories', methods=['GET'])
@jwt_required()
def get_categories():
    """
    Get categories for the current user
    
    Query parameters:
    - include_inactive: Whether to include inactive categories (default: false)
    - only_expense: Whether to only include expense categories (not income) (default: true)
    
    Returns:
        JSON response with a list of categories
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get query parameters
        include_inactive = request.args.get('include_inactive', 'false').lower() == 'true'
        only_expense = request.args.get('only_expense', 'true').lower() == 'true'
        
        # Get categories
        categories = Category.get_user_categories(
            user.id,
            include_inactive=include_inactive,
            only_expense=only_expense
        )
        
        # Format response
        categories_list = []
        for category in categories:
            current_spending = category.current_spending if hasattr(category, 'current_spending') else 0
            
            category_data = {
                'id': category.id,
                'name': category.name,
                'description': category.description,
                'color_code': category.color_code,
                'icon': category.icon,
                'budget_limit': float(category.budget_limit) if category.budget_limit else None,
                'budget_start_day': category.budget_start_day,
                'is_default': category.is_default,
                'is_active': category.is_active,
                'is_income': category.is_income,
                'created_at': category.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                'updated_at': category.updated_at.strftime('%Y-%m-%d %H:%M:%S')
            }
            
            # Add budget data if this is an expense category with a budget limit
            if not category.is_income and category.budget_limit:
                category_data.update({
                    'current_spending': current_spending,
                    'budget_percentage': category.budget_percentage,
                    'budget_status': category.budget_status
                })
            
            categories_list.append(category_data)
        
        return api_success({"categories": categories_list})
        
    except Exception as e:
        logger.error(f"Error getting categories: {str(e)}")
        return api_error("An error occurred while retrieving categories", 500)

@api_bp.route('/categories/<int:category_id>', methods=['GET'])
@jwt_required()
def get_category(category_id):
    """
    Get a specific category by ID
    
    Path parameters:
    - category_id: ID of the category to retrieve
    
    Returns:
        JSON response with category details
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get category
        category = Category.query.filter_by(id=category_id, user_id=user.id).first()
        
        if not category:
            return api_error("Category not found", 404)
        
        # Get total expenses for this category
        total_expenses = db.session.query(func.sum(Expense.amount)).filter_by(
            user_id=user.id,
            category_id=category.id
        ).scalar() or 0
        
        # Get expense count for this category
        expense_count = Expense.query.filter_by(
            user_id=user.id,
            category_id=category.id
        ).count()
        
        # Format response
        category_data = {
            'id': category.id,
            'name': category.name,
            'description': category.description,
            'color_code': category.color_code,
            'icon': category.icon,
            'budget_limit': float(category.budget_limit) if category.budget_limit else None,
            'budget_start_day': category.budget_start_day,
            'is_default': category.is_default,
            'is_active': category.is_active,
            'is_income': category.is_income,
            'created_at': category.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'updated_at': category.updated_at.strftime('%Y-%m-%d %H:%M:%S'),
            'stats': {
                'total_expenses': float(total_expenses),
                'expense_count': expense_count
            }
        }
        
        # Add budget data if this is an expense category with a budget limit
        if not category.is_income and category.budget_limit:
            category_data['stats'].update({
                'current_spending': category.current_spending,
                'budget_percentage': category.budget_percentage,
                'budget_status': category.budget_status
            })
        
        return api_success({"category": category_data})
        
    except Exception as e:
        logger.error(f"Error getting category {category_id}: {str(e)}")
        return api_error("An error occurred while retrieving the category", 500)

@api_bp.route('/categories', methods=['POST'])
@jwt_required()
@validate_json(CATEGORY_SCHEMA)
def create_category():
    """
    Create a new category
    
    Request body:
    - name: Category name (required)
    - description: Category description
    - color_code: Category color code (hex)
    - icon: Category icon name
    - budget_limit: Monthly budget limit
    - budget_start_day: Day of month when budget resets
    - is_income: Whether this is an income category
    - is_active: Whether this category is active
    
    Returns:
        JSON response with the created category
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get request data
        data = request.get_json()
        
        # Check if category name already exists for this user
        existing_category = Category.query.filter_by(
            user_id=user.id,
            name=data['name']
        ).first()
        
        if existing_category:
            return api_error("A category with this name already exists", 409)
        
        # Create category
        category = Category(
            user_id=user.id,
            name=data['name'],
            description=data.get('description'),
            color_code=data.get('color_code', '#757575'),
            icon=data.get('icon'),
            budget_limit=data.get('budget_limit'),
            budget_start_day=data.get('budget_start_day', 1),
            is_income=data.get('is_income', False),
            is_active=data.get('is_active', True),
            is_default=False
        )
        
        # Save to database
        db.session.add(category)
        success, error = safe_commit()
        
        if not success:
            return api_error(f"Database error: {error}", 500)
        
        # Format response
        category_data = {
            'id': category.id,
            'name': category.name,
            'description': category.description,
            'color_code': category.color_code,
            'icon': category.icon,
            'budget_limit': float(category.budget_limit) if category.budget_limit else None,
            'budget_start_day': category.budget_start_day,
            'is_default': category.is_default,
            'is_active': category.is_active,
            'is_income': category.is_income
        }
        
        return api_success({
            "message": "Category created successfully",
            "category": category_data
        }, code=201)
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error creating category: {str(e)}")
        return api_error("An error occurred while creating the category", 500)

@api_bp.route('/categories/<int:category_id>', methods=['PUT'])
@jwt_required()
def update_category(category_id):
    """
    Update an existing category
    
    Path parameters:
    - category_id: ID of the category to update
    
    Request body:
    - name: Category name
    - description: Category description
    - color_code: Category color code (hex)
    - icon: Category icon name
    - budget_limit: Monthly budget limit
    - budget_start_day: Day of month when budget resets
    - is_income: Whether this is an income category
    - is_active: Whether this category is active
    
    Returns:
        JSON response with the updated category
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get category
        category = Category.query.filter_by(id=category_id, user_id=user.id).first()
        
        if not category:
            return api_error("Category not found", 404)
        
        # Get request data
        data = request.get_json()
        
        if not data:
            return api_error("Missing JSON in request", 400)
        
        # Check if updating name and if it conflicts with existing categories
        if 'name' in data and data['name'] != category.name:
            existing_category = Category.query.filter(
                Category.user_id == user.id,
                Category.name == data['name'],
                Category.id != category_id
            ).first()
            
            if existing_category:
                return api_error("A category with this name already exists", 409)
            
            category.name = data['name']
        
        # Update other fields
        if 'description' in data:
            category.description = data['description']
        
        if 'color_code' in data:
            category.color_code = data['color_code']
        
        if 'icon' in data:
            category.icon = data['icon']
        
        if 'budget_limit' in data:
            category.budget_limit = data['budget_limit']
        
        if 'budget_start_day' in data:
            category.budget_start_day = data['budget_start_day']
        
        if 'is_income' in data:
            category.is_income = data['is_income']
        
        if 'is_active' in data:
            category.is_active = data['is_active']
        
        # Save to database
        success, error = safe_commit()
        
        if not success:
            return api_error(f"Database error: {error}", 500)
        
        # Format response
        category_data = {
            'id': category.id,
            'name': category.name,
            'description': category.description,
            'color_code': category.color_code,
            'icon': category.icon,
            'budget_limit': float(category.budget_limit) if category.budget_limit else None,
            'budget_start_day': category.budget_start_day,
            'is_default': category.is_default,
            'is_active': category.is_active,
            'is_income': category.is_income,
            'updated_at': category.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        return api_success({
            "message": "Category updated successfully",
            "category": category_data
        })
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error updating category {category_id}: {str(e)}")
        return api_error("An error occurred while updating the category", 500)

@api_bp.route('/categories/<int:category_id>', methods=['DELETE'])
@jwt_required()
def delete_category(category_id):
    """
    Delete a category
    
    Path parameters:
    - category_id: ID of the category to delete
    
    Query parameters:
    - force: Force deletion even if category has expenses (will set expenses to uncategorized)
    
    Returns:
        JSON response with success message
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get category
        category = Category.query.filter_by(id=category_id, user_id=user.id).first()
        
        if not category:
            return api_error("Category not found", 404)
        
        # Check if category is a default category
        if category.is_default:
            return api_error("Cannot delete default categories", 403)
        
        # Check if category has expenses
        expense_count = Expense.query.filter_by(
            user_id=user.id,
            category_id=category.id
        ).count()
        
        if expense_count > 0:
            # Check if force parameter is provided
            force = request.args.get('force', 'false').lower() == 'true'
            
            if not force:
                return api_error({
                    "error": "Category has expenses and cannot be deleted",
                    "expense_count": expense_count,
                    "message": "Use force=true query parameter to delete anyway and set expenses to uncategorized"
                }, 409)
            
            # Update expenses to uncategorized
            expenses = Expense.query.filter_by(
                user_id=user.id,
                category_id=category.id
            ).all()
            
            for expense in expenses:
                expense.category_id = None
        
        # Delete category
        db.session.delete(category)
        success, error = safe_commit()
        
        if not success:
            return api_error(f"Database error: {error}", 500)
        
        result = {
            "message": "Category deleted successfully"
        }
        
        if expense_count > 0:
            result["info"] = f"{expense_count} expenses were uncategorized"
        
        return api_success(result)
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error deleting category {category_id}: {str(e)}")
        return api_error("An error occurred while deleting the category", 500)

@api_bp.route('/categories/bulk', methods=['POST'])
@jwt_required()
def bulk_action_categories():
    """
    Perform bulk actions on categories
    
    Request body:
    - action: Action to perform (delete, activate, deactivate)
    - category_ids: List of category IDs to perform the action on
    - force: Force deletion even if categories have expenses (will set expenses to uncategorized)
    
    Returns:
        JSON response with success message
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get request data
        data = request.get_json()
        
        if not data:
            return api_error("Missing JSON in request", 400)
        
        # Validate required fields
        if 'action' not in data:
            return api_error("Action is required", 400)
        
        if 'category_ids' not in data or not data['category_ids']:
            return api_error("Category IDs are required", 400)
        
        action = data['action']
        category_ids = data['category_ids']
        
        # Validate category IDs
        try:
            category_ids = [int(id) for id in category_ids]
        except ValueError:
            return api_error("Invalid category ID format", 400)
        
        # Get categories
        categories = Category.query.filter(
            Category.id.in_(category_ids),
            Category.user_id == user.id
        ).all()
        
        if not categories:
            return api_error("No valid categories found", 404)
        
        # Perform action
        if action == 'delete':
            # Check for default categories
            default_categories = [c.name for c in categories if c.is_default]
            if default_categories:
                return api_error({
                    "error": "Cannot delete default categories",
                    "default_categories": default_categories
                }, 403)
            
            # Check if categories have expenses
            categories_with_expenses = []
            for category in categories:
                expense_count = Expense.query.filter_by(
                    user_id=user.id,
                    category_id=category.id
                ).count()
                
                if expense_count > 0:
                    categories_with_expenses.append({
                        "id": category.id,
                        "name": category.name,
                        "expense_count": expense_count
                    })
            
            if categories_with_expenses:
                # Check if force parameter is provided
                force = data.get('force', False)
                
                if not force:
                    return api_error({
                        "error": "Some categories have expenses and cannot be deleted",
                        "categories_with_expenses": categories_with_expenses,
                        "message": "Use force=true parameter to delete anyway and set expenses to uncategorized"
                    }, 409)
                
                # Update expenses to uncategorized
                for category_info in categories_with_expenses:
                    expenses = Expense.query.filter_by(
                        user_id=user.id,
                        category_id=category_info["id"]
                    ).all()
                    
                    for expense in expenses:
                        expense.category_id = None
            
            # Delete categories
            for category in categories:
                db.session.delete(category)
            
            success, error = safe_commit()
            
            if not success:
                return api_error(f"Database error: {error}", 500)
            
            result = {
                "message": f"{len(categories)} categories deleted successfully"
            }
            
            if categories_with_expenses:
                total_expenses = sum(c["expense_count"] for c in categories_with_expenses)
                result["info"] = f"{total_expenses} expenses were uncategorized"
            
            return api_success(result)
            
        elif action == 'activate':
            # Activate categories
            for category in categories:
                category.is_active = True
            
            success, error = safe_commit()
            
            if not success:
                return api_error(f"Database error: {error}", 500)
                
            return api_success({
                "message": f"{len(categories)} categories activated successfully"
            })
            
        elif action == 'deactivate':
            # Deactivate categories
            for category in categories:
                category.is_active = False
            
            success, error = safe_commit()
            
            if not success:
                return api_error(f"Database error: {error}", 500)
                
            return api_success({
                "message": f"{len(categories)} categories deactivated successfully"
            })
            
        else:
            return api_error(f"Invalid action: {action}", 400)
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error performing bulk action on categories: {str(e)}")
        return api_error("An error occurred while performing the bulk action", 500)

@api_bp.route('/categories/budgets', methods=['PUT'])
@jwt_required()
def update_category_budgets():
    """
    Update budgets for multiple categories at once
    
    Request body:
    - budgets: Dictionary with category IDs as keys and budget limits as values
    
    Returns:
        JSON response with updated categories
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get request data
        data = request.get_json()
        
        if not data:
            return api_error("Missing JSON in request", 400)
        
        # Validate required fields
        if 'budgets' not in data or not isinstance(data['budgets'], dict):
            return api_error("Budgets dictionary is required", 400)
        
        budgets = data['budgets']
        
        # Validate and parse category IDs
        category_ids = []
        for category_id in budgets.keys():
            try:
                category_ids.append(int(category_id))
            except ValueError:
                return api_error(f"Invalid category ID format: {category_id}", 400)
        
        # Get categories
        categories = Category.query.filter(
            Category.id.in_(category_ids),
            Category.user_id == user.id
        ).all()
        
        # Create a mapping of category IDs to categories for easier access
        category_map = {str(c.id): c for c in categories}
        
        # Update budgets
        updated_categories = []
        for category_id, budget_limit in budgets.items():
            category = category_map.get(str(category_id))
            
            if category:
                # Set budget limit
                if budget_limit is None or budget_limit == "":
                    category.budget_limit = None
                else:
                    try:
                        budget_limit = float(budget_limit)
                        if budget_limit < 0:
                            return api_error(f"Budget limit cannot be negative: {budget_limit}", 400)
                        category.budget_limit = budget_limit
                    except ValueError:
                        return api_error(f"Invalid budget limit format: {budget_limit}", 400)
                
                updated_categories.append({
                    'id': category.id,
                    'name': category.name,
                    'budget_limit': float(category.budget_limit) if category.budget_limit else None
                })
        
        # Save to database
        success, error = safe_commit()
        
        if not success:
            return api_error(f"Database error: {error}", 500)
        
        return api_success({
            "message": f"Updated budgets for {len(updated_categories)} categories",
            "categories": updated_categories
        })
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error updating category budgets: {str(e)}")
        return api_error("An error occurred while updating category budgets", 500)

@api_bp.route('/categories/<int:category_id>/expenses', methods=['GET'])
@jwt_required()
def get_category_expenses(category_id):
    """
    Get expenses for a specific category
    
    Path parameters:
    - category_id: ID of the category
    
    Query parameters:
    - page: Page number (default: 1)
    - per_page: Items per page (default: 10)
    - start_date: Filter by start date (YYYY-MM-DD)
    - end_date: Filter by end date (YYYY-MM-DD)
    - sort: Sort field (date, amount, description)
    - order: Sort order (asc, desc)
    
    Returns:
        JSON response with expenses for the category
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get category
        category = Category.query.filter_by(id=category_id, user_id=user.id).first()
        
        if not category:
            return api_error("Category not found", 404)
        
        # Get pagination parameters
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        
        # Build query
        query = Expense.query.filter_by(
            user_id=user.id,
            category_id=category_id
        )
        
        # Apply date filters
        start_date = request.args.get('start_date')
        if start_date:
            try:
                start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
                query = query.filter(Expense.date >= start_date)
            except ValueError:
                return api_error("Invalid start_date format. Use YYYY-MM-DD", 400)
                
        end_date = request.args.get('end_date')
        if end_date:
            try:
                end_date = datetime.strptime(end_date, '%Y-%m-%d').date()
                query = query.filter(Expense.date <= end_date)
            except ValueError:
                return api_error("Invalid end_date format. Use YYYY-MM-DD", 400)
        
        # Apply sorting
        sort = request.args.get('sort', 'date')
        order = request.args.get('order', 'desc')
        
        if sort == 'date':
            if order == 'asc':
                query = query.order_by(Expense.date.asc(), Expense.id.asc())
            else:
                query = query.order_by(Expense.date.desc(), Expense.id.desc())
        elif sort == 'amount':
            if order == 'asc':
                query = query.order_by(Expense.amount.asc())
            else:
                query = query.order_by(Expense.amount.desc())
        elif sort == 'description':
            if order == 'asc':
                query = query.order_by(Expense.description.asc())
            else:
                query = query.order_by(Expense.description.desc())
        else:
            # Default sorting
            query = query.order_by(Expense.date.desc(), Expense.id.desc())
        
        # Paginate results
        expenses_page = query.paginate(page=page, per_page=per_page, error_out=False)
        
        # Format expenses
        expenses = [{
            'id': expense.id,
            'amount': float(expense.amount),
            'formatted_amount': expense.formatted_amount,
            'description': expense.description,
            'date': expense.formatted_date,
            'payment_method': expense.payment_method,
            'location': expense.location,
            'is_recurring': expense.is_recurring,
            'notes': expense.notes
        } for expense in expenses_page.items]
        
        # Get category stats
        total_expenses = db.session.query(func.sum(Expense.amount)).filter_by(
            user_id=user.id,
            category_id=category_id
        ).scalar() or 0
        
        expense_count = Expense.query.filter_by(
            user_id=user.id,
            category_id=category_id
        ).count()
        
        # Format response
        result = {
            'category': {
                'id': category.id,
                'name': category.name,
                'color_code': category.color_code,
                'budget_limit': float(category.budget_limit) if category.budget_limit else None
            },
            'expenses': expenses,
            'stats': {
                'total_expenses': float(total_expenses),
                'expense_count': expense_count,
                'current_spending': category.current_spending if hasattr(category, 'current_spending') else 0,
                'budget_percentage': category.budget_percentage if category.budget_limit else 0
            },
            'pagination': {
                'page': expenses_page.page,
                'per_page': expenses_page.per_page,
                'total_pages': expenses_page.pages,
                'total_items': expenses_page.total
            }
        }
        
        return api_success(result)
        
    except Exception as e:
        logger.error(f"Error getting expenses for category {category_id}: {str(e)}")
        return api_error("An error occurred while retrieving category expenses", 500)

@api_bp.route('/categories/<int:category_id>/stats', methods=['GET'])
@jwt_required()
def get_category_stats(category_id):
    """
    Get detailed statistics for a specific category
    
    Path parameters:
    - category_id: ID of the category
    
    Query parameters:
    - period: Stats period (month, year, all) - default: month
    
    Returns:
        JSON response with category statistics
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get category
        category = Category.query.filter_by(id=category_id, user_id=user.id).first()
        
        if not category:
            return api_error("Category not found", 404)
        
        # Get period
        period = request.args.get('period', 'month')
        
        # Calculate date range
        today = datetime.now().date()
        
        if period == 'month':
            start_date = today.replace(day=1)
        elif period == 'year':
            start_date = today.replace(month=1, day=1)
        else:  # 'all'
            start_date = None
        
        # Get category data
        category_data = {
            'id': category.id,
            'name': category.name,
            'description': category.description,
            'color_code': category.color_code,
            'icon': category.icon,
            'budget_limit': float(category.budget_limit) if category.budget_limit else None,
            'is_income': category.is_income
        }
        
        # Get basic stats
        query = Expense.query.filter_by(
            user_id=user.id,
            category_id=category_id
        )
        
        if start_date:
            query = query.filter(Expense.date >= start_date)
        
        total_expenses = db.session.query(func.sum(Expense.amount)).filter(
            query.whereclause
        ).scalar() or 0
        
        expense_count = query.count()
        
        avg_expense = total_expenses / expense_count if expense_count > 0 else 0
        
        max_expense = db.session.query(func.max(Expense.amount)).filter(
            query.whereclause
        ).scalar() or 0
        
        # Get monthly trend
        monthly_trend = []
        if period == 'year' or period == 'all':
            # Group by month
            monthly_data = db.session.query(
                func.date_trunc('month', Expense.date).label('month'),
                func.sum(Expense.amount).label('total')
            ).filter(
                Expense.user_id == user.id,
                Expense.category_id == category_id
            )
            
            if start_date:
                monthly_data = monthly_data.filter(Expense.date >= start_date)
            
            monthly_data = monthly_data.group_by(
                func.date_trunc('month', Expense.date)
            ).order_by(
                func.date_trunc('month', Expense.date)
            ).all()
            
            # Format monthly data
            for month_date, total in monthly_data:
                if month_date:
                    monthly_trend.append({
                        'month': month_date.strftime('%b %Y'),
                        'total': float(total)
                    })
        
        # Get daily trend for month view
        daily_trend = []
        if period == 'month':
            # Group by day
            daily_data = db.session.query(
                func.extract('day', Expense.date).label('day'),
                func.sum(Expense.amount).label('total')
            ).filter(
                Expense.user_id == user.id,
                Expense.category_id == category_id,
                Expense.date >= start_date
            ).group_by(
                func.extract('day', Expense.date)
            ).order_by(
                func.extract('day', Expense.date)
            ).all()
            
            # Format daily data
            for day, total in daily_data:
                daily_trend.append({
                    'day': int(day),
                    'total': float(total)
                })
        
        # Format response
        stats = {
            'category': category_data,
            'period': period,
            'start_date': start_date.strftime('%Y-%m-%d') if start_date else None,
            'end_date': today.strftime('%Y-%m-%d'),
            'stats': {
                'total_expenses': float(total_expenses),
                'expense_count': expense_count,
                'average_expense': float(avg_expense),
                'max_expense': float(max_expense)
            }
        }
        
        # Add budget data if applicable
        if category.budget_limit:
            stats['stats'].update({
                'current_spending': category.current_spending,
                'budget_limit': float(category.budget_limit),
                'budget_percentage': category.budget_percentage,
                'budget_status': category.budget_status
            })
        
        # Add trend data based on period
        if period == 'month':
            stats['daily_trend'] = daily_trend
        else:
            stats['monthly_trend'] = monthly_trend
        
        return api_success(stats)
        
    except Exception as e:
        logger.error(f"Error getting stats for category {category_id}: {str(e)}")
        return api_error("An error occurred while retrieving category statistics", 500)

@api_bp.route('/categories/default', methods=['POST'])
@jwt_required()
def create_default_categories():
    """
    Create default categories for the current user
    
    Returns:
        JSON response with created categories
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Check if user already has categories
        existing_categories = Category.query.filter_by(user_id=user.id).count()
        
        if existing_categories > 0:
            return api_success({
                "message": "User already has categories",
                "count": existing_categories
            })
        
        # Create default categories
        categories = Category.get_or_create_default_categories(user.id)
        
        # Format response
        categories_list = [{
            'id': category.id,
            'name': category.name,
            'color_code': category.color_code,
            'is_default': category.is_default,
            'is_income': category.is_income
        } for category in categories]
        
        return api_success({
            "message": f"Created {len(categories)} default categories",
            "categories": categories_list
        }, code=201)
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error creating default categories: {str(e)}")
        return api_error("An error occurred while creating default categories", 500)