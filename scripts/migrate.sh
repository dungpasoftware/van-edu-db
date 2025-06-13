#!/bin/bash

# Van Edu Database Migration Script
# This script applies database migrations

set -e

# Configuration
CONTAINER_NAME="van-edu-mysql"
DB_NAME="van_edu_db"
MIGRATIONS_DIR="./migrations"

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if container is running
check_container() {
    if ! docker ps | grep -q $CONTAINER_NAME; then
        error "MySQL container '$CONTAINER_NAME' is not running"
        exit 1
    fi
}

# Create migrations table if it doesn't exist
create_migrations_table() {
    log "Creating migrations table if it doesn't exist..."
    
    docker exec $CONTAINER_NAME mysql \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        -e "USE $DB_NAME; CREATE TABLE IF NOT EXISTS migrations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            migration VARCHAR(255) NOT NULL UNIQUE,
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_migration (migration)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"
    
    log "Migrations table ready"
}

# Get executed migrations
get_executed_migrations() {
    docker exec $CONTAINER_NAME mysql \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        -e "USE $DB_NAME; SELECT migration FROM migrations ORDER BY id;" \
        --silent --skip-column-names
}

# Check if migration was executed
is_migration_executed() {
    local migration_name="$1"
    local executed_migrations=$(get_executed_migrations)
    
    echo "$executed_migrations" | grep -q "^$migration_name$"
}

# Execute migration
execute_migration() {
    local migration_file="$1"
    local migration_name=$(basename "$migration_file" .sql)
    
    log "Executing migration: $migration_name"
    
    # Execute the migration SQL
    docker exec -i $CONTAINER_NAME mysql \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        $DB_NAME < "$migration_file"
    
    if [ $? -eq 0 ]; then
        # Record migration as executed
        docker exec $CONTAINER_NAME mysql \
            -u${MYSQL_USER} \
            -p${MYSQL_PASSWORD} \
            -e "USE $DB_NAME; INSERT INTO migrations (migration) VALUES ('$migration_name');"
        
        log "Migration $migration_name executed successfully"
    else
        error "Migration $migration_name failed"
        exit 1
    fi
}

# Run pending migrations
run_migrations() {
    if [ ! -d "$MIGRATIONS_DIR" ]; then
        warn "Migrations directory not found: $MIGRATIONS_DIR"
        return 0
    fi
    
    local migration_files=$(find "$MIGRATIONS_DIR" -name "*.sql" | sort)
    
    if [ -z "$migration_files" ]; then
        info "No migration files found"
        return 0
    fi
    
    log "Checking for pending migrations..."
    local pending_count=0
    
    for migration_file in $migration_files; do
        local migration_name=$(basename "$migration_file" .sql)
        
        if ! is_migration_executed "$migration_name"; then
            execute_migration "$migration_file"
            pending_count=$((pending_count + 1))
        else
            info "Migration already executed: $migration_name"
        fi
    done
    
    if [ $pending_count -eq 0 ]; then
        log "No pending migrations found"
    else
        log "Executed $pending_count migration(s)"
    fi
}

# List migration status
list_migrations() {
    info "Migration Status:"
    echo ""
    
    if [ ! -d "$MIGRATIONS_DIR" ]; then
        warn "Migrations directory not found: $MIGRATIONS_DIR"
        return 0
    fi
    
    local migration_files=$(find "$MIGRATIONS_DIR" -name "*.sql" | sort)
    local executed_migrations=$(get_executed_migrations)
    
    for migration_file in $migration_files; do
        local migration_name=$(basename "$migration_file" .sql)
        
        if echo "$executed_migrations" | grep -q "^$migration_name$"; then
            echo "✓ $migration_name (executed)"
        else
            echo "○ $migration_name (pending)"
        fi
    done
    echo ""
}

# Create new migration file
create_migration() {
    local migration_name="$1"
    
    if [ -z "$migration_name" ]; then
        error "Migration name is required"
        echo "Usage: $0 create <migration_name>"
        exit 1
    fi
    
    # Create migrations directory if it doesn't exist
    mkdir -p "$MIGRATIONS_DIR"
    
    # Generate filename with timestamp
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local filename="${timestamp}_${migration_name}.sql"
    local filepath="$MIGRATIONS_DIR/$filename"
    
    # Create migration template
    cat > "$filepath" << EOF
-- Migration: $migration_name
-- Created: $(date)

USE $DB_NAME;

-- Add your migration SQL here
-- Example:
-- ALTER TABLE users ADD COLUMN new_field VARCHAR(255) NULL;

-- Don't forget to add rollback instructions in comments:
-- Rollback: ALTER TABLE users DROP COLUMN new_field;
EOF
    
    log "Created migration file: $filepath"
    info "Edit the file to add your migration SQL"
}

# Show migration history
show_history() {
    info "Migration History:"
    echo ""
    
    docker exec $CONTAINER_NAME mysql \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        -e "USE $DB_NAME; SELECT id, migration, executed_at FROM migrations ORDER BY id DESC;" \
        --table
}

# Show usage
usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  run                Run pending migrations (default)"
    echo "  list               List migration status"
    echo "  history            Show migration history"
    echo "  create <name>      Create new migration file"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run pending migrations"
    echo "  $0 list                      # List migration status"
    echo "  $0 create add_user_avatar    # Create new migration"
    echo "  $0 history                   # Show migration history"
    echo ""
}

# Parse command line arguments
COMMAND="run"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        run|list|history|create)
            COMMAND="$1"
            shift
            ;;
        *)
            if [ "$COMMAND" = "create" ]; then
                MIGRATION_NAME="$1"
                shift
            else
                error "Unknown option: $1"
                usage
                exit 1
            fi
            ;;
    esac
done

# Main execution
main() {
    check_container
    create_migrations_table
    
    case $COMMAND in
        run)
            log "Running database migrations..."
            run_migrations
            log "Migration process completed"
            ;;
        list)
            list_migrations
            ;;
        history)
            show_history
            ;;
        create)
            create_migration "$MIGRATION_NAME"
            ;;
        *)
            error "Unknown command: $COMMAND"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main 