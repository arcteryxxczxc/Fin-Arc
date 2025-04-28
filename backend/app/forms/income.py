from flask_wtf import FlaskForm
from wtforms import StringField, DecimalField, DateField, SelectField, TextAreaField
from wtforms import BooleanField, HiddenField, SubmitField, IntegerField
from wtforms.validators import DataRequired, Length, Optional, NumberRange

class IncomeForm(FlaskForm):
    """
    Form for adding or editing income
    
    This form handles all fields related to income entries including
    amount, source, date, and tax information.
    """
    amount = DecimalField('Amount', validators=[
        DataRequired(message='Amount is required'),
        NumberRange(min=0.01, message='Amount must be greater than zero')
    ])
    
    source = StringField('Source', validators=[
        DataRequired(message='Income source is required'),
        Length(max=100, message='Source must be less than 100 characters')
    ])
    
    description = StringField('Description', validators=[
        Optional(),
        Length(max=255, message='Description must be less than 255 characters')
    ])
    
    date = DateField('Date', validators=[
        DataRequired(message='Date is required')
    ], format='%Y-%m-%d')
    
    category_id = SelectField('Category', validators=[Optional()], coerce=int)
    
    is_recurring = BooleanField('Recurring Income', default=False)
    
    recurring_type = SelectField('Recurrence Type', validators=[Optional()], choices=[
        ('', 'Select Recurrence Type'),
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('yearly', 'Yearly')
    ])
    
    recurring_day = IntegerField('Recurring Day', validators=[
        Optional(),
        NumberRange(min=1, max=31, message='Day must be between 1 and 31')
    ])
    
    is_taxable = BooleanField('Taxable Income', default=True)
    
    tax_rate = DecimalField('Tax Rate (%)', validators=[
        Optional(),
        NumberRange(min=0, max=100, message='Tax rate must be between 0 and 100')
    ])
    
    submit = SubmitField('Save Income')


class IncomeFilterForm(FlaskForm):
    """
    Form for filtering incomes in a list view
    
    This form provides various filter options for the income list,
    including date range, source, category, and amount range.
    """
    start_date = DateField('From', validators=[Optional()], format='%Y-%m-%d')
    
    end_date = DateField('To', validators=[Optional()], format='%Y-%m-%d')
    
    source = SelectField('Source', validators=[Optional()])
    
    category_id = SelectField('Category', validators=[Optional()], coerce=int)
    
    min_amount = DecimalField('Min Amount', validators=[Optional()])
    
    max_amount = DecimalField('Max Amount', validators=[Optional()])
    
    is_recurring = BooleanField('Recurring Only', default=False)
    
    search = StringField('Search', validators=[Optional()])
    
    submit = SubmitField('Apply Filters')
    reset = SubmitField('Reset')


class IncomeBulkActionForm(FlaskForm):
    """
    Form for performing bulk actions on selected incomes
    
    This form allows operations like delete, change category, or export
    on multiple selected incomes at once.
    """
    selected_incomes = HiddenField('Selected Incomes')
    
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


class RecurringIncomeForm(FlaskForm):
    """
    Form specifically for recurring income with additional fields
    
    This form extends the basic income form with additional fields
    specific to recurring income entries, such as start/end dates.
    """
    amount = DecimalField('Amount', validators=[
        DataRequired(message='Amount is required'),
        NumberRange(min=0.01, message='Amount must be greater than zero')
    ])
    
    source = StringField('Source', validators=[
        DataRequired(message='Income source is required'),
        Length(max=100, message='Source must be less than 100 characters')
    ])
    
    description = StringField('Description', validators=[
        Optional(),
        Length(max=255, message='Description must be less than 255 characters')
    ])
    
    start_date = DateField('Start Date', validators=[
        DataRequired(message='Start date is required')
    ], format='%Y-%m-%d')
    
    end_date = DateField('End Date (Optional)', validators=[Optional()], format='%Y-%m-%d')
    
    category_id = SelectField('Category', validators=[Optional()], coerce=int)
    
    recurring_type = SelectField('Recurrence Type', validators=[
        DataRequired(message='Recurrence type is required')
    ], choices=[
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('yearly', 'Yearly')
    ])
    
    recurring_day = IntegerField('Day of Month/Week', validators=[
        Optional(),
        NumberRange(min=1, max=31, message='Day must be between 1 and 31')
    ])
    
    is_taxable = BooleanField('Taxable Income', default=True)
    
    tax_rate = DecimalField('Tax Rate (%)', validators=[
        Optional(),
        NumberRange(min=0, max=100, message='Tax rate must be between 0 and 100')
    ])
    
    submit = SubmitField('Save Recurring Income')