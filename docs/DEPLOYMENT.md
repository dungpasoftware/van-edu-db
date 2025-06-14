 # Van Edu Database - Server Deployment Guide

This guide provides quick commands for deploying the Van Edu Premium Subscription Platform database on servers.

## 🚀 Quick Server Setup

### 1. Initial Setup
```bash
# Clone the repository
git clone <your-repo-url> van-edu-db
cd van-edu-db

# Copy and configure environment
cp env.example .env
# Edit .env with your production settings
nano .env

# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Database Users Setup Commands

#### Create All Database Users (Recommended)
```bash
make create-users
```

#### Alternative: Use Deployment Script
```bash
make deploy-users
# or directly:
./scripts/deploy.sh users-only
```

#### Test All Connections
```bash
make test-connections
# or:
make deploy-test
```

## 🔧 Available Makefile Commands

### User Management
```bash
make create-users      # Create all database users with permissions
make list-users        # List all database users
make check-permissions # Check user permissions
make drop-users        # Drop additional users (WARNING: destructive)
make test-connections  # Test all user connections
```

### Production Setup
```bash
make setup-production  # Complete production setup
make deploy-users      # Deploy users only
make deploy-test       # Test deployment
```

### Database Operations
```bash
make init              # Full initialization (start, migrate, seed)
make up                # Start database only
make up-dev            # Start with pgAdmin
make migrate           # Run migrations
make seed              # Load sample data
make backup            # Create backup
make restore           # Restore from backup
```

### Monitoring
```bash
make health            # Health checks
make stats             # Database statistics
make premium-stats     # Premium subscription stats
make performance       # Performance metrics
```

## 👥 Database Users

The system creates 4 database users:

| User | Purpose | Permissions | Password Variable |
|------|---------|-------------|-------------------|
| `van_edu_app` | Main application | Superuser | `POSTGRES_PASSWORD` |
| `van_edu_readonly` | Analytics/Reporting | SELECT only | `DB_READONLY_PASSWORD` |
| `van_edu_admin` | Database management | Full table access | `DB_ADMIN_PASSWORD` |
| `van_edu_backup` | Backup operations | SELECT for backups | `DB_BACKUP_PASSWORD` |

## 🔗 DBeaver Connection Settings

### Primary Application User
- **Host**: `your-server-ip`
- **Port**: `5432`
- **Database**: `van_edu_db`
- **Username**: `van_edu_app`
- **Password**: From `POSTGRES_PASSWORD` in .env

### Read-Only User (Analytics)
- **Host**: `your-server-ip`
- **Port**: `5432`
- **Database**: `van_edu_db`
- **Username**: `van_edu_readonly`
- **Password**: From `DB_READONLY_PASSWORD` in .env

### Admin User (Management)
- **Host**: `your-server-ip`
- **Port**: `5432`
- **Database**: `van_edu_db`
- **Username**: `van_edu_admin`
- **Password**: From `DB_ADMIN_PASSWORD` in .env

## 🛠️ Server Deployment Workflow

### For New Server Setup:
```bash
# 1. Initial setup
make setup

# 2. Edit .env file with production settings
nano .env

# 3. Start database
make up

# 4. Initialize database
make init

# 5. Create additional users
make create-users

# 6. Test everything
make health
make test-connections
```

### For Existing Server (Users Only):
```bash
# If database exists but users are missing
make create-users
make test-connections
```

### For Production Environment:
```bash
# Complete production setup
make setup-production
```

## 🔒 Security Checklist

- [ ] Update all passwords in `.env` file
- [ ] Use strong, unique passwords for each user
- [ ] Configure firewall rules for port 5432
- [ ] Set up SSL certificates for production
- [ ] Enable PostgreSQL SSL in production
- [ ] Configure backup encryption keys
- [ ] Set up automated backups
- [ ] Monitor database access logs

## 📊 Verification Commands

### Check Database Status
```bash
make health
make stats
make premium-stats
```

### Verify User Setup
```bash
make list-users
make check-permissions
make test-connections
```

### Test Premium Features
```bash
# Check premium users
make psql-readonly
# Then run: SELECT * FROM users WHERE is_premium = true;

# Check payment transactions
# Run: SELECT * FROM payment_transaction ORDER BY created_at DESC;
```

## 🚨 Troubleshooting

### Connection Issues
```bash
# Check if database is running
make status

# Check logs
make logs

# Restart services
make down
make up
```

### User Authentication Issues
```bash
# Recreate users
make drop-users
make create-users
make test-connections
```

### Permission Issues
```bash
# Check current permissions
make check-permissions

# Reset permissions (recreate users)
make deploy-users
```

## 📝 Environment Variables

Required variables in `.env`:

```bash
# PostgreSQL Configuration
POSTGRES_DB=van_edu_db
POSTGRES_USER=van_edu_app
POSTGRES_PASSWORD=your_secure_password

# Additional Users
DB_READONLY_PASSWORD=readonly_password
DB_ADMIN_PASSWORD=admin_password
DB_BACKUP_PASSWORD=backup_password

# Ports
POSTGRES_PORT=5432
PGADMIN_PORT=8080

# pgAdmin (for development)
PGADMIN_EMAIL=admin@vanedu.com
PGADMIN_PASSWORD=admin_password
```

## 🎯 Quick Commands Summary

```bash
# Essential commands for server deployment
make setup              # Initial setup
make create-users       # Create database users
make test-connections   # Test all connections
make setup-production   # Complete production setup
make health            # Health check
make backup            # Create backup
```

This deployment guide ensures you can quickly set up the Van Edu database on any server with proper user management and security configurations.