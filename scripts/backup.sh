#!/bin/bash

# Van Edu Premium Subscription Platform - PostgreSQL Backup Script
# Creates encrypted, compressed backups with retention management

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
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
ENCRYPTION_KEY=${BACKUP_ENCRYPTION_KEY:-"van_edu_backup_key_2024"}
CLEANUP=${1:-"--cleanup"}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate backup filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="van_edu_backup_${TIMESTAMP}.sql"
COMPRESSED_FILE="${BACKUP_FILE}.gz"
ENCRYPTED_FILE="${COMPRESSED_FILE}.enc"

echo -e "${BLUE}🗄️  Van Edu Premium Subscription Platform - PostgreSQL Backup${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}❌ Error: PostgreSQL container '$CONTAINER_NAME' is not running${NC}"
    exit 1
fi

# Check if database is accessible
if ! docker exec "$CONTAINER_NAME" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Cannot connect to PostgreSQL database${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Backup Configuration:${NC}"
echo "  Database: $POSTGRES_DB"
echo "  User: $POSTGRES_USER"
echo "  Container: $CONTAINER_NAME"
echo "  Backup Directory: $BACKUP_DIR"
echo "  Retention: $RETENTION_DAYS days"
echo "  Encryption: Enabled (AES-256-CBC)"
echo ""

# Create database backup
echo -e "${YELLOW}🔄 Creating database backup...${NC}"
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
    > "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database backup created: $BACKUP_FILE${NC}"
else
    echo -e "${RED}❌ Error: Failed to create database backup${NC}"
    exit 1
fi

# Compress backup
echo -e "${YELLOW}🗜️  Compressing backup...${NC}"
gzip "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backup compressed: $COMPRESSED_FILE${NC}"
else
    echo -e "${RED}❌ Error: Failed to compress backup${NC}"
    exit 1
fi

# Encrypt backup
echo -e "${YELLOW}🔐 Encrypting backup...${NC}"
openssl enc -aes-256-cbc -salt -in "$BACKUP_DIR/$COMPRESSED_FILE" -out "$BACKUP_DIR/$ENCRYPTED_FILE" -k "$ENCRYPTION_KEY"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backup encrypted: $ENCRYPTED_FILE${NC}"
    # Remove unencrypted compressed file
    rm "$BACKUP_DIR/$COMPRESSED_FILE"
else
    echo -e "${RED}❌ Error: Failed to encrypt backup${NC}"
    exit 1
fi

# Get backup file size
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$ENCRYPTED_FILE" | cut -f1)
echo -e "${GREEN}📦 Final backup size: $BACKUP_SIZE${NC}"

# Verify backup integrity
echo -e "${YELLOW}🔍 Verifying backup integrity...${NC}"
if openssl enc -aes-256-cbc -d -in "$BACKUP_DIR/$ENCRYPTED_FILE" -k "$ENCRYPTION_KEY" | gunzip | head -n 5 >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Backup integrity verified${NC}"
else
    echo -e "${RED}❌ Warning: Backup integrity check failed${NC}"
fi

# Cleanup old backups if requested
if [ "$CLEANUP" = "--cleanup" ]; then
    echo -e "${YELLOW}🧹 Cleaning up old backups (older than $RETENTION_DAYS days)...${NC}"
    
    DELETED_COUNT=0
    for file in "$BACKUP_DIR"/van_edu_backup_*.sql.gz.enc; do
        if [ -f "$file" ]; then
            # Check if file is older than retention period
            if [ "$(find "$file" -mtime +$RETENTION_DAYS)" ]; then
                echo "  Deleting: $(basename "$file")"
                rm "$file"
                ((DELETED_COUNT++))
            fi
        fi
    done
    
    if [ $DELETED_COUNT -gt 0 ]; then
        echo -e "${GREEN}✅ Deleted $DELETED_COUNT old backup(s)${NC}"
    else
        echo -e "${GREEN}✅ No old backups to delete${NC}"
    fi
fi

# Show backup summary
echo ""
echo -e "${BLUE}📊 Backup Summary:${NC}"
echo "  Backup File: $ENCRYPTED_FILE"
echo "  Size: $BACKUP_SIZE"
echo "  Location: $BACKUP_DIR/$ENCRYPTED_FILE"
echo "  Created: $(date)"
echo ""

# List all available backups
echo -e "${BLUE}📁 Available Backups:${NC}"
if ls "$BACKUP_DIR"/van_edu_backup_*.sql.gz.enc >/dev/null 2>&1; then
    for backup in "$BACKUP_DIR"/van_edu_backup_*.sql.gz.enc; do
        if [ -f "$backup" ]; then
            SIZE=$(du -h "$backup" | cut -f1)
            DATE=$(stat -c %y "$backup" | cut -d' ' -f1,2 | cut -d'.' -f1)
            echo "  $(basename "$backup") - $SIZE - $DATE"
        fi
    done
else
    echo "  No backups found"
fi

echo ""
echo -e "${GREEN}🎉 Backup completed successfully!${NC}"
echo ""
echo -e "${YELLOW}💡 To restore this backup, run:${NC}"
echo "  make restore"
echo ""
echo -e "${YELLOW}💡 To schedule automatic backups, add to crontab:${NC}"
echo "  0 2 * * * cd $(pwd) && make backup >/dev/null 2>&1" 