# backend/routes/auth.py

from flask import Blueprint, render_template, redirect, url_for, flash, request, jsonify, current_app
from flask_login import login_user, logout_user, login_required, current_user
from werkzeug.urls import url_parse
from backend.app import db, bcrypt
from backend.models.user import User, LoginAttempt
from backend.forms.auth import LoginForm, RegistrationForm, ResetPasswordRequestForm, ResetPasswordForm
import logging

# Set up logging
logger = logging.getLogger(__name__)

# Create a Blueprint for auth routes
auth_routes = Blueprint('auth', __name__, url_prefix='/auth')

@auth_routes.route('/register', methods=['GET', 'POST'])
def register():
    """
    User registration endpoint
    Handles both form display and form submission
    """
    # If user is already logged in, redirect to home page
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    form = RegistrationForm()
    if form.validate_on_submit():
        try:
            # Create new user with data from the form
            user = User(
                username=form.username.data,
                email=form.email.data,
                first_name=form.first_name.data,
                last_name=form.last_name.data
            )
            user.password = form.password.data  # This will hash the password
            
            # Add user to database
            db.session.add(user)
            db.session.commit()
            
            # Log successful registration
            logger.info(f"User registered successfully: {user.username}")
            
            flash('Registration successful! You can now log in.', 'success')
            return redirect(url_for('auth.login'))
        except Exception as e:
            # Log error and rollback transaction
            logger.error(f"Error during registration: {str(e)}")
            db.session.rollback()
            flash('An error occurred during registration. Please try again.', 'danger')
        
    # For GET requests or if form validation fails
    return render_template('auth/register.html', title='Register', form=form)

@auth_routes.route('/login', methods=['GET', 'POST'])
def login():
    """
    User login endpoint with attempt tracking and account lockout
    Handles both form display and form submission
    """
    # If user is already logged in, redirect to home page
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    form = LoginForm()
    if form.validate_on_submit():
        # Find user by username
        user = User.query.filter_by(username=form.username.data).first()
        login_success = False
        
        # Check if user exists
        if user:
            # Check if account is locked
            if user.check_account_lock_status():
                flash('Account is temporarily locked due to multiple failed login attempts. Please try again later.', 'danger')
                logger.warning(f"Login attempt on locked account: {user.username}")
                return render_template('auth/login.html', title='Login', form=form)
            
            # Verify password
            if user.verify_password(form.password.data):
                login_success = True
                
                # Log the user in
                login_user(user, remember=form.remember_me.data)
                user.update_last_login()
                
                # Record successful login attempt
                LoginAttempt.add_login_attempt(
                    user=user,
                    ip_address=request.remote_addr,
                    user_agent=request.user_agent.string,
                    success=True
                )
                
                logger.info(f"Successful login: {user.username}")
                
                # Redirect to requested page or default
                next_page = request.args.get('next')
                if not next_page or url_parse(next_page).netloc != '':
                    next_page = url_for('index')
                
                return redirect(next_page)
        
        # Login failed - record the attempt if user exists
        if user:
            LoginAttempt.add_login_attempt(
                user=user,
                ip_address=request.remote_addr,
                user_agent=request.user_agent.string,
                success=False
            )
            
            logger.warning(f"Failed login attempt for user: {user.username}")
        else:
            logger.warning(f"Failed login attempt for non-existent user: {form.username.data}")
        
        # Show generic error message to prevent username enumeration
        flash('Invalid username or password', 'danger')
    
    return render_template('auth/login.html', title='Login', form=form)

@auth_routes.route('/logout')
@login_required
def logout():
    """User logout endpoint"""
    username = current_user.username  # Save username before logout
    logout_user()
    logger.info(f"User logged out: {username}")
    flash('You have been logged out successfully.', 'info')
    return redirect(url_for('index'))

@auth_routes.route('/profile')
@login_required
def profile():
    """User profile page"""
    return render_template('auth/profile.html', title='My Profile')

@auth_routes.route('/reset_password_request', methods=['GET', 'POST'])
def reset_password_request():
    """
    Password reset request endpoint
    Handles both form display and form submission
    """
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    form = ResetPasswordRequestForm()
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data).first()
        if user:
            token = user.generate_reset_token()
            # In a real application, send an email with the reset token
            # Here we'll just log it for demonstration
            reset_url = url_for('auth.reset_password', token=token, _external=True)
            logger.info(f"Password reset requested for {user.email}. Reset URL: {reset_url}")
            
        # Don't reveal if email exists for security
        flash('If your email address exists in our database, you will receive a password reset link shortly.', 'info')
        return redirect(url_for('auth.login'))
    
    return render_template('auth/reset_password_request.html', title='Reset Password', form=form)

@auth_routes.route('/reset_password/<token>', methods=['GET', 'POST'])
def reset_password(token):
    """
    Password reset with token endpoint
    Handles both form display and form submission
    """
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    # Verify token and get user
    user = User.verify_reset_token(token)
    if not user:
        flash('Invalid or expired reset token.', 'danger')
        return redirect(url_for('auth.reset_password_request'))
    
    form = ResetPasswordForm()
    if form.validate_on_submit():
        user.password = form.password.data
        user.clear_reset_token()
        db.session.commit()
        logger.info(f"Password reset successful for user: {user.username}")
        flash('Your password has been reset successfully.', 'success')
        return redirect(url_for('auth.login'))
    
    return render_template('auth/reset_password.html', title='Reset Password', form=form)

@auth_routes.route('/change_password', methods=['GET', 'POST'])
@login_required
def change_password():
    """
    Change password endpoint for authenticated users
    Handles both form display and form submission
    """
    from backend.forms.auth import ChangePasswordForm
    
    form = ChangePasswordForm()
    if form.validate_on_submit():
        if current_user.verify_password(form.current_password.data):
            current_user.password = form.new_password.data
            db.session.commit()
            logger.info(f"Password changed for user: {current_user.username}")
            flash('Your password has been updated.', 'success')
            return redirect(url_for('auth.profile'))
        else:
            flash('Current password is incorrect.', 'danger')
    
    return render_template('auth/change_password.html', title='Change Password', form=form)

@auth_routes.route('/account_status')
@login_required
def account_status():
    """API endpoint to get account status information"""
    return jsonify({
        'username': current_user.username,
        'email': current_user.email,
        'last_login': current_user.last_login.isoformat() if current_user.last_login else None,
        'account_created': current_user.created_at.isoformat(),
        'is_admin': current_user.is_admin
    })

@auth_routes.route('/login_history')
@login_required
def login_history():
    """View login history for the current user"""
    # Get the most recent login attempts (limit to 10)
    login_attempts = LoginAttempt.query.filter_by(user_id=current_user.id)\
        .order_by(LoginAttempt.timestamp.desc())\
        .limit(10)\
        .all()
    
    return render_template(
        'auth/login_history.html', 
        title='Login History',
        login_attempts=login_attempts
    )