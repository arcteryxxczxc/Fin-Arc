#!/usr/bin/env python3
"""
This script runs a series of health checks on the Flask backend.
It will test database connectivity, API endpoints, and authentication flows.
Usage: python flask_diagnostic.py

"""

import sys
import os
import json
import requests
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f"finarc_diagnostic_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger("fin-arc-diagnostics")

# Configuration
BASE_URL = "http://localhost:8111/api"
TEST_USERNAME = "test_diagnostic_user"
TEST_EMAIL = "test_diagnostic@gmail.com"
TEST_PASSWORD = "Test12345!"

def print_header(title):
    """Print a formatted header to the console"""
    logger.info("\n" + "=" * 50)
    logger.info(f" {title} ".center(50, "="))
    logger.info("=" * 50)

def test_server_connectivity():
    """Test if the server is running and accessible"""
    print_header("Testing Server Connectivity")
    try:
        response = requests.get(f"{BASE_URL}")
        logger.info(f"Server response: Status {response.status_code}")
        if response.status_code == 404:
            logger.info("Status 404 is expected for the base endpoint, that's OK.")
            return True
        elif 200 <= response.status_code < 300:
            logger.info("Server is running and accessible!")
            return True
        else:
            logger.error(f"Unexpected status code: {response.status_code}")
            return False
    except requests.RequestException as e:
        logger.error(f"Connection error: {e}")
        logger.error("Make sure the Flask server is running on localhost:8111")
        return False

def test_authentication_flow():
    """Test the complete authentication flow"""
    print_header("Testing Authentication Flow")
    
    # Step 1: Register a test user
    logger.info("Step 1: Registering a test user")
    register_payload = {
        "username": TEST_USERNAME,
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD,
        "first_name": "Test",
        "last_name": "User"
    }
    
    try:
        register_response = requests.post(
            f"{BASE_URL}/auth/register",
            json=register_payload,
            headers={"Content-Type": "application/json"}
        )
        
        logger.info(f"Register response status: {register_response.status_code}")
        logger.info(f"Register response: {register_response.text[:200]}...")
        
        if 200 <= register_response.status_code < 300:
            logger.info("Registration successful")
            register_data = register_response.json()
            access_token = register_data.get("access_token")
            refresh_token = register_data.get("refresh_token")
            
            if not access_token or not refresh_token:
                logger.error("Missing tokens in registration response")
                return False
        elif register_response.status_code == 409:
            logger.info("User already exists, proceeding to login")
            access_token = None
            refresh_token = None
        else:
            logger.error(f"Registration failed: {register_response.text}")
            return False
    except requests.RequestException as e:
        logger.error(f"Registration connection error: {e}")
        return False
    
    # Step 2: Login with the test user
    logger.info("\nStep 2: Logging in with test user")
    login_payload = {
        "username": TEST_USERNAME,
        "password": TEST_PASSWORD
    }
    
    try:
        login_response = requests.post(
            f"{BASE_URL}/auth/login",
            json=login_payload,
            headers={"Content-Type": "application/json"}
        )
        
        logger.info(f"Login response status: {login_response.status_code}")
        logger.info(f"Login response: {login_response.text[:200]}...")
        
        if 200 <= login_response.status_code < 300:
            logger.info("Login successful")
            login_data = login_response.json()
            access_token = login_data.get("access_token")
            refresh_token = login_data.get("refresh_token")
            
            if not access_token or not refresh_token:
                logger.error("Missing tokens in login response")
                return False
        else:
            logger.error(f"Login failed: {login_response.text}")
            return False
    except requests.RequestException as e:
        logger.error(f"Login connection error: {e}")
        return False
    
    # Step 3: Get user profile
    logger.info("\nStep 3: Getting user profile")
    try:
        profile_response = requests.get(
            f"{BASE_URL}/auth/profile",
            headers={"Authorization": f"Bearer {access_token}"}
        )
        
        logger.info(f"Profile response status: {profile_response.status_code}")
        logger.info(f"Profile response: {profile_response.text[:200]}...")
        
        if 200 <= profile_response.status_code < 300:
            logger.info("Profile retrieval successful")
        else:
            logger.error(f"Profile retrieval failed: {profile_response.text}")
            return False
    except requests.RequestException as e:
        logger.error(f"Profile connection error: {e}")
        return False
    
    # Step 4: Test token refresh
    logger.info("\nStep 4: Testing token refresh")
    try:
        refresh_response = requests.post(
            f"{BASE_URL}/auth/refresh",
            headers={"Authorization": f"Bearer {refresh_token}"}
        )
        
        logger.info(f"Refresh response status: {refresh_response.status_code}")
        logger.info(f"Refresh response: {refresh_response.text[:200]}...")
        
        if 200 <= refresh_response.status_code < 300:
            logger.info("Token refresh successful")
            refresh_data = refresh_response.json()
            new_access_token = refresh_data.get("access_token")
            
            if not new_access_token:
                logger.error("Missing access token in refresh response")
                return False
            
            # Verify new token works
            verify_response = requests.get(
                f"{BASE_URL}/auth/profile",
                headers={"Authorization": f"Bearer {new_access_token}"}
            )
            
            if 200 <= verify_response.status_code < 300:
                logger.info("New token verification successful")
            else:
                logger.error(f"New token verification failed: {verify_response.text}")
                return False
        else:
            logger.error(f"Token refresh failed: {refresh_response.text}")
            return False
    except requests.RequestException as e:
        logger.error(f"Refresh connection error: {e}")
        return False
    
    # Step 5: Logout
    logger.info("\nStep 5: Testing logout")
    try:
        logout_response = requests.post(
            f"{BASE_URL}/auth/logout",
            headers={"Authorization": f"Bearer {access_token}"}
        )
        
        logger.info(f"Logout response status: {logout_response.status_code}")
        logger.info(f"Logout response: {logout_response.text[:200]}...")
        
        if 200 <= logout_response.status_code < 300:
            logger.info("Logout successful")
        else:
            logger.error(f"Logout failed: {logout_response.text}")
            return False
    except requests.RequestException as e:
        logger.error(f"Logout connection error: {e}")
        return False
    
    logger.info("\nAuthentication flow test completed successfully!")
    return True

