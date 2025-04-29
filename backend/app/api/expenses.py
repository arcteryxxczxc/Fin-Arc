from flask import request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app import db
from app.models.expense import Expense
from app.models.category import Category
from app.models.user import User
from app.utils.api import api_success, api_error
from app.utils.db import safe_commit, paginate_query
from app.utils.validation import validate_json, EXPENSE_SCHEMA
from sqlalchemy import or_, func
from datetime import datetime
import csv
import io
import logging

# Set up logger
logger = logging.getLogger(__name__)

@api_bp.route('/expenses', methods=['GET'])
@jwt_required()
def get_expenses():
    """
    Get a list of expenses for the current user
    
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
            return api_error("User not found", 404)
        
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
            try:
                query = query.filter(Expense.date >= datetime.strptime(start_date, '%Y-%m-%d').date())
            except ValueError:
                return api_error("Invalid start_date format. Use YYYY-MM-DD", 400)
        
        end_date = request.args.get('end_date')
        if end_date:
            try:
                query = query.filter(Expense.date <= datetime.strptime(end_date, '%Y-%m-%d').date())
            except ValueError:
                return api_error("Invalid end_date format. Use YYYY-MM-DD", 400)
        
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
        expenses_page = paginate_query(query, page, per_page)
        
        # Format response
        expenses = [{
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
        } for expense in expenses_page.items]
        
        return api_success({
            "expenses": expenses,
            "pagination": {
                "page": expenses_page.page,
                "per_page": expenses_page.per_page,
                "total_pages": expenses_page.pages,
                "total_items": expenses_page.total
            }
        })
        
    except Exception as e:
        logger.error(f"Error getting expenses: {str(e)}")
        return api_error("An error occurred while retrieving expenses", 500)

@api_bp.route('/expenses/<int:expense_id>', methods=['GET'])
@jwt_required()
def get_expense(expense_id):
    """
    Get a specific expense by ID
    
    Path parameters:
    - expense_id: ID of the expense to retrieve
    
    Returns:
        JSON response with expense details
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get expense
        expense = Expense.query.filter_by(id=expense_id, user_id=user.id).first()
        
        if not expense:
            return api_error("Expense not found", 404)
        
        # Format response
        expense_data = {
            "id": expense.id,
            "amount": float(expense.amount),
            "formatted_amount": expense.formatted_amount,
            "description": expense.description,
            "date": expense.formatted_date,
            "time": expense.time.strftime('%H:%M') if expense.time else None,
            "category_id": expense.category_id,
            "category_name": expense.category.name if expense.category else "Uncategorized",
            "payment_method": expense.payment_method,
            "location": expense.location,
            "has_receipt": expense.has_receipt,
            "receipt_path": expense.receipt_path,
            "is_recurring": expense.is_recurring,
            "recurring_type": expense.recurring_type,
            "notes": expense.notes,
            "created_at": expense.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            "updated_at": expense.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        return api_success({"expense": expense_data})
        
    except Exception as e:
        logger.error(f"Error getting expense {expense_id}: {str(e)}")
        return api_error("An error occurred while retrieving the expense", 500)

@api_bp.route('/expenses', methods=['POST'])
@jwt_required()
@validate_json(EXPENSE_SCHEMA)
def create_expense():
    """
    Create a new expense
    
    Request body:
    - amount: Expense amount (required)
    - description: Expense description
    - date: Expense date (YYYY-MM-DD)
    - time: Expense time (HH:MM)
    - category_id: Category ID
    - payment_method: Payment method
    - location: Location
    - is_recurring: Whether the expense is recurring
    - recurring_type: Type of recurrence (daily, weekly, monthly, yearly)
    - notes: Additional notes
    
    Returns:
        JSON response with the created expense
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get validated request data
        data = request.get_json()
        
        # Parse date
        date_val = datetime.utcnow().date()
        if 'date' in data and data['date']:
            try:
                date_val = datetime.strptime(data['date'], '%Y-%m-%d').date()
            except ValueError:
                return api_error("Invalid date format. Use YYYY-MM-DD", 400)
        
        # Parse time
        time_val = None
        if 'time' in data and data['time']:
            try:
                time_val = datetime.strptime(data['time'], '%H:%M').time()
            except ValueError:
                return api_error("Invalid time format. Use HH:MM", 400)
        
        # Create expense
        expense = Expense(
            user_id=user.id,
            amount=data['amount'],
            description=data.get('description'),
            date=date_val,
            time=time_val,
            payment_method=data.get('payment_method'),
            location=data.get('location'),
            is_recurring=data.get('is_recurring', False),
            recurring_type=data.get('recurring_type') if data.get('is_recurring', False) else None,
            notes=data.get('notes')
        )
        
        # Handle category
        category_id = data.get('category_id')
        if category_id:
            category = Category.query.filter_by(id=category_id, user_id=user.id).first()
            if category:
                expense.category_id = category.id
        
        # Save to database
        db.session.add(expense)
        success, error = safe_commit()
        
        if not success:
            return api_error(f"Database error: {error}", 500)
        
        # Format response
        expense_data = {
            "id": expense.id,
            "amount": float(expense.amount),
            "formatted_amount": expense.formatted_amount,
            "description": expense.description,
            "date": expense.formatted_date,
            "category_id": expense.category_id,
            "category_name": expense.category.name if expense.category else "Uncategorized",
            "payment_method": expense.payment_method,
            "location": expense.location,
            "is_recurring": expense.is_recurring,
            "recurring_type": expense.recurring_type,
            "notes": expense.notes
        }
        
        return api_success({
            "message": "Expense created successfully",
            "expense": expense_data
        }, code=201)
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error creating expense: {str(e)}")
        return api_error("An error occurred while creating the expense", 500)

@api_bp.route('/expenses/<int:expense_id>', methods=['PUT'])
@jwt_required()
def update_expense(expense_id):
    """
    Update an existing expense
    
    Path parameters:
    - expense_id: ID of the expense to update
    
    Request body:
    - amount: Expense amount
    - description: Expense description
    - date: Expense date (YYYY-MM-DD)
    - time: Expense time (HH:MM)
    - category_id: Category ID
    - payment_method: Payment method
    - location: Location
    - is_recurring: Whether the expense is recurring
    - recurring_type: Type of recurrence (daily, weekly, monthly, yearly)
    - notes: Additional notes
    
    Returns:
        JSON response with the updated expense
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get expense
        expense = Expense.query.filter_by(id=expense_id, user_id=user.id).first()
        
        if not expense:
            return api_error("Expense not found", 404)
        
        # Get request data
        data = request.get_json()
        
        if not data:
            return api_error("Missing JSON in request", 400)
        
        # Update expense
        if 'amount' in data:
            try:
                amount = float(data['amount'])
                if amount <= 0:
                    return api_error("Amount must be greater than zero", 400)
                expense.amount = amount
            except ValueError:
                return api_error("Invalid amount format", 400)
        
        # Update description
        if 'description' in data:
            expense.description = data['description']
        
        # Update date
        if 'date' in data:
            try:
                expense.date = datetime.strptime(data['date'], '%Y-%m-%d').date()
            except ValueError:
                return api_error("Invalid date format. Use YYYY-MM-DD", 400)
        
        # Update time
        if 'time' in data:
            if data['time']:
                try:
                    expense.time = datetime.strptime(data['time'], '%H:%M').time()
                except ValueError:
                    return api_error("Invalid time format. Use HH:MM", 400)
            else:
                expense.time = None
        
        # Update category
        if 'category_id' in data:
            category_id = data['category_id']
            if category_id:
                category = Category.query.filter_by(id=category_id, user_id=user.id).first()
                if category:
                    expense.category_id = category.id
                else:
                    return api_error("Category not found", 404)
            else:
                expense.category_id = None
        
        # Update other fields
        if 'payment_method' in data:
            expense.payment_method = data['payment_method']
        
        if 'location' in data:
            expense.location = data['location']
        
        if 'is_recurring' in data:
            expense.is_recurring = data['is_recurring']
            
            # Update recurring_type if is_recurring is True
            if 'recurring_type' in data and expense.is_recurring:
                expense.recurring_type = data['recurring_type']
            # Clear recurring_type if is_recurring is False
            elif not expense.is_recurring:
                expense.recurring_type = None
        
        if 'notes' in data:
            expense.notes = data['notes']
        
        # Save to database
        success, error = safe_commit()
        
        if not success:
            return api_error(f"Database error: {error}", 500)
        
        # Format response
        expense_data = {
            "id": expense.id,
            "amount": float(expense.amount),
            "formatted_amount": expense.formatted_amount,
            "description": expense.description,
            "date": expense.formatted_date,
            "time": expense.time.strftime('%H:%M') if expense.time else None,
            "category_id": expense.category_id,
            "category_name": expense.category.name if expense.category else "Uncategorized",
            "payment_method": expense.payment_method,
            "location": expense.location,
            "is_recurring": expense.is_recurring,
            "recurring_type": expense.recurring_type,
            "notes": expense.notes,
            "updated_at": expense.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        return api_success({
            "message": "Expense updated successfully",
            "expense": expense_data
        })
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error updating expense {expense_id}: {str(e)}")
        return api_error("An error occurred while updating the expense", 500)

@api_bp.route('/expenses/<int:expense_id>', methods=['DELETE'])
@jwt_required()
def delete_expense(expense_id):
    """
    Delete an expense
    
    Path parameters:
    - expense_id: ID of the expense to delete
    
    Returns:
        JSON response with success message
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get expense
        expense = Expense.query.filter_by(id=expense_id, user_id=user.id).first()
        
        if not expense:
            return api_error("Expense not found", 404)
        
        # Delete expense
        db.session.delete(expense)
        success, error = safe_commit()
        
        if not success:
            return api_error(f"Database error: {error}", 500)
        
        return api_success(message="Expense deleted successfully")
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error deleting expense {expense_id}: {str(e)}")
        return api_error("An error occurred while deleting the expense", 500)

@api_bp.route('/expenses/bulk', methods=['POST'])
@jwt_required()
def bulk_action_expenses():
    """
    Perform bulk actions on expenses
    
    Request body:
    - action: Action to perform (delete, change_category)
    - expense_ids: List of expense IDs to perform the action on
    - target_category_id: Target category ID (for change_category action)
    
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
        
        if 'expense_ids' not in data or not data['expense_ids']:
            return api_error("Expense IDs are required", 400)
        
        action = data['action']
        expense_ids = data['expense_ids']
        
        # Validate expense IDs
        try:
            expense_ids = [int(id) for id in expense_ids]
        except ValueError:
            return api_error("Invalid expense ID format", 400)
        
        # Get expenses
        expenses = Expense.query.filter(
            Expense.id.in_(expense_ids),
            Expense.user_id == user.id
        ).all()
        
        if not expenses:
            return api_error("No valid expenses found", 404)
        
        # Perform action
        if action == 'delete':
            # Delete expenses
            for expense in expenses:
                db.session.delete(expense)
            
            success, error = safe_commit()
            
            if not success:
                return api_error(f"Database error: {error}", 500)
                
            return api_success({
                "message": f"{len(expenses)} expenses deleted successfully"
            })
            
        elif action == 'change_category':
            # Validate target category ID
            if 'target_category_id' not in data:
                return api_error("Target category ID is required for change_category action", 400)
            
            target_category_id = data['target_category_id']
            
            # Validate category
            if target_category_id:
                category = Category.query.filter_by(id=target_category_id, user_id=user.id).first()
                if not category:
                    return api_error("Target category not found", 404)
            
            # Update category
            for expense in expenses:
                expense.category_id = target_category_id
            
            success, error = safe_commit()
            
            if not success:
                return api_error(f"Database error: {error}", 500)
                
            return api_success({
                "message": f"Category updated for {len(expenses)} expenses"
            })
            
        else:
            return api_error(f"Invalid action: {action}", 400)
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error performing bulk action on expenses: {str(e)}")
        return api_error("An error occurred while performing the bulk action", 500)

@api_bp.route('/expenses/export', methods=['GET'])
@jwt_required()
def export_expenses():
    """
    Export expenses as CSV
    
    Query parameters:
    - ids: Comma-separated list of expense IDs to export (optional)
    - all other filter parameters from get_expenses
    
    Returns:
        CSV file with expenses
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Check if specific IDs are provided
        ids_param = request.args.get('ids')
        if ids_param:
            try:
                expense_ids = [int(id) for id in ids_param.split(',')]
                expenses = Expense.query.filter(
                    Expense.id.in_(expense_ids),
                    Expense.user_id == user.id
                ).order_by(Expense.date.desc()).all()
            except ValueError:
                return api_error("Invalid expense ID format", 400)
        else:
            # Build query using the same filters as get_expenses
            query = Expense.query.filter_by(user_id=user.id)
            
            # Apply filters
            category_id = request.args.get('category_id', type=int)
            if category_id:
                query = query.filter(Expense.category_id == category_id)
            
            start_date = request.args.get('start_date')
            if start_date:
                try:
                    query = query.filter(Expense.date >= datetime.strptime(start_date, '%Y-%m-%d').date())
                except ValueError:
                    return api_error("Invalid start_date format. Use YYYY-MM-DD", 400)
            
            end_date = request.args.get('end_date')
            if end_date:
                try:
                    query = query.filter(Expense.date <= datetime.strptime(end_date, '%Y-%m-%d').date())
                except ValueError:
                    return api_error("Invalid end_date format. Use YYYY-MM-DD", 400)
            
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
            
            # Get all matching expenses
            expenses = query.order_by(Expense.date.desc()).all()
        
        if not expenses:
            return api_error("No expenses found matching the criteria", 404)
        
        # Create CSV
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
        
        # Prepare response
        output.seek(0)
        
        # Return CSV file
        return {
            "content": output.getvalue(),
            "status": 200,
            "mimetype": "text/csv",
            "headers": {
                "Content-Disposition": f"attachment;filename=expenses_{datetime.now().strftime('%Y%m%d')}.csv"
            }
        }
        
    except Exception as e:
        logger.error(f"Error exporting expenses: {str(e)}")
        return api_error("An error occurred while exporting expenses", 500)

@api_bp.route('/expenses/stats', methods=['GET'])
@jwt_required()
def get_expense_stats():
    """
    Get expense statistics
    
    Query parameters:
    - period: Stats period (month, year, all) - default: month
    - category_id: Filter by category ID
    
    Returns:
        JSON response with expense statistics
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
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
        
        # Get category filter
        category_id = request.args.get('category_id', type=int)
        
        # Build query
        query = Expense.query.filter_by(user_id=user.id)
        
        if start_date:
            query = query.filter(Expense.date >= start_date)
        
        if category_id:
            query = query.filter(Expense.category_id == category_id)
        
        # Get total expenses
        total_expenses = db.session.query(func.sum(Expense.amount)).filter(
            query.whereclause
        ).scalar() or 0
        
        # Get expense count
        expense_count = query.count()
        
        # Get average expense
        avg_expense = total_expenses / expense_count if expense_count > 0 else 0
        
        # Get max expense
        max_expense = db.session.query(func.max(Expense.amount)).filter(
            query.whereclause
        ).scalar() or 0
        
        # Get expense by category
        category_expenses = db.session.query(
            Category.id,
            Category.name,
            Category.color_code,
            func.sum(Expense.amount).label('total')
        ).outerjoin(
            Expense, Expense.category_id == Category.id
        ).filter(
            Expense.user_id == user.id
        )
        
        if start_date:
            category_expenses = category_expenses.filter(Expense.date >= start_date)
        
        category_expenses = category_expenses.group_by(
            Category.id, Category.name, Category.color_code
        ).order_by(
            func.sum(Expense.amount).desc()
        ).all()
        
        # Format category expenses
        categories = []
        for cat_id, cat_name, cat_color, cat_total in category_expenses:
            if cat_total:
                categories.append({
                    'id': cat_id,
                    'name': cat_name or 'Uncategorized',
                    'color': cat_color or '#757575',
                    'total': float(cat_total),
                    'percentage': (float(cat_total) / float(total_expenses) * 100) if total_expenses > 0 else 0
                })
        
        # Get expenses by day for month view
        daily_expenses = []
        if period == 'month':
            # Group by day of month
            daily_data = db.session.query(
                func.extract('day', Expense.date).label('day'),
                func.sum(Expense.amount).label('total')
            ).filter(
                Expense.user_id == user.id,
                Expense.date >= start_date
            )
            
            if category_id:
                daily_data = daily_data.filter(Expense.category_id == category_id)
            
            daily_data = daily_data.group_by(
                func.extract('day', Expense.date)
            ).order_by(
                func.extract('day', Expense.date)
            ).all()
            
            # Format daily expenses
            for day, total in daily_data:
                daily_expenses.append({
                    'day': int(day),
                    'total': float(total)
                })
        
        # Format response
        stats_data = {
            'period': period,
            'start_date': start_date.strftime('%Y-%m-%d') if start_date else None,
            'end_date': today.strftime('%Y-%m-%d'),
            'total_expenses': float(total_expenses),
            'expense_count': expense_count,
            'average_expense': float(avg_expense),
            'max_expense': float(max_expense),
            'categories': categories
        }
        
        if period == 'month':
            stats_data['daily_expenses'] = daily_expenses
        
        return api_success(stats_data)
        
    except Exception as e:
        logger.error(f"Error getting expense stats: {str(e)}")
        return api_error("An error occurred while getting expense statistics", 500)