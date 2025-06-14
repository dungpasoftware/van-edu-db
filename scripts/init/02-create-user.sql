-- Create database users for Van Edu Premium Subscription Platform - PostgreSQL
-- This runs after database creation

-- Connect to the database
\c van_edu_db;

-- Create the application user for backend connection
CREATE USER van_edu_app WITH PASSWORD 'van_edu_app_2024!';

-- Grant necessary privileges on the application database
GRANT CONNECT ON DATABASE van_edu_db TO van_edu_app;
GRANT USAGE ON SCHEMA public TO van_edu_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO van_edu_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO van_edu_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO van_edu_app;

-- Grant privileges on future tables and sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO van_edu_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO van_edu_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO van_edu_app;

-- Create read-only user for analytics and reporting
CREATE USER van_edu_readonly WITH PASSWORD 'readonly_secure_2024!';

-- Grant read-only privileges
GRANT CONNECT ON DATABASE van_edu_db TO van_edu_readonly;
GRANT USAGE ON SCHEMA public TO van_edu_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO van_edu_readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO van_edu_readonly;

-- Grant privileges on future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO van_edu_readonly;

-- Create backup user for automated backups
CREATE USER van_edu_backup WITH PASSWORD 'backup_secure_2024!';

-- Grant backup privileges
GRANT CONNECT ON DATABASE van_edu_db TO van_edu_backup;
GRANT USAGE ON SCHEMA public TO van_edu_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO van_edu_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO van_edu_backup;

-- Grant privileges on future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO van_edu_backup;

-- Create admin user for database management
CREATE USER van_edu_admin WITH PASSWORD 'admin_secure_2024!';

-- Grant admin privileges (almost all privileges except superuser)
GRANT CONNECT ON DATABASE van_edu_db TO van_edu_admin;
GRANT ALL PRIVILEGES ON SCHEMA public TO van_edu_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO van_edu_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO van_edu_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO van_edu_admin;

-- Grant privileges on future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO van_edu_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO van_edu_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON FUNCTIONS TO van_edu_admin;

-- Allow admin to create/drop tables and manage schema
ALTER USER van_edu_admin CREATEDB;

-- Display created users
SELECT usename as "User", 
       CASE WHEN usesuper THEN 'Yes' ELSE 'No' END as "Superuser",
       CASE WHEN usecreatedb THEN 'Yes' ELSE 'No' END as "Create DB"
FROM pg_user 
WHERE usename LIKE 'van_edu_%' 
ORDER BY usename; 