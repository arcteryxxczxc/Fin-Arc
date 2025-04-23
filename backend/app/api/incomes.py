from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.models import User, Income
from datetime import datetime

@api_bp.route('/incomes', methods=['GET'])
@jwt_required()
def get_incomes():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    # Get query parameters for filtering
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    
    # Base query
    query = Income.query.filter_by(user_id=user.id)
    
    # Apply filters if provided
    if start_date:
        try:
            start_date = datetime.strptime(start_date, '%Y-%m-%d')
            query = query.filter(Income.date >= start_date)
        except ValueError:
            return jsonify({"msg": "Invalid start_date format. Use YYYY-MM-DD."}), 400
    
    if end_date:
        try:
            end_date = datetime.strptime(end_date, '%Y-%m-%d')
            query = query.filter(Income.date <= end_date)
        except ValueError:
            return jsonify({"msg": "Invalid end_date format. Use YYYY-MM-DD."}), 400
    
    # Order by date, newest first
    incomes = query.order_by(Income.date.desc()).all()
    
    return jsonify({
        "incomes": [income.to_dict() for income in incomes]
    }), 200

@api_bp.route('/incomes', methods=['POST'])
@jwt_required()
def create_income():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    data = request.get_json()
    if not data:
        return jsonify({"msg": "Missing JSON in request"}), 400
    
    source = data.get('source')
    amount = data.get('amount')
    currency = data.get('currency', 'UZS')
    date_str = data.get('date')
    
    if not source or amount is None:
        return jsonify({"msg": "Source and amount are required"}), 400
    
    # Parse date if provided
    date = None
    if date_str:
        try:
            date = datetime.strptime(date_str, '%Y-%m-%d')
        except ValueError:
            return jsonify({"msg": "Invalid date format. Use YYYY-MM-DD."}), 400
    else:
        date = datetime.utcnow()
    
    new_income = Income(
        user_id=user.id,
        source=source,
        amount=amount,
        currency=currency,
        date=date
    )
    
    try:
        new_income.save_to_db()
        return jsonify({
            "msg": "Income created successfully",
            "income": new_income.to_dict()
        }), 201
    except Exception as e:
        return jsonify({"msg": f"Error creating income: {str(e)}"}), 500

@api_bp.route('/incomes/<int:income_id>', methods=['GET'])
@jwt_required()
def get_income(income_id):
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    income = Income.query.filter_by(id=income_id, user_id=user.id).first()
    if not income:
        return jsonify({"msg": "Income not found"}), 404
    
    return jsonify(income.to_dict()), 200

@api_bp.route('/incomes/<int:income_id>', methods=['PUT'])
@jwt_required()
def update_income(income_id):
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    income = Income.query.filter_by(id=income_id, user_id=user.id).first()
    if not income:
        return jsonify({"msg": "Income not found"}), 404
    
    data = request.get_json()
    if not data:
        return jsonify({"msg": "Missing JSON in request"}), 400
    
    source = data.get('source')
    amount = data.get('amount')
    currency = data.get('currency')
    date_str = data.get('date')
    
    if source:
        income.source = source
    
    if amount is not None:
        income.amount = amount
    
    if currency:
        income.currency = currency
    
    if date_str:
        try:
            income.date = datetime.strptime(date_str, '%Y-%m-%d')
        except ValueError:
            return jsonify({"msg": "Invalid date format. Use YYYY-MM-DD."}), 400
    
    try:
        income.save_to_db()
        return jsonify({
            "msg": "Income updated successfully",
            "income": income.to_dict()
        }), 200
    except Exception as e:
        return jsonify({"msg": f"Error updating income: {str(e)}"}), 500

@api_bp.route('/incomes/<int:income_id>', methods=['DELETE'])
@jwt_required()
def delete_income(income_id):
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    income = Income.query.filter_by(id=income_id, user_id=user.id).first()
    if not income:
        return jsonify({"msg": "Income not found"}), 404
    
    try:
        income.delete_from_db()
        return jsonify({"msg": "Income deleted successfully"}), 200
    except Exception as e:
        return jsonify({"msg": f"Error deleting income: {str(e)}"}), 500