def test_api_endpoints():
    """Test key API endpoints"""
    print_header("Testing API Endpoints")
    
    # Login first to get a token
    login_payload = {
        "username": TEST_USERNAME,
        "password": TEST_PASSWORD
    }
    
    try:
        login_response = requests.post(
            f"{BASE_URL}/auth/login",
            json=login_payload,
            headers={"Content-Type": "application/json"}
        )
        
        if 200 <= login_response.status_code < 300:
            login_data = login_response.json()
            access_token = login_data.get("access_token")
        else:
            logger.error(f"Login failed for API endpoint tests: {login_response.text}")
            return False
    except requests.RequestException as e:
        logger.error(f"Login connection error: {e}")
        return False
    
    # Define endpoints to test
    endpoints = [
        {"method": "GET", "url": "/categories", "name": "Get Categories"},
        {"method": "GET", "url": "/expenses", "name": "Get Expenses"},
        {"method": "GET", "url": "/income", "name": "Get Income"},
        {"method": "GET", "url": "/reports/dashboard", "name": "Get Dashboard Data"}
    ]
    
    # Test each endpoint
    all_passed = True
    for endpoint in endpoints:
        logger.info(f"\nTesting: {endpoint['name']} - {endpoint['method']} {endpoint['url']}")
        
        try:
            if endpoint["method"] == "GET":
                response = requests.get(
                    f"{BASE_URL}{endpoint['url']}",
                    headers={"Authorization": f"Bearer {access_token}"}
                )
            elif endpoint["method"] == "POST":
                response = requests.post(
                    f"{BASE_URL}{endpoint['url']}",
                    headers={"Authorization": f"Bearer {access_token}"}
                )
            
            logger.info(f"Response status: {response.status_code}")
            
            if 200 <= response.status_code < 300:
                logger.info(f"{endpoint['name']} - Success!")
                # Log a sample of the response
                try:
                    response_json = response.json()
                    sample = json.dumps(response_json, indent=2)[:200] + "..."
                    logger.info(f"Sample response: {sample}")
                except:
                    logger.info(f"Response: {response.text[:200]}...")
            else:
                logger.error(f"{endpoint['name']} - Failed with status {response.status_code}")
                logger.error(f"Response: {response.text}")
                all_passed = False
        except requests.RequestException as e:
            logger.error(f"Connection error for {endpoint['name']}: {e}")
            all_passed = False
    
    if all_passed:
        logger.info("\nAll API endpoint tests passed!")
    else:
        logger.error("\nSome API endpoint tests failed!")
    
    return all_passed

def check_flask_logs():
    """Check for Flask log files"""
    print_header("Checking Flask Logs")
    
    log_paths = [
        "./flask.log",
        "./error.log",
        "./app.log",
        "./logs/flask.log",
        "./logs/error.log",
        "./logs/app.log"
    ]
    
    found_logs = False
    for log_path in log_paths:
        if os.path.exists(log_path):
            logger.info(f"Found log file: {log_path}")
            found_logs = True
            
            # Read the last 10 lines
            try:
                with open(log_path, 'r') as f:
                    lines = f.readlines()
                    last_lines = lines[-min(10, len(lines)):]
                    logger.info(f"Last {len(last_lines)} lines:")
                    for line in last_lines:
                        logger.info(f"  {line.strip()}")
            except Exception as e:
                logger.error(f"Error reading log file: {e}")
    
    if not found_logs:
        logger.warning("No Flask log files found in standard locations!")
        logger.info("Tips for finding Flask logs:")
        logger.info("1. Check your Flask app configuration for the log file location")
        logger.info("2. Look for environment variables that might specify log paths")
        logger.info("3. Check the console output where Flask is running")
    
    return found_logs

