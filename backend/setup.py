#!/usr/bin/env python3
"""
Setup script for Fin-Arc backend
- Tests database connection
- Creates database if needed
- Initializes database tables and sample data
- Performs basic API tests
"""

import os
import sys
import subprocess
import logging
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

def run_command(command, description):
    """Run a system command and log the result"""
    logger.info(f"Running: {description}")
    try:
        result = subprocess.run(
            command,
            shell=True,
            check=True,
            capture_output=True,
            text=True
        )
        logger.info(f"✅ Success: {description}")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"❌ Failed: {description}")
        logger.error(f"Error: {e.stderr}")
        return False

def create_database():
    """Create the database if it doesn't exist"""
    db_user = os.environ.get('DB_USER', 'postgres')
    db_name = os.environ.get('DB_NAME', 'fin_arc')
    
    # Check if database exists
    check_cmd = f"psql -U {db_user} -lqt | cut -d \\| -f 1 | grep -w {db_name}"
    try:
        result = subprocess.run(
            check_cmd,
            shell=True,
            capture_output=True,
            text=True
        )
        
        if db_name in result.stdout:
            logger.info(f"Database '{db_name}' already exists")
            return True
        else:
            # Create database
            create_cmd = f"createdb -U {db_user} {db_name}"
            return run_command(create_cmd, f"Creating database '{db_name}'")
    except subprocess.CalledProcessError:
        logger.error("Failed to check database existence")
        return False

def main():
    """Main setup function"""
    print("\n" + "="*50)
    print(" Fin-Arc Backend Setup ".center(50, "="))
    print("="*50 + "\n")
    
    # Check if PostgreSQL is installed
    if not run_command("psql --version", "Checking PostgreSQL installation"):
        logger.error("PostgreSQL not found. Please install PostgreSQL first.")
        return False
    
    # Check if .env file exists
    if not os.path.exists('.env'):
        logger.error(".env file not found. Please create it first.")
        return False
    
    # Test database connection
    logger.info("Testing database connection...")
    test_result = run_command("python db_test.py", "Testing database connection")
    
    if not test_result:
        # Try to create the database
        if not create_database():
            logger.error("Failed to create database. Please check PostgreSQL configuration.")
            return False
        
        # Test connection again
        test_result = run_command("python db_test.py", "Re-testing database connection")
        if not test_result:
            logger.error("Database connection still failing. Please check your .env file.")
            return False
    
    # Initialize database with tables and sample data
    if not run_command("python init_db.py", "Initializing database"):
        logger.error("Failed to initialize database.")
        return False
    
    # Run diagnostic tests
    run_command("python flask_diagnostic.py", "Running API diagnostics")
    
    # Start the Flask server
    logger.info("\n🎉 Setup completed successfully! You can now start the server with:")
    logger.info("python run.py")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)