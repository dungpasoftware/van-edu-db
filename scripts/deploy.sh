#!/bin/bash

# Van Edu Premium Subscription Platform - Deployment Script
# This script sets up the complete database environment for production

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

# Check if .env file exists
check_env() {
    if [ ! -f .env ]; then
        print_error ".env file not found!"
        print_status "Creating .env from env.example..."
        cp env.example .env
        print_warning "Please edit .env file with your production configuration before continuing"
        exit 1
    fi
    print_status ".env file found"
}

# Load environment variables
load_env() {
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
        print_status "Environment variables loaded"
    fi
}

# Create additional users
create_users() {
    print_header "Creating additional database users..."
    
    # Create users
    print_status "Creating van_edu_readonly user..."
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "CREATE USER van_edu_readonly WITH PASSWORD '${DB_READONLY_PASSWORD}';" 2>/dev/null || print_warning "User van_edu_readonly already exists"
    
    print_status "Creating van_edu_backup user..."
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "CREATE USER van_edu_backup WITH PASSWORD '${DB_BACKUP_PASSWORD}';" 2>/dev/null || print_warning "User van_edu_backup already exists"
    
    print_status "Creating van_edu_admin user..."
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "CREATE USER van_edu_admin WITH PASSWORD '${DB_ADMIN_PASSWORD}';" 2>/dev/null || print_warning "User van_edu_admin already exists"
    
    # Set permissions for readonly user
    print_status "Setting up permissions for van_edu_readonly..."
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO van_edu_readonly;"
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "GRANT USAGE ON SCHEMA public TO van_edu_readonly;"
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO van_edu_readonly;"
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO van_edu_readonly;"
    
    # Set permissions for backup user
    print_status "Setting up permissions for van_edu_backup..."
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO van_edu_backup;"
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "GRANT USAGE ON SCHEMA public TO van_edu_backup;"
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO van_edu_backup;"
    
    # Set permissions for admin user
    print_status "Setting up permissions for van_edu_admin..."
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO van_edu_admin;"
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "GRANT USAGE ON SCHEMA public TO van_edu_admin;"
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO van_edu_admin;"
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO van_edu_admin;"
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO van_edu_admin;"
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO van_edu_admin;"
    
    print_status "Database users created and configured successfully"
}

# Test connections
test_connections() {
    print_header "Testing database connections..."
    
    echo "Testing van_edu_app connection..."
    docker exec van-edu-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 'van_edu_app: ✅ Connected' as status;" 2>/dev/null || echo "van_edu_app: ❌ Failed"
    
    echo "Testing van_edu_readonly connection..."
    docker exec van-edu-postgres psql -U van_edu_readonly -d ${POSTGRES_DB} -c "SELECT 'van_edu_readonly: ✅ Connected' as status;" 2>/dev/null || echo "van_edu_readonly: ❌ Failed"
    
    echo "Testing van_edu_admin connection..."
    docker exec van-edu-postgres psql -U van_edu_admin -d ${POSTGRES_DB} -c "SELECT 'van_edu_admin: ✅ Connected' as status;" 2>/dev/null || echo "van_edu_admin: ❌ Failed"
    
    echo "Testing van_edu_backup connection..."
    docker exec van-edu-postgres psql -U van_edu_backup -d ${POSTGRES_DB} -c "SELECT 'van_edu_backup: ✅ Connected' as status;" 2>/dev/null || echo "van_edu_backup: ❌ Failed"
    
    print_status "Connection tests completed"
}

# Handle command line arguments
case "${1:-users-only}" in
    "users-only")
        load_env
        create_users
        test_connections
        ;;
    "test")
        load_env
        test_connections
        ;;
    "help")
        echo "Van Edu Deployment Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  users-only  Create users and permissions only (default)"
        echo "  test        Test database connections"
        echo "  help        Show this help message"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 