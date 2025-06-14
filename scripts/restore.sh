#!/bin/bash

# Van Edu Premium Subscription Platform - PostgreSQL Restore Script
# Restores encrypted, compressed backups with safety checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Configuration
BACKUP_DIR="./backups"
CONTAINER_NAME="van-edu-postgres"
ENCRYPTION_KEY=${BACKUP_ENCRYPTION_KEY:-"van_edu_backup_key_2024"}

# Command line options
FORCE_RESTORE=false
LIST_BACKUPS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_RESTORE=true
            shift
            ;;
        -l|--list)
            LIST_BACKUPS=true
            shift
            ;;
        -h|--help)
            echo "Van Edu Premium Subscription Platform - PostgreSQL Restore Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --force    Force restore from latest backup without confirmation"
            echo "  -l, --list     List available backups and exit"
            echo "  -h, --help     Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🔄 Van Edu Premium Subscription Platform - PostgreSQL Restore${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Function to list available backups
list_backups() {
    echo -e "${BLUE}📁 Available Backups:${NC}"
    if ls "$BACKUP_DIR"/van_edu_backup_*.sql.gz.enc >/dev/null 2>&1; then
        local count=0
        for backup in "$BACKUP_DIR"/van_edu_backup_*.sql.gz.enc; do
            if [ -f "$backup" ]; then
                ((count++))
                SIZE=$(du -h "$backup" | cut -f1)
                DATE=$(stat -c %y "$backup" | cut -d' ' -f1,2 | cut -d'.' -f1)
                echo "  $count. $(basename "$backup") - $SIZE - $DATE"
            fi
        done
        return $count
    else
        echo "  No backups found in $BACKUP_DIR"
        return 0
    fi
}

# If list option is specified, show backups and exit
if [ "$LIST_BACKUPS" = true ]; then
    list_backups
    exit 0
fi

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}❌ Error: PostgreSQL container '$CONTAINER_NAME' is not running${NC}"
    echo "Please start the container first: make up"
    exit 1
fi

# Check if database is accessible
if ! docker exec "$CONTAINER_NAME" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Cannot connect to PostgreSQL database${NC}"
    exit 1
fi

# List available backups
list_backups
BACKUP_COUNT=$?

if [ $BACKUP_COUNT -eq 0 ]; then
    echo -e "${RED}❌ No backups found. Please create a backup first.${NC}"
    exit 1
fi

# Select backup to restore
if [ "$FORCE_RESTORE" = true ]; then
    # Use the latest backup
    SELECTED_BACKUP=$(ls -t "$BACKUP_DIR"/van_edu_backup_*.sql.gz.enc | head -n 1)
    echo -e "${YELLOW}🔄 Force restore mode: Using latest backup${NC}"
    echo "  Selected: $(basename "$SELECTED_BACKUP")"
else
    # Interactive selection
    echo ""
    echo -e "${YELLOW}Please select a backup to restore (1-$BACKUP_COUNT):${NC}"
    read -p "Enter backup number: " BACKUP_NUMBER
    
    # Validate input
    if ! [[ "$BACKUP_NUMBER" =~ ^[0-9]+$ ]] || [ "$BACKUP_NUMBER" -lt 1 ] || [ "$BACKUP_NUMBER" -gt $BACKUP_COUNT ]; then
        echo -e "${RED}❌ Invalid backup number${NC}"
        exit 1
    fi
    
    # Get selected backup file
    SELECTED_BACKUP=$(ls -t "$BACKUP_DIR"/van_edu_backup_*.sql.gz.enc | sed -n "${BACKUP_NUMBER}p")
fi

if [ ! -f "$SELECTED_BACKUP" ]; then
    echo -e "${RED}❌ Selected backup file not found${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📋 Restore Configuration:${NC}"
echo "  Database: $POSTGRES_DB"
echo "  User: $POSTGRES_USER"
echo "  Container: $CONTAINER_NAME"
echo "  Backup File: $(basename "$SELECTED_BACKUP")"
echo "  Backup Size: $(du -h "$SELECTED_BACKUP" | cut -f1)"
echo ""

# Final confirmation unless force mode
if [ "$FORCE_RESTORE" = false ]; then
    echo -e "${RED}⚠️  WARNING: This will completely replace the current database!${NC}"
    echo -e "${RED}⚠️  All existing data will be lost!${NC}"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}❌ Restore cancelled${NC}"
        exit 0
    fi
