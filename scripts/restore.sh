#!/bin/bash

# Van Edu Database Restore Script
# This script restores database from encrypted backups

set -e

# Configuration
CONTAINER_NAME="van-edu-mysql"
DB_NAME="van_edu_db"
BACKUP_DIR="/backups"
ENCRYPTION_KEY=${BACKUP_ENCRYPTION_KEY:-""}

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

# List available backups
list_backups() {
    info "Available backups in $BACKUP_DIR:"
    echo ""
    
    local backups=$(find "$BACKUP_DIR" -name "van_edu_backup_*.sql*" -type f | sort -r)
    
    if [ -z "$backups" ]; then
        warn "No backups found in $BACKUP_DIR"
        return 1
    fi
    
    local i=1
    for backup in $backups; do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c %y "$backup" | cut -d'.' -f1)
        echo "$i) $filename (Size: $size, Created: $date)"
        i=$((i+1))
    done
    echo ""
}

# Select backup file
select_backup() {
    if [ -n "$1" ]; then
        # Backup file provided as argument
        BACKUP_FILE="$1"
        if [ ! -f "$BACKUP_FILE" ]; then
            error "Backup file not found: $BACKUP_FILE"
            exit 1
        fi
    else
        # Interactive selection
        list_backups
        
        local backups_array=($(find "$BACKUP_DIR" -name "van_edu_backup_*.sql*" -type f | sort -r))
        
        if [ ${#backups_array[@]} -eq 0 ]; then
            error "No backups available for restore"
            exit 1
        fi
        
        echo -n "Select backup to restore (1-${#backups_array[@]}): "
        read selection
        
        if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#backups_array[@]} ]; then
            error "Invalid selection"
            exit 1
        fi
        
        BACKUP_FILE="${backups_array[$((selection-1))]}"
    fi
    
    log "Selected backup: $(basename "$BACKUP_FILE")"
}

# Verify backup file
verify_backup() {
    log "Verifying backup file integrity..."
    
    if [[ "$BACKUP_FILE" == *.gz ]]; then
        if ! gzip -t "$BACKUP_FILE"; then
            error "Backup file is corrupted or invalid"
            exit 1
        fi
        log "Backup file integrity verified"
    fi
}

# Prepare backup for restore
prepare_backup() {
    local temp_dir="/tmp/van_edu_restore_$$"
    mkdir -p "$temp_dir"
    
    local working_file="$BACKUP_FILE"
    
    # Decompress if needed
    if [[ "$working_file" == *.gz ]]; then
        log "Decompressing backup..."
        working_file="$temp_dir/$(basename "$BACKUP_FILE" .gz)"
        gunzip -c "$BACKUP_FILE" > "$working_file"
    fi
    
    # Decrypt if needed
    if [[ "$working_file" == *.enc ]]; then
        if [ -z "$ENCRYPTION_KEY" ]; then
            error "Backup is encrypted but no encryption key provided"
            error "Set BACKUP_ENCRYPTION_KEY environment variable"
            rm -rf "$temp_dir"
            exit 1
        fi
        
        log "Decrypting backup..."
        local decrypted_file="$temp_dir/$(basename "$working_file" .enc)"
        openssl enc -aes-256-cbc -d -in "$working_file" -out "$decrypted_file" -k "$ENCRYPTION_KEY"
        
        if [ $? -ne 0 ]; then
            error "Failed to decrypt backup. Check your encryption key."
            rm -rf "$temp_dir"
            exit 1
        fi
        
        working_file="$decrypted_file"
    fi
    
    RESTORE_FILE="$working_file"
    TEMP_DIR="$temp_dir"
    log "Backup prepared for restore: $RESTORE_FILE"
}

# Create database backup before restore
create_pre_restore_backup() {
    if [ "$SKIP_BACKUP" = false ]; then
        log "Creating backup before restore..."
        local backup_script="$(dirname "$0")/backup.sh"
        
        if [ -f "$backup_script" ]; then
            $backup_script --no-cleanup
            log "Pre-restore backup completed"
        else
            warn "Backup script not found, skipping pre-restore backup"
        fi
    else
        warn "Skipping pre-restore backup as requested"
    fi
}

# Confirm restore operation
confirm_restore() {
    if [ "$FORCE_RESTORE" = true ]; then
        return 0
    fi
    
    warn "This operation will replace all data in the '$DB_NAME' database!"
    warn "Backup file: $(basename "$BACKUP_FILE")"
    echo -n "Are you sure you want to continue? (yes/no): "
    read confirmation
    
    if [ "$confirmation" != "yes" ]; then
        log "Restore operation cancelled"
        cleanup
        exit 0
    fi
}

# Perform database restore
restore_database() {
    log "Starting database restore..."
    
    # Import the backup
    docker exec -i $CONTAINER_NAME mysql \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} < "$RESTORE_FILE"
    
    if [ $? -eq 0 ]; then
        log "Database restore completed successfully"
    else
        error "Database restore failed"
        cleanup
        exit 1
    fi
}

# Cleanup temporary files
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        log "Cleaned up temporary files"
    fi
}

# Verify restore
verify_restore() {
    log "Verifying restore..."
    
    # Check if database exists and has tables
    local table_count=$(docker exec $CONTAINER_NAME mysql \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';" \
        --silent --skip-column-names)
    
    if [ "$table_count" -gt 0 ]; then
        log "Restore verification successful. Found $table_count tables in database."
    else
        error "Restore verification failed. No tables found in database."
        exit 1
    fi
}

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS] [BACKUP_FILE]"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -f, --force        Skip confirmation prompt"
    echo "  -l, --list         List available backups and exit"
    echo "  --skip-backup      Skip creating backup before restore"
    echo ""
    echo "Arguments:"
    echo "  BACKUP_FILE        Path to backup file (optional, will prompt if not provided)"
    echo ""
    echo "Environment variables:"
    echo "  BACKUP_ENCRYPTION_KEY  Key for decrypting backups"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive backup selection"
    echo "  $0 -f /backups/backup.sql.gz         # Force restore from specific file"
    echo "  $0 -l                                # List available backups"
    echo ""
}

# Main execution
main() {
    log "Starting Van Edu database restore process..."
    
    check_container
    select_backup "$BACKUP_FILE_ARG"
    verify_backup
    prepare_backup
    create_pre_restore_backup
    confirm_restore
    restore_database
    verify_restore
    cleanup
    
    log "Database restore completed successfully!"
    info "Database '$DB_NAME' has been restored from: $(basename "$BACKUP_FILE")"
}

# Parse command line arguments
FORCE_RESTORE=false
SKIP_BACKUP=false
LIST_ONLY=false
BACKUP_FILE_ARG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -f|--force)
            FORCE_RESTORE=true
            shift
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        -*)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            BACKUP_FILE_ARG="$1"
            shift
            ;;
    esac
done

# Handle list-only mode
if [ "$LIST_ONLY" = true ]; then
    list_backups
    exit 0
fi

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run main function
main 