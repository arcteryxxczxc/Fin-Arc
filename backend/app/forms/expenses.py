from flask_wtf import FlaskForm
from wtforms import StringField, DecimalField, DateField, TimeField, SelectField, TextAreaField
from wtforms import BooleanField, FileField, HiddenField, SubmitField
from wtforms.validators import DataRequired, Length, Optional, NumberRange
from flask_wtf.file import FileAllowed

class ExpenseForm(FlaskForm):
    """
    Form for adding or editing an expense
    
    This form handles all fields related to expense entries including
    amount, date, category, payment method, and receipt upload.
    """
    amount = DecimalField('Amount', validators=[
        DataRequired(message='Amount is required'),
        NumberRange(min=0.01, message='Amount must be greater than zero')
    ])
    
    description = StringField('Description', validators=[
        Length(max=255, message='Description must be less than 255 characters')
    ])
    
    date = DateField('Date', validators=[
        DataRequired(message='Date is required')
    ], format='%Y-%m-%d')
    
    time = TimeField('Time', validators=[Optional()], format='%H:%M')
    
    category_id = SelectField('Category', validators=[Optional()], coerce=int)
    
    payment_method = SelectField('Payment Method', validators=[Optional()], choices=[
        ('', 'Select Payment Method'),
        ('cash', 'Cash'),
        ('credit_card', 'Credit Card'),
        ('debit_card', 'Debit Card'),
        ('bank_transfer', 'Bank Transfer'),
        ('mobile_payment', 'Mobile Payment'),
        ('other', 'Other')
    ])
    
    location = StringField('Location', validators=[
        Optional(),
        Length(max=255, message='Location must be less than 255 characters')
    ])
    
    receipt = FileField('Receipt', validators=[
        Optional(),
        FileAllowed(['jpg', 'jpeg', 'png', 'pdf'], 'Images and PDFs only!')
    ])
    
    is_recurring = BooleanField('Recurring Expense', default=False)
    
    recurring_type = SelectField('Recurrence Type', validators=[Optional()], choices=[
        ('', 'Select Recurrence Type'),
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('yearly', 'Yearly')
    ])
    
    notes = TextAreaField('Notes', validators=[
        Optional(),
        Length(max=1000, message='Notes must be less than 1000 characters')
    ])
    
    submit = SubmitField('Save Expense')


class ExpenseFilterForm(FlaskForm):
    """
    Form for filtering expenses in a list view
    
    This form provides various filter options for the expenses list,
    including date range, category, amount range, and search.
    """
    start_date = DateField('From', validators=[Optional()], format='%Y-%m-%d')
    
    end_date = DateField('To', validators=[Optional()], format='%Y-%m-%d')
    
    category_id = SelectField('Category', validators=[Optional()], coerce=int)
    
    min_amount = DecimalField('Min Amount', validators=[Optional()])
    
    max_amount = DecimalField('Max Amount', validators=[Optional()])
    
    payment_method = SelectField('Payment Method', validators=[Optional()], choices=[
        ('', 'All Payment Methods'),
        ('cash', 'Cash'),
        ('credit_card', 'Credit Card'),
        ('debit_card', 'Debit Card'),
        ('bank_transfer', 'Bank Transfer'),
        ('mobile_payment', 'Mobile Payment'),
        ('other', 'Other')
    ])
    
    search = StringField('Search', validators=[Optional()])
    
    submit = SubmitField('Apply Filters')
    reset = SubmitField('Reset')


class ExpenseBulkActionForm(FlaskForm):
    """
    Form for performing bulk actions on selected expenses
    
    This form allows operations like delete, change category, or export
    on multiple selected expenses at once.
    """
    selected_expenses = HiddenField('Selected Expenses')
    
    action = SelectField('Action', choices=[
        ('', 'Select Action'),
        ('delete', 'Delete Selected'),
        ('change_category', 'Change Category'),
        ('export', 'Export Selected')
    ])
    
    target_category_id = SelectField('Target Category', validators=[Optional()], coerce=int)
    
    confirm = BooleanField('Confirm', default=False, validators=[
        DataRequired(message='Please confirm this action')
    ])
    
    submit = SubmitField('Apply')