fi

# Create a backup of current database before restore
echo -e "${YELLOW}💾 Creating backup of current database before restore...${NC}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PRE_RESTORE_BACKUP="$BACKUP_DIR/pre_restore_backup_${TIMESTAMP}.sql.gz.enc"

docker exec "$CONTAINER_NAME" pg_dump \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    --verbose \
    --no-password \
    --format=plain \
    --no-owner \
    --no-privileges \
    --clean \
    --if-exists \
    | gzip | openssl enc -aes-256-cbc -salt -k "$ENCRYPTION_KEY" > "$PRE_RESTORE_BACKUP"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Pre-restore backup created: $(basename "$PRE_RESTORE_BACKUP")${NC}"
else
    echo -e "${RED}❌ Warning: Failed to create pre-restore backup${NC}"
    if [ "$FORCE_RESTORE" = false ]; then
        read -p "Continue anyway? (yes/no): " CONTINUE
        if [ "$CONTINUE" != "yes" ]; then
            exit 1
        fi
    fi
fi

# Prepare temporary files
TEMP_DIR=$(mktemp -d)
TEMP_ENCRYPTED="$TEMP_DIR/backup.sql.gz.enc"
TEMP_COMPRESSED="$TEMP_DIR/backup.sql.gz"
TEMP_SQL="$TEMP_DIR/backup.sql"

# Copy backup to temp directory
cp "$SELECTED_BACKUP" "$TEMP_ENCRYPTED"

# Decrypt backup
echo -e "${YELLOW}🔓 Decrypting backup...${NC}"
if ! openssl enc -aes-256-cbc -d -in "$TEMP_ENCRYPTED" -out "$TEMP_COMPRESSED" -k "$ENCRYPTION_KEY"; then
    echo -e "${RED}❌ Error: Failed to decrypt backup. Check encryption key.${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo -e "${GREEN}✅ Backup decrypted${NC}"

# Decompress backup
echo -e "${YELLOW}📦 Decompressing backup...${NC}"
if ! gunzip -c "$TEMP_COMPRESSED" > "$TEMP_SQL"; then
    echo -e "${RED}❌ Error: Failed to decompress backup${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo -e "${GREEN}✅ Backup decompressed${NC}"

# Verify SQL file
echo -e "${YELLOW}🔍 Verifying backup file...${NC}"
if ! head -n 5 "$TEMP_SQL" | grep -q "PostgreSQL\|--"; then
    echo -e "${RED}❌ Error: Backup file doesn't appear to be a valid PostgreSQL dump${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo -e "${GREEN}✅ Backup file verified${NC}"

# Restore database
echo -e "${YELLOW}🔄 Restoring database...${NC}"
echo "This may take a few minutes depending on the database size..."

if docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 < "$TEMP_SQL"; then
    echo -e "${GREEN}✅ Database restored successfully${NC}"
else
    echo -e "${RED}❌ Error: Database restore failed${NC}"
    echo -e "${YELLOW}💡 You can restore the pre-restore backup if needed:${NC}"
    echo "  Pre-restore backup: $(basename "$PRE_RESTORE_BACKUP")"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up temporary files
rm -rf "$TEMP_DIR"

# Verify restore
echo -e "${YELLOW}🔍 Verifying restored database...${NC}"
TABLE_COUNT=$(docker exec "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" | tr -d ' ')

if [ "$TABLE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Database verification successful${NC}"
    echo "  Tables found: $TABLE_COUNT"
else
    echo -e "${RED}❌ Warning: No tables found in restored database${NC}"
fi

# Show restore summary
echo ""
echo -e "${BLUE}📊 Restore Summary:${NC}"
echo "  Restored From: $(basename "$SELECTED_BACKUP")"
echo "  Database: $POSTGRES_DB"
echo "  Tables: $TABLE_COUNT"
echo "  Completed: $(date)"
echo "  Pre-restore backup: $(basename "$PRE_RESTORE_BACKUP")"
echo ""

echo -e "${GREEN}🎉 Database restore completed successfully!${NC}"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "  1. Verify your application works correctly"
echo "  2. Test critical functionality"
echo "  3. Remove pre-restore backup if everything is working:"
echo "     rm \"$PRE_RESTORE_BACKUP\"" 