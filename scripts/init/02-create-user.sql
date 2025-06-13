-- Create database user with limited privileges
-- This runs after database creation

-- Create the application user
CREATE USER IF NOT EXISTS 'van_edu_user'@'%' IDENTIFIED BY 'van_edu_secure_2024!';

-- Grant necessary privileges on the application database
GRANT SELECT, INSERT, UPDATE, DELETE ON van_edu_db.* TO 'van_edu_user'@'%';

-- Grant specific privileges for routine operations
GRANT CREATE TEMPORARY TABLES ON van_edu_db.* TO 'van_edu_user'@'%';
GRANT LOCK TABLES ON van_edu_db.* TO 'van_edu_user'@'%';

-- Grant EXECUTE privilege for stored procedures (if any)
GRANT EXECUTE ON van_edu_db.* TO 'van_edu_user'@'%';

-- Create read-only user for reporting/analytics
CREATE USER IF NOT EXISTS 'van_edu_readonly'@'%' IDENTIFIED BY 'readonly_secure_2024!';
GRANT SELECT ON van_edu_db.* TO 'van_edu_readonly'@'%';

-- Create backup user
CREATE USER IF NOT EXISTS 'van_edu_backup'@'%' IDENTIFIED BY 'backup_secure_2024!';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON van_edu_db.* TO 'van_edu_backup'@'%';

-- Flush privileges to ensure changes take effect
FLUSH PRIVILEGES;

-- Display created users
SELECT User, Host FROM mysql.user WHERE User LIKE 'van_edu_%'; 