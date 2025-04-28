from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models.expense import Expense
from app.models.category import Category
from app.models.user import User
from datetime import datetime, timedelta
import logging

# Set up logger
logger = logging.getLogger(__name__)

# Create a blueprint for expense routes
expense_routes = Blueprint('expenses', __name__, url_prefix='/expenses')

@expense_routes.route('/', methods=['GET'])
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
                db.or_(
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

@expense_routes.route('/', methods=['POST'])
@jwt_required()
def add_expense():
    """
    Add a new expense
    
    Required fields:
    - amount: Expense amount
    - date: Expense date (YYYY-MM-DD)
    
    Optional fields:
    - description: Expense description
    - category_id: Category ID
    - payment_method: Payment method
    - location: Location
    - time: Time (HH:MM)
    - is_recurring: Whether the expense is recurring
    - recurring_type: Recurrence type (daily, weekly, monthly, yearly)
    - notes: Additional notes
    
    Returns:
        JSON response with the created expense
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return jsonify({"msg": "User not found"}), 404
        
        # Get request data
        data = request.get_json()
        
        if not data:
            return jsonify({"msg": "Missing JSON in request"}), 400
        
        # Validate required fields
        amount = data.get('amount')
        date_str = data.get('date')
        
        if not amount:
            return jsonify({"msg": "Amount is required"}), 400
        
        if not date_str:
            return jsonify({"msg": "Date is required"}), 400
        
        # Parse date
        try:
            expense_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return jsonify({"msg": "Invalid date format. Use YYYY-MM-DD"}), 400
        
        # Parse time if provided
        expense_time = None
        time_str = data.get('time')
        if time_str:
            try:
                expense_time = datetime.strptime(time_str, '%H:%M').time()
            except ValueError:
                return jsonify({"msg": "Invalid time format. Use HH:MM"}), 400
        
        # Validate category if provided
        category_id = data.get('category_id')
        if category_id:
            category = Category.query.filter_by(id=category_id, user_id=user.id).first()
            if not category:
                return jsonify({"msg": "Category not found"}), 404
        
        # Create new expense
        new_expense = Expense(
            user_id=user.id,
            amount=amount,
            description=data.get('description'),
            date=expense_date,
            time=expense_time,
            category_id=category_id,
            payment_method=data.get('payment_method'),
            location=data.get('location'),
            is_recurring=data.get('is_recurring', False),
            recurring_type=data.get('recurring_type'),
            notes=data.get('notes')
        )
        
        # Save to database
        new_expense.save_to_db()
        
        return jsonify({
            "msg": "Expense added successfully",
            "expense": {
                "id": new_expense.id,
                "amount": float(new_expense.amount),
                "formatted_amount": new_expense.formatted_amount,
                "description": new_expense.description,
                "date": new_expense.formatted_date
            }
        }), 201
        
    except Exception as e:
        logger.error(f"Error adding expense: {str(e)}")
        return jsonify({"msg": "An error occurred while adding the expense"}), 500

@expense_routes.route('/<int:expense_id>', methods=['GET'])
@jwt_required()
def get_expense(expense_id):
    """
    Get a specific expense by ID
    
    Args:
        expense_id: ID of the expense to retrieve
    
    Returns:
        JSON response with the expense details
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return jsonify({"msg": "User not found"}), 404
        
        # Get expense
        expense = Expense.query.filter_by(id=expense_id, user_id=user.id).first()
        
        if not expense:
            return jsonify({"msg": "Expense not found"}), 404
        
        # Format response
        result = {
            "id": expense.id,
            "amount": float(expense.amount),
            "formatted_amount": expense.formatted_amount,
            "description": expense.description,
            "date": expense.formatted_date,
            "time": expense.time.strftime('%H:%M') if expense.time else None,
            "category_id": expense.category_id,
            "category_name": expense.category.name if expense.category else "Uncategorized",
            "category_color": expense.category.color_code if expense.category else "#757575",
            "payment_method": expense.payment_method,
            "location": expense.location,
            "has_receipt": expense.has_receipt,
            "receipt_path": expense.receipt_path if expense.has_receipt else None,
            "is_recurring": expense.is_recurring,
            "recurring_type": expense.recurring_type,
            "notes": expense.notes,
            "created_at": expense.created_at.isoformat(),
            "updated_at": expense.updated_at.isoformat()
        }
        
        return jsonify(result), 200
        
    except Exception as e:
        logger.error(f"Error getting expense: {str(e)}")
        return jsonify({"msg": "An error occurred while retrieving the expense"}), 500

@expense_routes.route('/<int:expense_id>', methods=['PUT'])
@jwt_required()
def update_expense(expense_id):
    """
    Update an existing expense
    
    Args:
        expense_id: ID of the expense to update
    
    Returns:
        JSON response with the updated expense
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return jsonify({"msg": "User not found"}), 404
        
        # Get expense
        expense = Expense.query.filter_by(id=expense_id, user_id=user.id).first()
        
        if not expense:
            return jsonify({"msg": "Expense not found"}), 404
        
        # Get request data
        data = request.get_json()
        
        if not data:
            return jsonify({"msg": "Missing JSON in request"}), 400
        
        # Update fields if provided
        if 'amount' in data:
            expense.amount = data['amount']
        
        if 'description' in data:
            expense.description = data['description']
        
        if 'date' in data:
            try:
                expense.date = datetime.strptime(data['date'], '%Y-%m-%d').date()
            except ValueError:
                return jsonify({"msg": "Invalid date format. Use YYYY-MM-DD"}), 400
        
        if 'time' in data:
            if data['time']:
                try:
                    expense.time = datetime.strptime(data['time'], '%H:%M').time()
                except ValueError:
                    return jsonify({"msg": "Invalid time format. Use HH:MM"}), 400
            else:
                expense.time = None
        
        if 'category_id' in data:
            if data['category_id']:
                category = Category.query.filter_by(id=data['category_id'], user_id=user.id).first()
                if not category:
                    return jsonify({"msg": "Category not found"}), 404
                expense.category_id = data['category_id']
            else:
                expense.category_id = None
        
        if 'payment_method' in data:
            expense.payment_method = data['payment_method']
        
        if 'location' in data:
            expense.location = data['location']
        
        if 'is_recurring' in data:
            expense.is_recurring = data['is_recurring']
        
        if 'recurring_type' in data:
            expense.recurring_type = data['recurring_type']
        
        if 'notes' in data:
            expense.notes = data['notes']
        
        # Save changes
        db.session.commit()
        
        return jsonify({
            "msg": "Expense updated successfully",
            "expense": {
                "id": expense.id,
                "amount": float(expense.amount),
                "formatted_amount": expense.formatted_amount,
                "description": expense.description,
                "date": expense.formatted_date
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error updating expense: {str(e)}")
        return jsonify({"msg": "An error occurred while updating the expense"}), 500

@expense_routes.route('/<int:expense_id>', methods=['DELETE'])
@jwt_required()
def delete_expense(expense_id):
    """
    Delete an expense
    
    Args:
        expense_id: ID of the expense to delete
    
    Returns:
        JSON response with success message
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return jsonify({"msg": "User not found"}), 404
        
        # Get expense
        expense = Expense.query.filter_by(id=expense_id, user_id=user.id).first()
        
        if not expense:
            return jsonify({"msg": "Expense not found"}), 404
        
        # Delete expense
        expense.delete_from_db()
        
        return jsonify({"msg": "Expense deleted successfully"}), 200
        
    except Exception as e:
        logger.error(f"Error deleting expense: {str(e)}")
        return jsonify({"msg": "An error occurred while deleting the expense"}), 500

@expense_routes.route('/stats', methods=['GET'])
@jwt_required()
def get_expense_stats():
    """
    Get expense statistics and summaries
    
    Query parameters:
    - period: Stats period (today, week, month, year, all) (default: month)
    - start_date: Custom start date for stats (YYYY-MM-DD)
    - end_date: Custom end date for stats (YYYY-MM-DD)
    
    Returns:
        JSON response with expense statistics
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return jsonify({"msg": "User not found"}), 404
        
        # Get period parameter
        period = request.args.get('period', 'month')
        
        # Calculate date range based on period
        end_date = datetime.utcnow().date()
        
        if period == 'today':
            start_date = end_date
        elif period == 'week':
            start_date = end_date - timedelta(days=end_date.weekday())
        elif period == 'month':
            start_date = end_date.replace(day=1)
        elif period == 'year':
            start_date = end_date.replace(month=1, day=1)
        elif period == 'all':
            start_date = datetime(2000, 1, 1).date()  # Far past date
        elif period == 'custom':
            # Get custom date range
            start_date_str = request.args.get('start_date')
            end_date_str = request.args.get('end_date')
            
            if not start_date_str or not end_date_str:
                return jsonify({"msg": "start_date and end_date are required for custom period"}), 400
            
            try:
                start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
                end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
            except ValueError:
                return jsonify({"msg": "Invalid date format. Use YYYY-MM-DD"}), 400
        else:
            return jsonify({"msg": "Invalid period parameter"}), 400
        
        # Get total expenses for the period
        total_query = db.session.query(db.func.sum(Expense.amount)).filter(
            Expense.user_id == user.id,
            Expense.date >= start_date,
            Expense.date <= end_date
        )
        
        total_expenses = total_query.scalar() or 0
        
        # Get expenses by category
        category_expenses = Expense.get_total_by_category(
            user_id=user.id,
            start_date=start_date,
            end_date=end_date
        )
        
        # Format category data
        categories_data = []
        for category_id, category_name, category_total in category_expenses:
            # Get category color
            color = "#757575"  # Default color
            if category_id:
                category = Category.query.get(category_id)
                if category:
                    color = category.color_code
            
            categories_data.append({
                "id": category_id,
                "name": category_name or "Uncategorized",
                "total": float(category_total),
                "percentage": round((float(category_total) / float(total_expenses)) * 100, 2) if total_expenses > 0 else 0,
                "color": color
            })
        
        # Get expenses by payment method
        payment_methods_query = db.session.query(
            Expense.payment_method,
            db.func.sum(Expense.amount).label('total')
        ).filter(
            Expense.user_id == user.id,
            Expense.date >= start_date,
            Expense.date <= end_date
        ).group_by(
            Expense.payment_method
        )
        
        payment_methods_data = []
        for payment_method, method_total in payment_methods_query:
            payment_methods_data.append({
                "method": payment_method or "Not specified",
                "total": float(method_total),
                "percentage": round((float(method_total) / float(total_expenses)) * 100, 2) if total_expenses > 0 else 0
            })
        
        # Prepare stats response
        stats = {
            "period": period,
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
            "total_expenses": float(total_expenses),
            "categories": categories_data,
            "payment_methods": payment_methods_data
        }
        
        return jsonify(stats), 200
        
    except Exception as e:
        logger.error(f"Error getting expense stats: {str(e)}")
        return jsonify({"msg": "An error occurred while retrieving expense statistics"}), 500