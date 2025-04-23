from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app.models import User, Category

@api_bp.route('/categories', methods=['GET'])
@jwt_required()
def get_categories():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    categories = Category.query.filter_by(user_id=user.id).all()
    return jsonify({
        "categories": [category.to_dict() for category in categories]
    }), 200

@api_bp.route('/categories', methods=['POST'])
@jwt_required()
def create_category():
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    data = request.get_json()
    if not data:
        return jsonify({"msg": "Missing JSON in request"}), 400
    
    name = data.get('name', '')
    budget_limit = data.get('budget_limit')
    color_code = data.get('color_code', '#000000')
    
    if not name:
        return jsonify({"msg": "Category name is required"}), 400
    
    # Check if category with same name already exists for this user
    if Category.query.filter_by(user_id=user.id, name=name).first():
        return jsonify({"msg": "Category with this name already exists"}), 409
    
    new_category = Category(
        user_id=user.id,
        name=name,
        budget_limit=budget_limit,
        color_code=color_code
    )
    
    try:
        new_category.save_to_db()
        return jsonify({
            "msg": "Category created successfully",
            "category": new_category.to_dict()
        }), 201
    except Exception as e:
        return jsonify({"msg": f"Error creating category: {str(e)}"}), 500

@api_bp.route('/categories/<int:category_id>', methods=['GET'])
@jwt_required()
def get_category(category_id):
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    category = Category.query.filter_by(id=category_id, user_id=user.id).first()
    if not category:
        return jsonify({"msg": "Category not found"}), 404
    
    return jsonify(category.to_dict()), 200

@api_bp.route('/categories/<int:category_id>', methods=['PUT'])
@jwt_required()
def update_category(category_id):
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    category = Category.query.filter_by(id=category_id, user_id=user.id).first()
    if not category:
        return jsonify({"msg": "Category not found"}), 404
    
    data = request.get_json()
    if not data:
        return jsonify({"msg": "Missing JSON in request"}), 400
    
    name = data.get('name')
    budget_limit = data.get('budget_limit')
    color_code = data.get('color_code')
    
    if name:
        # Check if another category with same name already exists for this user
        existing = Category.query.filter_by(user_id=user.id, name=name).first()
        if existing and existing.id != category_id:
            return jsonify({"msg": "Another category with this name already exists"}), 409
        category.name = name
    
    if budget_limit is not None:
        category.budget_limit = budget_limit
    
    if color_code:
        category.color_code = color_code
    
    try:
        category.save_to_db()
        return jsonify({
            "msg": "Category updated successfully",
            "category": category.to_dict()
        }), 200
    except Exception as e:
        return jsonify({"msg": f"Error updating category: {str(e)}"}), 500

@api_bp.route('/categories/<int:category_id>', methods=['DELETE'])
@jwt_required()
def delete_category(category_id):
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    
    category = Category.query.filter_by(id=category_id, user_id=user.id).first()
    if not category:
        return jsonify({"msg": "Category not found"}), 404
    
    try:
        category.delete_from_db()
        return jsonify({"msg": "Category deleted successfully"}), 200
    except Exception as e:
        return jsonify({"msg": f"Error deleting category: {str(e)}"}), 500