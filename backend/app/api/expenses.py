from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.models import User, Expense, Category
from app.services.notifications import NotificationService
from datetime import datetime

@api_bp.route('/expenses', methods=['GET'])
@jwt_required()
def get_expenses():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    # Get query parameters for filtering
    category_id = request.args.get('category_id', type=int)
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    
    # Base query
    query = Expense.query.filter_by(user_id=user.id)
    
    # Apply filters if provided
    if category_id:
        query = query.filter_by(category_id=category_id)
    
    if start_date:
        try:
            start_date = datetime.strptime(start_date, '%Y-%m-%d')
            query = query.filter(Expense.date >= start_date)
        except ValueError:
            return jsonify({"msg": "Invalid start_date format. Use YYYY-MM-DD."}), 400
    
    if end_date:
        try:
            end_date = datetime.strptime(end_date, '%Y-%m-%d')
            query = query.filter(Expense.date <= end_date)
        except ValueError:
            return jsonify({"msg": "Invalid end_date format. Use YYYY-MM-DD."}), 400
    
    # Order by date, newest first
    expenses = query.order_by(Expense.date.desc()).all()
    
    return jsonify({
        "expenses": [expense.to_dict() for expense in expenses]
    }), 200

@api_bp.route('/expenses/<int:expense_id>', methods=['GET'])
@jwt_required()
def get_expense(expense_id):
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    expense = Expense.query.filter_by(id=expense_id, user_id=user.id).first()
    if not expense:
        return jsonify({"msg": "Expense not found"}), 404
    
    return jsonify(expense.to_dict()), 200

@api_bp.route('/expenses', methods=['POST'])
@jwt_required()
def create_expense():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    data = request.get_json()
    if not data:
        return jsonify({"msg": "Missing JSON in request"}), 400
    
    category_id = data.get('category_id')
    amount = data.get('amount')
    description = data.get('description', '')
    currency = data.get('currency', 'UZS')
    date_str = data.get('date')
    
    if not category_id or amount is None:
        return jsonify({"msg": "Category ID and amount are required"}), 400
    
    # Check if category exists and belongs to user
    category = Category.query.filter_by(id=category_id, user_id=user.id).first()
    if not category:
        return jsonify({"msg": "Category not found or doesn't belong to user"}), 404
    
    # Parse date if provided
    date = None
    if date_str:
        try:
            date = datetime.strptime(date_str, '%Y-%m-%d')
        except ValueError:
            return jsonify({"msg": "Invalid date format. Use YYYY-MM-DD."}), 400
    else:
        date = datetime.utcnow()
    
    new_expense = Expense(
        user_id=user.id,
        category_id=category_id,
        amount=amount,
        description=description,
        currency=currency,
        date=date
    )
    
    try:
        new_expense.save_to_db()
        
        # Check budget limits and create notifications
        from app.services.notifications import NotificationService
        new_notifications = NotificationService.check_budget_limits(user.id)
        
        return jsonify({
            "msg": "Expense created successfully",
            "expense": new_expense.to_dict(),
            "new_notifications": len(new_notifications)
        }), 201
    except Exception as e:
        return jsonify({"msg": f"Error creating expense: {str(e)}"}), 500

@api_bp.route('/expenses/<int:expense_id>', methods=['PUT'])
@jwt_required()
def update_expense(expense_id):
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    expense = Expense.query.filter_by(id=expense_id, user_id=user.id).first()
    if not expense:
        return jsonify({"msg": "Expense not found"}), 404
    
    data = request.get_json()
    if not data:
        return jsonify({"msg": "Missing JSON in request"}), 400
    
    category_id = data.get('category_id')
    amount = data.get('amount')
    description = data.get('description')
    currency = data.get('currency')
    date_str = data.get('date')
    
    if category_id:
        # Check if category exists and belongs to user
        category = Category.query.filter_by(id=category_id, user_id=user.id).first()
        if not category:
            return jsonify({"msg": "Category not found or doesn't belong to user"}), 404
        expense.category_id = category_id
    
    if amount is not None:
        expense.amount = amount
    
    if description is not None:
        expense.description = description
    
    if currency:
        expense.currency = currency
    
    if date_str:
        try:
            expense.date = datetime.strptime(date_str, '%Y-%m-%d')
        except ValueError:
            return jsonify({"msg": "Invalid date format. Use YYYY-MM-DD."}), 400
    
    try:
        expense.save_to_db()
        
        # Check budget limits and create notifications
        from app.services.notifications import NotificationService
        new_notifications = NotificationService.check_budget_limits(user.id)
        
        return jsonify({
            "msg": "Expense updated successfully",
            "expense": expense.to_dict(),
            "new_notifications": len(new_notifications)
        }), 200
    except Exception as e:
        return jsonify({"msg": f"Error updating expense: {str(e)}"}), 500
    
@api_bp.route('/expenses/<int:expense_id>', methods=['DELETE'])
@jwt_required()
def delete_expense(expense_id):
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    expense = Expense.query.filter_by(id=expense_id, user_id=user.id).first()
    if not expense:
        return jsonify({"msg": "Expense not found"}), 404
    
    try:
        expense.delete_from_db()
        return jsonify({"msg": "Expense deleted successfully"}), 200
    except Exception as e:
        return jsonify({"msg": f"Error deleting expense: {str(e)}"}), 500