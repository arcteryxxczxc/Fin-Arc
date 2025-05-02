#!/usr/bin/env python3
"""
Database connection test script for Fin-Arc application
This script tests the database connection and configuration
"""

import os
import sys
import psycopg2
from dotenv import load_dotenv
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

def test_postgresql_connection():
    """Test PostgreSQL database connection using environment variables"""
    logger.info("Testing PostgreSQL connection...")
    
    # Get connection parameters from environment
    db_user = os.environ.get('DB_USER', 'postgres')
    db_password = os.environ.get('DB_PASSWORD', 'postgres')
    db_host = os.environ.get('DB_HOST', 'localhost')
    db_port = os.environ.get('DB_PORT', '5432')
    db_name = os.environ.get('DB_NAME', 'fin_arc')
    
    # Direct database URL if provided
    db_url = os.environ.get('DATABASE_URL')
    
    if db_url:
        logger.info(f"Using DATABASE_URL environment variable")
        # Extract connection parameters from URL
        try:
            # Example format: postgresql://username:password@localhost:5432/database
            if db_url.startswith('postgresql://'):
                params_str = db_url.split('://')[-1]
                user_pass, host_port_db = params_str.split('@', 1)
                
                if ':' in user_pass:
                    db_user, db_password = user_pass.split(':', 1)
                else:
                    db_user = user_pass
                    db_password = ''
                
                if '/' in host_port_db:
                    host_port, db_name = host_port_db.split('/', 1)
                    
                    if ':' in host_port:
                        db_host, db_port = host_port.split(':', 1)
                    else:
                        db_host = host_port
                        db_port = '5432'
        except Exception as e:
            logger.error(f"Error parsing DATABASE_URL: {str(e)}")
    
    # Display connection parameters (without password)
    logger.info(f"Connection parameters:")
    logger.info(f"Host: {db_host}")
    logger.info(f"Port: {db_port}")
    logger.info(f"Database: {db_name}")
    logger.info(f"User: {db_user}")
    
    try:
        # Attempt to connect to the database
        conn = psycopg2.connect(
            host=db_host,
            port=db_port,
            dbname=db_name,
            user=db_user,
            password=db_password
        )
        
        # Get server version
        cursor = conn.cursor()
        cursor.execute('SELECT version();')
        version = cursor.fetchone()[0]
        
        # Count tables
        cursor.execute("""
            SELECT count(*) FROM information_schema.tables 
            WHERE table_schema = 'public';
        """)
        table_count = cursor.fetchone()[0]
        
        # Close connection
        cursor.close()
        conn.close()
        
        logger.info("✅ Database connection successful!")
        logger.info(f"PostgreSQL version: {version}")
        logger.info(f"Number of tables in database: {table_count}")
        
        return True
    except Exception as e:
        logger.error(f"❌ Database connection failed: {str(e)}")
        
        # Provide additional troubleshooting information
        if "password authentication failed" in str(e):
            logger.error("""
            HINT: Your password is incorrect. Check your DB_PASSWORD in .env file.
            If using 'postgres' as both username and password, make sure this matches your PostgreSQL installation.
            """)
        elif "does not exist" in str(e) and db_name in str(e):
            logger.error(f"""
            HINT: Database '{db_name}' does not exist. Create it with:
            
            createdb {db_name}
            
            Or using psql:
            
            psql -U {db_user} -c "CREATE DATABASE {db_name};"
            """)
        elif "Connection refused" in str(e):
            logger.error("""
            HINT: PostgreSQL server is not running or not accepting connections.
            Make sure PostgreSQL service is started:
            
            Windows: Open Services app and start PostgreSQL service
            Mac: brew services start postgresql
            Linux: sudo service postgresql start
            """)
        
        return False

if __name__ == "__main__":
    print("\n" + "="*50)
    print(" Fin-Arc Database Connection Test ".center(50, "="))
    print("="*50 + "\n")
    
    test_postgresql_connection()
    
    print("\nTest completed. Check logs for details.")