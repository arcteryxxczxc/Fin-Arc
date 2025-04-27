# backend/forms/auth.py

from flask import current_app
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SubmitField, ValidationError
from wtforms.validators import DataRequired, Email, Length, EqualTo, Regexp
from backend.models.user import User

class LoginForm(FlaskForm):
    """
    Form for user login with username and password
    """
    username = StringField('Username', validators=[
        DataRequired(message='Username is required'),
        Length(min=3, max=64, message='Username must be between 3 and 64 characters')
    ])
    
    password = PasswordField('Password', validators=[
        DataRequired(message='Password is required')
    ])
    
    remember_me = BooleanField('Remember Me')
    
    submit = SubmitField('Sign In')

class RegistrationForm(FlaskForm):
    """
    Form for user registration with enhanced password security
    """
    username = StringField('Username', validators=[
        DataRequired(message='Username is required'),
        Length(min=3, max=64, message='Username must be between 3 and 64 characters'),
        # Alphanumeric characters, dots, and underscores only
        Regexp('^[A-Za-z0-9_.]+$', message='Username can only contain letters, numbers, dots, and underscores')
    ])
    
    email = StringField('Email', validators=[
        DataRequired(message='Email is required'),
        Email(message='Invalid email address'),
        Length(max=120, message='Email must be less than 120 characters')
    ])
    
    first_name = StringField('First Name', validators=[
        DataRequired(message='First name is required'),
        Length(max=64, message='First name must be less than 64 characters')
    ])
    
    last_name = StringField('Last Name', validators=[
        DataRequired(message='Last name is required'),
        Length(max=64, message='Last name must be less than 64 characters')
    ])
    
    password = PasswordField('Password', validators=[
        DataRequired(message='Password is required'),
        Length(min=8, message='Password must be at least 8 characters'),
        # Ensure password meets complexity requirements
        Regexp(r'.*[A-Z].*', message='Password must contain at least one uppercase letter'),
        Regexp(r'.*[a-z].*', message='Password must contain at least one lowercase letter'),
        Regexp(r'.*[0-9].*', message='Password must contain at least one number'),
        Regexp(r'.*[!@#$%^&*()_+\-=\[\]{};\':"\\|,.<>\/?].*', 
               message='Password must contain at least one special character')
    ])
    
    confirm_password = PasswordField('Confirm Password', validators=[
        DataRequired(message='Please confirm your password'),
        EqualTo('password', message='Passwords must match')
    ])
    
    submit = SubmitField('Register')
    
    def validate_username(self, username):
        """Check if username is already in use"""
        user = User.query.filter_by(username=username.data).first()
        if user is not None:
            raise ValidationError('Username already in use. Please choose a different one.')
    
    def validate_email(self, email):
        """Check if email is already in use"""
        user = User.query.filter_by(email=email.data).first()
        if user is not None:
            raise ValidationError('Email already in use. Please use a different one.')

class ResetPasswordRequestForm(FlaskForm):
    """
    Form for requesting a password reset via email
    """
    email = StringField('Email', validators=[
        DataRequired(message='Email is required'),
        Email(message='Invalid email address')
    ])
    
    submit = SubmitField('Request Password Reset')

class ResetPasswordForm(FlaskForm):
    """
    Form for resetting the password with a secure token
    """
    password = PasswordField('New Password', validators=[
        DataRequired(message='Password is required'),
        Length(min=8, message='Password must be at least 8 characters'),
        # Ensure password meets complexity requirements
        Regexp(r'.*[A-Z].*', message='Password must contain at least one uppercase letter'),
        Regexp(r'.*[a-z].*', message='Password must contain at least one lowercase letter'),
        Regexp(r'.*[0-9].*', message='Password must contain at least one number'),
        Regexp(r'.*[!@#$%^&*()_+\-=\[\]{};\':"\\|,.<>\/?].*', 
               message='Password must contain at least one special character')
    ])
    
    confirm_password = PasswordField('Confirm Password', validators=[
        DataRequired(message='Please confirm your password'),
        EqualTo('password', message='Passwords must match')
    ])
    
    submit = SubmitField('Reset Password')

class ChangePasswordForm(FlaskForm):
    """
    Form for changing password when already logged in
    """
    current_password = PasswordField('Current Password', validators=[
        DataRequired(message='Current password is required')
    ])
    
    new_password = PasswordField('New Password', validators=[
        DataRequired(message='New password is required'),
        Length(min=8, message='Password must be at least 8 characters'),
        # Ensure password meets complexity requirements
        Regexp(r'.*[A-Z].*', message='Password must contain at least one uppercase letter'),
        Regexp(r'.*[a-z].*', message='Password must contain at least one lowercase letter'),
        Regexp(r'.*[0-9].*', message='Password must contain at least one number'),
        Regexp(r'.*[!@#$%^&*()_+\-=\[\]{};\':"\\|,.<>\/?].*', 
               message='Password must contain at least one special character')
    ])
    
    confirm_new_password = PasswordField('Confirm New Password', validators=[
        DataRequired(message='Please confirm your new password'),
        EqualTo('new_password', message='Passwords must match')
    ])
    
    submit = SubmitField('Change Password')