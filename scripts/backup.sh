#!/bin/bash

# Van Edu Database Backup Script
# This script creates encrypted backups with rotation

set -e

# Configuration
CONTAINER_NAME="van-edu-mysql"
DB_NAME="van_edu_db"
BACKUP_DIR="/backups"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
ENCRYPTION_KEY=${BACKUP_ENCRYPTION_KEY:-""}

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if container is running
check_container() {
    if ! docker ps | grep -q $CONTAINER_NAME; then
        error "MySQL container '$CONTAINER_NAME' is not running"
        exit 1
    fi
}

# Create backup directory if it doesn't exist
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log "Created backup directory: $BACKUP_DIR"
    fi
}

# Generate backup filename
generate_filename() {
    echo "van_edu_backup_$(date +%Y%m%d_%H%M%S).sql"
}

# Create database backup
create_backup() {
    local filename=$1
    local temp_file="$BACKUP_DIR/temp_$filename"
    local final_file="$BACKUP_DIR/$filename"
    
    log "Starting backup of database '$DB_NAME'..."
    
    # Create the backup
    docker exec $CONTAINER_NAME mysqldump \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --add-drop-database \
        --databases $DB_NAME > "$temp_file"
    
    if [ $? -eq 0 ]; then
        log "Database backup created successfully"
    else
        error "Failed to create database backup"
        rm -f "$temp_file"
        exit 1
    fi
    
    # Encrypt backup if encryption key is provided
    if [ -n "$ENCRYPTION_KEY" ]; then
        log "Encrypting backup..."
        openssl enc -aes-256-cbc -salt -in "$temp_file" -out "$final_file.enc" -k "$ENCRYPTION_KEY"
        if [ $? -eq 0 ]; then
            rm "$temp_file"
            final_file="$final_file.enc"
            log "Backup encrypted successfully"
        else
            error "Failed to encrypt backup"
            mv "$temp_file" "$final_file"
            warn "Backup saved without encryption"
        fi
    else
        mv "$temp_file" "$final_file"
        warn "No encryption key provided, backup saved without encryption"
    fi
    
    # Compress backup
    gzip "$final_file"
    final_file="$final_file.gz"
    
    log "Backup saved as: $final_file"
    log "Backup size: $(du -h "$final_file" | cut -f1)"
}

# Clean old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    
    find "$BACKUP_DIR" -name "van_edu_backup_*.sql*" -type f -mtime +$RETENTION_DAYS -delete
    
    local remaining=$(find "$BACKUP_DIR" -name "van_edu_backup_*.sql*" -type f | wc -l)
    log "Cleanup completed. $remaining backup files remaining."
}

# Verify backup integrity
verify_backup() {
    local backup_file=$1
    log "Verifying backup integrity..."
    
    if [[ "$backup_file" == *.gz ]]; then
        if gzip -t "$backup_file"; then
            log "Backup integrity verified"
        else
            error "Backup integrity check failed"
            exit 1
        fi
    fi
}

# Main execution
main() {
    log "Starting Van Edu database backup process..."
    
    check_container
    create_backup_dir
    
    local filename=$(generate_filename)
    create_backup "$filename"
    
    local final_backup="$BACKUP_DIR/$filename"
    if [ -n "$ENCRYPTION_KEY" ]; then
        final_backup="$final_backup.enc"
    fi
    final_backup="$final_backup.gz"
    
    verify_backup "$final_backup"
    cleanup_old_backups
    
    log "Backup process completed successfully!"
    log "Backup location: $final_backup"
}

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --no-cleanup   Skip cleanup of old backups"
    echo ""
    echo "Environment variables:"
    echo "  BACKUP_RETENTION_DAYS  Number of days to keep backups (default: 30)"
    echo "  BACKUP_ENCRYPTION_KEY  Key for encrypting backups"
    echo ""
}

# Parse command line arguments
NO_CLEANUP=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        --no-cleanup)
            NO_CLEANUP=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run main function
if [ "$NO_CLEANUP" = true ]; then
    log "Skipping cleanup as requested"
    check_container
    create_backup_dir
    filename=$(generate_filename)
    create_backup "$filename"
    
    final_backup="$BACKUP_DIR/$filename"
    if [ -n "$ENCRYPTION_KEY" ]; then
        final_backup="$final_backup.enc"
    fi
    final_backup="$final_backup.gz"
    
    verify_backup "$final_backup"
    log "Backup completed without cleanup"
else
    main
fi 