def run_diagnostics():
    """Run all diagnostic tests"""
    print_header("Fin-Arc Flask Backend Diagnostics")
    logger.info(f"Starting diagnostics at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Step 1: Test server connectivity
    if not test_server_connectivity():
        logger.error("Server connectivity test failed, aborting further tests.")
        return False
    
    # Step 2: Test authentication flow
    auth_result = test_authentication_flow()
    
    # Step 3: Test API endpoints
    api_result = test_api_endpoints()
    
    # Step 4: Check logs
    log_result = check_flask_logs()
    
    # Print summary
    print_header("Diagnostic Results Summary")
    logger.info(f"Server Connectivity: {'PASS' if True else 'FAIL'}")
    logger.info(f"Authentication Flow: {'PASS' if auth_result else 'FAIL'}")
    logger.info(f"API Endpoints: {'PASS' if api_result else 'FAIL'}")
    logger.info(f"Found Log Files: {'YES' if log_result else 'NO'}")
    
    if auth_result and api_result:
        logger.info("\nCore functionality tests PASSED!")
        return True
    else:
        logger.error("\nSome tests FAILED!")
        return False

def database_connection_test():
    """Optional PostgreSQL connection test"""
    print_header("Testing Database Connection")
    
    try:
        import psycopg2
        from psycopg2 import OperationalError
    except ImportError:
        logger.error("psycopg2 library not installed. Install using: pip install psycopg2-binary")
        return False
    
    # Get connection details from environment or use defaults
    db_host = os.environ.get("DB_HOST", "localhost")
    db_name = os.environ.get("DB_NAME", "fin_arc")
    db_user = os.environ.get("DB_USER", "postgres")
    db_password = os.environ.get("DB_PASSWORD", "")
    db_port = os.environ.get("DB_PORT", "5432")
    
    logger.info(f"Attempting to connect to PostgreSQL database:")
    logger.info(f"Host: {db_host}, Port: {db_port}, DB: {db_name}, User: {db_user}")
    
    try:
        # Connect to the database
        connection = psycopg2.connect(
            host=db_host,
            database=db_name,
            user=db_user,
            password=db_password,
            port=db_port
        )
        
        # Create a cursor object
        cursor = connection.cursor()
        
        # Execute test query with encoding handling
        cursor.execute("SELECT version();")
        
        # Retrieve query result and handle encoding issues
        try:
            db_version = cursor.fetchone()
            if db_version and db_version[0]:
                version_str = str(db_version[0])
                logger.info(f"PostgreSQL Database Version: {version_str}")
            else:
                logger.info("Connected to database but couldn't retrieve version")
        except UnicodeDecodeError:
            logger.info("Connected to database successfully (version string contains non-UTF8 characters)")
        
        # Test database schema with error handling
        logger.info("\nChecking database schema...")
        try:
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
                ORDER BY table_name;
            """)
            tables = cursor.fetchall()
            logger.info("Database tables:")
            for table in tables:
                logger.info(f"  - {table[0]}")
        except Exception as e:
            logger.warning(f"Could not query database tables: {e}")
        
        # Check user table with error handling
        logger.info("\nChecking 'users' table (if exists)...")
        try:
            cursor.execute("SELECT COUNT(*) FROM users;")
            user_count = cursor.fetchone()[0]
            logger.info(f"User count: {user_count}")
        except Exception as e:
            logger.warning(f"Could not query users table: {e}")
        
        # Close cursor and connection
        cursor.close()
        connection.close()
        logger.info("Database connection test successful!")
        return True
    
    except OperationalError as e:
        logger.error(f"Database connection error: {e}")
        logger.error("Tips for resolving database connection issues:")
        logger.error("1. Ensure the PostgreSQL service is running")
        logger.error("2. Verify the database credentials and connection details")
        logger.error("3. Check network access and firewall settings")
        return False
    except Exception as e:
        logger.error(f"Error during database test: {e}")
        return False

if __name__ == "__main__":
    try:
        # Run the main diagnostics
        diagnostics_result = run_diagnostics()
        
        # Offer to run database test
        print("\nWould you like to run database connection test? (y/n)")
        if input().lower() == 'y':
            database_connection_test()
        
        print("\nDiagnostics completed! Check the log file for detailed results.")
        
        sys.exit(0 if diagnostics_result else 1)
    except KeyboardInterrupt:
        print("\nDiagnostics interrupted by user.")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Unhandled exception in diagnostic script: {e}")
        sys.exit(1)