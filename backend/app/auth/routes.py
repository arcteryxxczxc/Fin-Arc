from flask import render_template, redirect, url_for, flash, request
from flask_login import login_user, logout_user, login_required, current_user
from werkzeug.urls import url_parse
from app.auth import auth_bp
from app.models.user import User, LoginAttempt
from app.forms.auth import LoginForm, RegistrationForm, ResetPasswordRequestForm, ResetPasswordForm, ChangePasswordForm
import logging

# Set up logging
logger = logging.getLogger(__name__)

@auth_bp.route('/register', methods=['GET', 'POST'])
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
            user.save_to_db()
            
            # Log successful registration
            logger.info(f"User registered successfully: {user.username}")
            
            flash('Registration successful! You can now log in.', 'success')
            return redirect(url_for('auth.login'))
        except Exception as e:
            # Log error and rollback transaction
            logger.error(f"Error during registration: {str(e)}")
            flash('An error occurred during registration. Please try again.', 'danger')
        
    # For GET requests or if form validation fails
    return render_template('auth/register.html', title='Register', form=form)

@auth_bp.route('/login', methods=['GET', 'POST'])
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
            if user.is_account_locked():
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

@auth_bp.route('/logout')
@login_required
def logout():
    """User logout endpoint"""
    username = current_user.username  # Save username before logout
    logout_user()
    logger.info(f"User logged out: {username}")
    flash('You have been logged out successfully.', 'info')
    return redirect(url_for('index'))

@auth_bp.route('/profile')
@login_required
def profile():
    """User profile page"""
    return render_template('auth/profile.html', title='My Profile')

# Add other template-rendering auth routes like change_password, reset_password, login_history, etc.

@auth_bp.route('/change_password', methods=['GET', 'POST'])
@login_required
def change_password():
    """
    Change password endpoint for authenticated users
    Handles both form display and form submission
    """
    form = ChangePasswordForm()
    if form.validate_on_submit():
        if current_user.verify_password(form.current_password.data):
            current_user.password = form.new_password.data
            current_user.save_to_db()
            logger.info(f"Password changed for user: {current_user.username}")
            flash('Your password has been updated.', 'success')
            return redirect(url_for('auth.profile'))
        else:
            flash('Current password is incorrect.', 'danger')
    
    return render_template('auth/change_password.html', title='Change Password', form=form)

@auth_bp.route('/login_history')
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

@auth_bp.route('/reset-password-request', methods=['GET', 'POST'])
def reset_password_request():
    """Password reset request endpoint"""
    # If user is already logged in, redirect to home page
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    form = ResetPasswordRequestForm()
    if form.validate_on_submit():
        # Implementation would go here
        flash('Check your email for password reset instructions.', 'info')
        return redirect(url_for('auth.login'))
        
    return render_template('auth/reset_password_request.html', title='Reset Password', form=form)