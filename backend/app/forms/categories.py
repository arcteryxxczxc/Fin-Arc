# backend/forms/categories.py

from flask_wtf import FlaskForm
from wtforms import StringField, DecimalField, TextAreaField, SelectField, BooleanField, SubmitField
from wtforms import IntegerField, HiddenField
from wtforms.validators import DataRequired, Length, Optional, NumberRange, ValidationError

class CategoryForm(FlaskForm):
    """Form for adding or editing a category"""
    
    name = StringField('Category Name', validators=[
        DataRequired(message='Category name is required'),
        Length(min=2, max=50, message='Category name must be between 2 and 50 characters')
    ])
    
    description = TextAreaField('Description', validators=[
        Optional(),
        Length(max=255, message='Description must be less than 255 characters')
    ])
    
    color_code = StringField('Color', validators=[
        DataRequired(message='Color is required'),
        Length(min=4, max=7, message='Color must be a valid hex code')
    ])
    
    icon = SelectField('Icon', validators=[Optional()], choices=[
        ('', 'No Icon'),
        ('shopping-cart', 'Shopping Cart'),
        ('utensils', 'Food & Dining'),
        ('home', 'Housing'),
        ('car', 'Transportation'),
        ('medkit', 'Healthcare'),
        ('graduation-cap', 'Education'),
        ('briefcase', 'Work'),
        ('gamepad', 'Entertainment'),
        ('tshirt', 'Clothing'),
        ('plane', 'Travel'),
        ('gift', 'Gifts'),
        ('money-bill-wave', 'Bills & Utilities'),
        ('piggy-bank', 'Savings'),
        ('chart-line', 'Investments'),
        ('heart', 'Personal Care'),
        ('paw', 'Pets'),
        ('child', 'Children'),
        ('hands-helping', 'Charity'),
        ('ellipsis-h', 'Other')
    ])
    
    budget_limit = DecimalField('Monthly Budget Limit', validators=[
        Optional(),
        NumberRange(min=0, message='Budget limit must be a positive number')
    ])
    
    budget_start_day = IntegerField('Budget Start Day', validators=[
        Optional(),
        NumberRange(min=1, max=31, message='Day must be between 1 and 31')
    ], default=1)
    
    is_income = BooleanField('Income Category', default=False)
    
    is_active = BooleanField('Active', default=True)
    
    submit = SubmitField('Save Category')
    
    def validate_color_code(self, field):
        """Validate that color_code is a valid hex color code"""
        if not field.data:
            return
            
        # Check if the value is a valid hex color code
        if not (field.data.startswith('#') and len(field.data) in [4, 7]):
            raise ValidationError('Color must be a valid hex code (e.g., #FFF or #FFFFFF)')
            
        # Check if all characters after # are valid hex digits
        try:
            int(field.data[1:], 16)
        except ValueError:
            raise ValidationError('Color must be a valid hex code (e.g., #FFF or #FFFFFF)')

class CategoryBulkActionForm(FlaskForm):
    """Form for performing bulk actions on selected categories"""
    
    selected_categories = HiddenField('Selected Categories')
    
    action = SelectField('Action', choices=[
        ('', 'Select Action'),
        ('delete', 'Delete Selected'),
        ('activate', 'Activate Selected'),
        ('deactivate', 'Deactivate Selected')
    ])
    
    confirm = BooleanField('Confirm', default=False, validators=[
        DataRequired(message='Please confirm this action')
    ])
    
    submit = SubmitField('Apply')

class CategoryBudgetForm(FlaskForm):
    """Form for quickly updating multiple category budgets"""
    
    # This will be populated dynamically with fields named 'budget_[category_id]'
    submit = SubmitField('Update Budgets')
    
    def __init__(self, *args, categories=None, **kwargs):
        super(CategoryBudgetForm, self).__init__(*args, **kwargs)
        
        # Dynamically add fields for each category
        if categories:
            for category in categories:
                field_name = f'budget_{category.id}'
                field = DecimalField(
                    f'Budget for {category.name}',
                    validators=[Optional(), NumberRange(min=0)],
                    default=category.budget_limit
                )
                setattr(self, field_name, field)