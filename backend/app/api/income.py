from flask import request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api import api_bp
from app import db
from app.models.income import Income
from app.models.category import Category
from app.models.user import User
from app.utils.api import api_success, api_error
from app.utils.db import safe_commit, paginate_query
from app.utils.validation import validate_json, INCOME_SCHEMA
from sqlalchemy import or_, func
from datetime import datetime
import csv
import io
import hashlib
import logging

# Set up logging
logger = logging.getLogger(__name__)

@api_bp.route('/income', methods=['GET'])
@jwt_required()
def get_income_entries():
    """
    Get a list of income entries for the current user
    
    Query parameters:
    - page: Page number (default: 1)
    - per_page: Items per page (default: 10)
    - category_id: Filter by category
    - start_date: Filter by start date (YYYY-MM-DD)
    - end_date: Filter by end date (YYYY-MM-DD)
    - min_amount: Filter by minimum amount
    - max_amount: Filter by maximum amount
    - source: Filter by income source
    - is_recurring: Filter recurring income only (true/false)
    - search: Search in description or source
    
    Returns:
        JSON response with a list of income entries and pagination info
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
        query = Income.query.filter_by(user_id=user.id)
        
        # Apply filters
        category_id = request.args.get('category_id', type=int)
        if category_id:
            query = query.filter(Income.category_id == category_id)
        
        start_date = request.args.get('start_date')
        if start_date:
            try:
                query = query.filter(Income.date >= datetime.strptime(start_date, '%Y-%m-%d').date())
            except ValueError:
                return api_error("Invalid start_date format. Use YYYY-MM-DD", 400)
        
        end_date = request.args.get('end_date')
        if end_date:
            try:
                query = query.filter(Income.date <= datetime.strptime(end_date, '%Y-%m-%d').date())
            except ValueError:
                return api_error("Invalid end_date format. Use YYYY-MM-DD", 400)
        
        min_amount = request.args.get('min_amount', type=float)
        if min_amount:
            query = query.filter(Income.amount >= min_amount)
        
        max_amount = request.args.get('max_amount', type=float)
        if max_amount:
            query = query.filter(Income.amount <= max_amount)
        
        source = request.args.get('source')
        if source:
            query = query.filter(Income.source == source)
        
        is_recurring = request.args.get('is_recurring')
        if is_recurring is not None:
            is_recurring_bool = is_recurring.lower() == 'true'
            query = query.filter(Income.is_recurring == is_recurring_bool)
        
        search = request.args.get('search')
        if search:
            search_term = f"%{search}%"
            query = query.filter(
                or_(
                    Income.description.ilike(search_term),
                    Income.source.ilike(search_term)
                )
            )
        
        # Order by date (newest first)
        query = query.order_by(Income.date.desc(), Income.id.desc())
        
        # Paginate
        income_page = paginate_query(query, page, per_page)
        
        # Format response
        incomes = [{
            "id": income.id,
            "amount": float(income.amount),
            "formatted_amount": income.formatted_amount,
            "source": income.source,
            "description": income.description,
            "date": income.formatted_date,
            "category_id": income.category_id,
            "category_name": income.category.name if income.category else None,
            "is_recurring": income.is_recurring,
            "recurring_type": income.recurring_type,
            "recurring_day": income.recurring_day,
            "is_taxable": income.is_taxable,
            "tax_rate": float(income.tax_rate) if income.tax_rate else None,
            "after_tax_amount": income.after_tax_amount
        } for income in income_page.items]
        
        pagination = {
            "page": income_page.page,
            "per_page": income_page.per_page,
            "total_pages": income_page.pages,
            "total_items": income_page.total
        }
        
        return api_success({
            "income": incomes,
            "pagination": pagination
        })
        
    except Exception as e:
        logger.error(f"Error getting income entries: {str(e)}")
        return api_error("An error occurred while retrieving income entries", 500)

@api_bp.route('/income/<int:income_id>', methods=['GET'])
@jwt_required()
def get_income(income_id):
    """
    Get a specific income entry by ID
    
    Path parameters:
    - income_id: ID of the income entry to retrieve
    
    Returns:
        JSON response with income details
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get income
        income = Income.query.filter_by(id=income_id, user_id=user.id).first()
        
        if not income:
            return api_error("Income entry not found", 404)
        
        # Format response
        income_data = {
            "id": income.id,
            "amount": float(income.amount),
            "formatted_amount": income.formatted_amount,
            "source": income.source,
            "description": income.description,
            "date": income.formatted_date,
            "category_id": income.category_id,
            "category_name": income.category.name if income.category else None,
            "is_recurring": income.is_recurring,
            "recurring_type": income.recurring_type,
            "recurring_day": income.recurring_day,
            "is_taxable": income.is_taxable,
            "tax_rate": float(income.tax_rate) if income.tax_rate else None,
            "after_tax_amount": income.after_tax_amount,
            "created_at": income.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            "updated_at": income.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        return api_success({"income": income_data})
        
    except Exception as e:
        logger.error(f"Error getting income {income_id}: {str(e)}")
        return api_error("An error occurred while retrieving the income entry", 500)

@api_bp.route('/income', methods=['POST'])
@jwt_required()
@validate_json(INCOME_SCHEMA)
def create_income():
    """
    Create a new income entry
    
    Request body:
    - amount: Income amount (required)
    - source: Income source (required)
    - description: Income description
    - date: Income date (YYYY-MM-DD)
    - category_id: Category ID
    - is_recurring: Whether the income is recurring
    - recurring_type: Type of recurrence (daily, weekly, monthly, yearly)
    - recurring_day: Day of month/week for recurring income
    - is_taxable: Whether the income is taxable
    - tax_rate: Tax rate percentage
    
    Returns:
        JSON response with the created income entry
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get request data
        data = request.get_json()
        
        # Parse date
        date_val = datetime.utcnow().date()
        if 'date' in data and data['date']:
            try:
                date_val = datetime.strptime(data['date'], '%Y-%m-%d').date()
            except ValueError:
                return api_error("Invalid date format. Use YYYY-MM-DD", 400)
        
        # Create income entry
        income = Income(
            user_id=user.id,
            amount=data['amount'],
            source=data['source'],
            description=data.get('description'),
            date=date_val,
            is_recurring=data.get('is_recurring', False),
            recurring_type=data.get('recurring_type') if data.get('is_recurring', False) else None,
            recurring_day=data.get('recurring_day') if data.get('is_recurring', False) else None,
            is_taxable=data.get('is_taxable', False),
            tax_rate=data.get('tax_rate') if data.get('is_taxable', False) else None
        )
        
        # Handle category
        category_id = data.get('category_id')
        if category_id:
            # Verify that this is an income category
            category = Category.query.filter_by(
                id=category_id, 
                user_id=user.id,
                is_income=True
            ).first()
            
            if category:
                income.category_id = category.id
            else:
                return api_error("Invalid income category", 400)
        
        # Save to database
        db.session.add(income)
        success, error = safe_commit()
        
        if not success:
            return api_error(f"Database error: {error}", 500)
        
        # Format response
        income_data = {
            "id": income.id,
            "amount": float(income.amount),
            "formatted_amount": income.formatted_amount,
            "source": income.source,
            "description": income.description,
            "date": income.formatted_date,
            "category_id": income.category_id,
            "category_name": income.category.name if income.category else None,
            "is_recurring": income.is_recurring,
            "recurring_type": income.recurring_type,
            "recurring_day": income.recurring_day,
            "is_taxable": income.is_taxable,
            "tax_rate": float(income.tax_rate) if income.tax_rate else None,
            "after_tax_amount": income.after_tax_amount
        }
        
        return api_success({
            "message": "Income entry created successfully",
            "income": income_data
        }, code=201)
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error creating income: {str(e)}")
        return api_error("An error occurred while creating the income entry", 500)

@api_bp.route('/income/<int:income_id>', methods=['PUT'])
@jwt_required()
def update_income(income_id):
    """
    Update an existing income entry
    
    Path parameters:
    - income_id: ID of the income entry to update
    
    Request body:
    - amount: Income amount
    - source: Income source
    - description: Income description
    - date: Income date (YYYY-MM-DD)
    - category_id: Category ID
    - is_recurring: Whether the income is recurring
    - recurring_type: Type of recurrence (daily, weekly, monthly, yearly)
    - recurring_day: Day of month/week for recurring income
    - is_taxable: Whether the income is taxable
    - tax_rate: Tax rate percentage
    
    Returns:
        JSON response with the updated income entry
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get income
        income = Income.query.filter_by(id=income_id, user_id=user.id).first()
        
        if not income:
            return api_error("Income entry not found", 404)
        
        # Get request data
        data = request.get_json()
        
        if not data:
            return api_error("Missing JSON in request", 400)
        
        # Update income
        if 'amount' in data:
            try:
                amount = float(data['amount'])
                if amount <= 0:
                    return api_error("Amount must be greater than zero", 400)
                income.amount = amount
            except ValueError:
                return api_error("Invalid amount format", 400)
        
        # Update source
        if 'source' in data:
            income.source = data['source']
            
        # Update description
        if 'description' in data:
            income.description = data['description']
        
        # Update date
        if 'date' in data:
            try:
                income.date = datetime.strptime(data['date'], '%Y-%m-%d').date()
            except ValueError:
                return api_error("Invalid date format. Use YYYY-MM-DD", 400)
        
        # Update category
        if 'category_id' in data:
            category_id = data['category_id']
            if category_id:
                # Verify that this is an income category
                category = Category.query.filter_by(
                    id=category_id, 
                    user_id=user.id,
                    is_income=True
                ).first()
                
                if category:
                    income.category_id = category.id
                else:
                    return api_error("Invalid income category", 400)
            else:
                income.category_id = None
        
        # Update recurring fields
        if 'is_recurring' in data:
            income.is_recurring = data['is_recurring']
            
            # Update recurring_type if is_recurring is True
            if 'recurring_type' in data and income.is_recurring:
                income.recurring_type = data['recurring_type']
                
            # Update recurring_day if is_recurring is True
            if 'recurring_day' in data and income.is_recurring:
                income.recurring_day = data['recurring_day']
                
            # Clear recurring fields if is_recurring is False
            if not income.is_recurring:
                income.recurring_type = None
                income.recurring_day = None
        
        # Update tax fields
        if 'is_taxable' in data:
            income.is_taxable = data['is_taxable']
            
            # Update tax_rate if is_taxable is True
            if 'tax_rate' in data and income.is_taxable:
                income.tax_rate = data['tax_rate']
                
            # Clear tax_rate if is_taxable is False
            if not income.is_taxable:
                income.tax_rate = None
        
        # Save to database
        success, error = safe_commit()
        
        if not success:
            return api_error(f"Database error: {error}", 500)
        
        # Format response
        income_data = {
            "id": income.id,
            "amount": float(income.amount),
            "formatted_amount": income.formatted_amount,
            "source": income.source,
            "description": income.description,
            "date": income.formatted_date,
            "category_id": income.category_id,
            "category_name": income.category.name if income.category else None,
            "is_recurring": income.is_recurring,
            "recurring_type": income.recurring_type,
            "recurring_day": income.recurring_day,
            "is_taxable": income.is_taxable,
            "tax_rate": float(income.tax_rate) if income.tax_rate else None,
            "after_tax_amount": income.after_tax_amount,
            "updated_at": income.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        return api_success({
            "message": "Income entry updated successfully",
            "income": income_data
        })
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error updating income {income_id}: {str(e)}")
        return api_error("An error occurred while updating the income entry", 500)

@api_bp.route('/income/<int:income_id>', methods=['DELETE'])
@jwt_required()
def delete_income(income_id):
    """
    Delete an income entry
    
    Path parameters:
    - income_id: ID of the income entry to delete
    
    Returns:
        JSON response with success message
    """
    try:
        # Get current user
        current_username = get_jwt_identity()
        user = User.query.filter_by(username=current_username).first()
        
        if not user:
            return api_error("User not found", 404)
        
        # Get income
        income = Income.query.filter_by(id=income_id, user_id=user.id).first()
        
        if not income:
            return api_error("Income entry not found", 404)
        
        # Delete income
        db.session.delete(income)
        success, error = safe_commit()
        
        if not success:
            return api_error(f"Database error: {error}", 500)
        
        return api_success(message="Income entry deleted successfully")
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error deleting income {income_id}: {str(e)}")
        return api_error("An error occurred while deleting the income entry", 500)

@api_bp.route('/income/bulk', methods=['POST'])
@jwt_required()
def bulk_action_income():
    """
    Perform bulk actions on income entries
    
    Request body:
    - action: Action to perform (delete, change_category)
    - income_ids: List of income entry IDs to perform the action on
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
        
        if 'income_ids' not in data or not data['income_ids']:
            return api_error("Income IDs are required", 400)
        
        action = data['action']
        income_ids = data['income_ids']
        
        # Validate income IDs
        try:
            income_ids = [int(id) for id in income_ids]
        except ValueError:
            return api_error("Invalid income ID format", 400)
        
        # Get income entries
        incomes = Income.query.filter(
            Income.id.in_(income_ids),
            Income.user_id == user.id
        ).all()
        
        if not incomes:
            return api_error("No valid income entries found", 404)
        
        # Perform action
        if action == 'delete':
            # Delete income entries
            for income in incomes:
                db.session.delete(income)
            
            success, error = safe_commit()
            
            if not success:
                return api_error(f"Database error: {error}", 500)
                
            return api_success({
                "message": f"{len(incomes)} income entries deleted successfully"
            })
            
        elif action == 'change_category':
            # Validate target category ID
            if 'target_category_id' not in data:
                return api_error("Target category ID is required for change_category action", 400)
            
            target_category_id = data['target_category_id']
            
            # Validate category
            if target_category_id:
                category = Category.query.filter_by(
                    id=target_category_id, 
                    user_id=user.id,
                    is_income=True
                ).first()
                
                if not category:
                    return api_error("Target category not found or not an income category", 404)
            
            # Update category
            for income in incomes:
                income.category_id = target_category_id
            
            success, error = safe_commit()
            
            if not success:
                return api_error(f"Database error: {error}", 500)
                
            return api_success({
                "message": f"Category updated for {len(incomes)} income entries"
            })
            
        else:
            return api_error(f"Invalid action: {action}", 400)
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error performing bulk action on income entries: {str(e)}")
        return api_error("An error occurred while performing the bulk action", 500)

@api_bp.route('/income/export', methods=['GET'])
@jwt_required()
def export_income():
    """
    Export income entries as CSV
    
    Query parameters:
    - ids: Comma-separated list of income entry IDs to export (optional)
    - all other filter parameters from get_income_entries
    
    Returns:
        CSV file with income entries
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
                income_ids = [int(id) for id in ids_param.split(',')]
                incomes = Income.query.filter(
                    Income.id.in_(income_ids),
                    Income.user_id == user.id
                ).order_by(Income.date.desc()).all()
            except ValueError:
                return api_error("Invalid income ID format", 400)
        else:
            # Build query using the same filters as get_income_entries
            query = Income.query.filter_by(user_id=user.id)
            
            # Apply filters
            category_id = request.args.get('category_id', type=int)
            if category_id:
                query = query.filter(Income.category_id == category_id)
            
            start_date = request.args.get('start_date')
            if start_date:
                try:
                    query = query.filter(Income.date >= datetime.strptime(start_date, '%Y-%m-%d').date())
                except ValueError:
                    return api_error("Invalid start_date format. Use YYYY-MM-DD", 400)
            
            end_date = request.args.get('end_date')
            if end_date:
                try:
                    query = query.filter(Income.date <= datetime.strptime(end_date, '%Y-%m-%d').date())
                except ValueError:
                    return api_error("Invalid end_date format. Use YYYY-MM-DD", 400)
            
            min_amount = request.args.get('min_amount', type=float)
            if min_amount:
                query = query.filter(Income.amount >= min_amount)
            
            max_amount = request.args.get('max_amount', type=float)
            if max_amount:
                query = query.filter(Income.amount <= max_amount)
            
            source = request.args.get('source')
            if source:
                query = query.filter(Income.source == source)
            
            is_recurring = request.args.get('is_recurring')
            if is_recurring is not None:
                is_recurring_bool = is_recurring.lower() == 'true'
                query = query.filter(Income.is_recurring == is_recurring_bool)
            
            search = request.args.get('search')
            if search:
                search_term = f"%{search}%"
                query = query.filter(
                    or_(
                        Income.description.ilike(search_term),
                        Income.source.ilike(search_term)
                    )
                )
            
            # Get all matching income entries
            incomes = query.order_by(Income.date.desc()).all()
        
        if not incomes:
            return api_error("No income entries found matching the criteria", 404)
        
        # Create CSV
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Write header row
        writer.writerow([
            'ID', 'Date', 'Source', 'Description', 'Amount', 'After-Tax Amount',
            'Category', 'Recurring', 'Recurring Type', 'Taxable', 'Tax Rate (%)'
        ])
        
        # Write data rows
        for income in incomes:
            category_name = income.category.name if income.category else ''
            recurring_type = income.recurring_type if income.is_recurring else ''
            tax_rate = income.tax_rate if income.is_taxable else ''
            
            writer.writerow([
                income.id,
                income.formatted_date,
                income.source,
                income.description or '',
                income.formatted_amount,
                "{:.2f}".format(income.after_tax_amount),
                category_name,
                'Yes' if income.is_recurring else 'No',
                recurring_type or '',
                'Yes' if income.is_taxable else 'No',
                tax_rate or ''
            ])
        
        # Prepare response
        output.seek(0)
        
        # Return CSV file
        return {
            "content": output.getvalue(),
            "status": 200,
            "mimetype": "application/json",
            "headers": {
                "Content-Disposition": f"attachment;filename=income_{datetime.now().strftime('%Y%m%d')}.csv"
            }
        }
        
    except Exception as e:
        logger.error(f"Error exporting income entries: {str(e)}")
        return api_error("An error occurred while exporting income entries", 500)

@api_bp.route('/income/stats', methods=['GET'])
@jwt_required()
def get_income_stats():
    """
    Get income statistics
    
    Query parameters:
    - period: Stats period (month, year, all) - default: month
    - source: Filter by income source
    
    Returns:
        JSON response with income statistics
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
        
        # Get source filter
        source = request.args.get('source')
        
        # Build query
        query = Income.query.filter_by(user_id=user.id)
        
        if start_date:
            query = query.filter(Income.date >= start_date)
        
        if source:
            query = query.filter(Income.source == source)
        
        # Get total income
        total_income = db.session.query(func.sum(Income.amount)).filter(
            query.whereclause
        ).scalar() or 0
        
        # Get after-tax income
        income_entries = query.all()
        after_tax_income = sum(income.after_tax_amount for income in income_entries)
        
        # Get income count
        income_count = len(income_entries)
        
        # Get average income
        avg_income = total_income / income_count if income_count > 0 else 0
        
        # Get income by source
        source_data = db.session.query(
            Income.source,
            func.sum(Income.amount).label('total')
        ).filter(
            Income.user_id == user.id
        )
        
        if start_date:
            source_data = source_data.filter(Income.date >= start_date)
        
        source_data = source_data.group_by(
            Income.source
        ).order_by(
            func.sum(Income.amount).desc()
        ).all()
        
        # Format source data
        sources = []
        for source_name, source_total in source_data:
            if source_total:
                # Generate a color for this source based on name
                hash_object = hashlib.md5(source_name.encode())
                hashed = hash_object.hexdigest()
                color = f'#{hashed[:6]}'
                
                sources.append({
                    'source': source_name,
                    'total': float(source_total),
                    'color': color,
                    'percentage': (float(source_total) / float(total_income) * 100) if float(total_income) > 0 else 0
                })
        
        # Get monthly trend
        monthly_data = db.session.query(
            func.date_trunc('month', Income.date).label('month'),
            func.sum(Income.amount).label('total')
        ).filter(
            Income.user_id == user.id
        )
        
        if source:
            monthly_data = monthly_data.filter(Income.source == source)
        
        monthly_data = monthly_data.group_by(
            func.date_trunc('month', Income.date)
        ).order_by(
            func.date_trunc('month', Income.date)
        ).all()
        
        # Format monthly data
        monthly_trend = []
        for month_date, total in monthly_data:
            if month_date:
                monthly_trend.append({
                    'month': month_date.strftime('%b %Y'),
                    'total': float(total)
                })
        
        # Calculate average monthly income
        avg_monthly = Income.calculate_monthly_average(user.id, months=3)
        
        # Format response
        stats_data = {
            'period': period,
            'start_date': start_date.strftime('%Y-%m-%d') if start_date else None,
            'end_date': today.strftime('%Y-%m-%d'),
            'stats': {
                'total_income': float(total_income),
                'after_tax_income': float(after_tax_income),
                'income_count': income_count,
                'average_income': float(avg_income),
                'average_monthly': float(avg_monthly)
            },
            'sources': sources,
            'monthly_trend': monthly_trend
        }
        
        return api_success(stats_data)
        
    except Exception as e:
        logger.error(f"Error getting income stats: {str(e)}")
        return api_error("An error occurred while getting income statistics", 500)