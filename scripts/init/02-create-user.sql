-- Create database users for Van Edu Premium Subscription Platform
-- This runs after database creation

-- Create the application user for backend connection
CREATE USER IF NOT EXISTS 'van_edu_app'@'%' IDENTIFIED BY 'van_edu_app_2024!';

-- Grant necessary privileges on the application database
GRANT SELECT, INSERT, UPDATE, DELETE ON van_edu_db.* TO 'van_edu_app'@'%';

-- Grant specific privileges for routine operations
GRANT CREATE TEMPORARY TABLES ON van_edu_db.* TO 'van_edu_app'@'%';
GRANT LOCK TABLES ON van_edu_db.* TO 'van_edu_app'@'%';

-- Grant EXECUTE privilege for stored procedures (if any)
GRANT EXECUTE ON van_edu_db.* TO 'van_edu_app'@'%';

-- Create read-only user for analytics and reporting
CREATE USER IF NOT EXISTS 'van_edu_readonly'@'%' IDENTIFIED BY 'readonly_secure_2024!';
GRANT SELECT ON van_edu_db.* TO 'van_edu_readonly'@'%';

-- Create backup user for automated backups
CREATE USER IF NOT EXISTS 'van_edu_backup'@'%' IDENTIFIED BY 'backup_secure_2024!';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON van_edu_db.* TO 'van_edu_backup'@'%';

-- Create admin user for database management
CREATE USER IF NOT EXISTS 'van_edu_admin'@'%' IDENTIFIED BY 'admin_secure_2024!';
GRANT ALL PRIVILEGES ON van_edu_db.* TO 'van_edu_admin'@'%';

-- Flush privileges to ensure changes take effect
FLUSH PRIVILEGES;

-- Display created users
SELECT User, Host FROM mysql.user WHERE User LIKE 'van_edu_%'; 