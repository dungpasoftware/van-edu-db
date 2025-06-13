# Van Edu Database Repository

A complete MySQL database solution for the Van Edu online course platform with Docker deployment, automated backups, migration system, and comprehensive security features.

## 🚀 Quick Start

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd van-edu-db
   make setup
   ```

2. **Configure Environment**
   ```bash
   # Edit .env file with your settings
   nano .env
   ```

3. **Initialize Database**
   ```bash
   make init
   ```

4. **Access Services**
   - **MySQL**: `localhost:3306`
   - **phpMyAdmin** (dev): `http://localhost:8080`

## 📋 Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Database Schema](#database-schema)
- [Usage](#usage)
- [Security](#security)
- [Backup & Restore](#backup--restore)
- [Development](#development)
- [API Examples](#api-examples)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## ✨ Features

### 🐳 Docker Infrastructure
- MySQL 8.0 with optimized configuration
- Persistent data volumes
- Health checks and automatic restarts
- Network isolation and security
- phpMyAdmin for development

### 🗄️ Database Schema
- **Users**: Authentication and profiles
- **Courses**: Course content and metadata
- **Categories**: Hierarchical categorization
- **Enrollments**: Student progress tracking
- **Lessons**: Individual lesson content
- **Payments**: Transaction management
- **Reviews**: Course ratings and feedback
- **Coupons**: Discount system

### 🔒 Security Features
- Limited privilege database users
- Environment-based configuration
- Encrypted backups
- Network security
- SQL injection protection

### 🛠️ Development Tools
- Migration system
- Database seeding
- Performance monitoring
- Automated testing
- One-command deployment

### 📦 Backup System
- Automated encrypted backups
- Retention policies
- Restore capabilities
- Integrity verification

## 📋 Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Make utility
- OpenSSL (for backup encryption)
- 2GB+ available disk space

## 🔧 Installation

### 1. Environment Setup

```bash
# Copy environment template
cp env.example .env

# Edit configuration
nano .env
```

### 2. Key Configuration Options

```bash
# Database Configuration
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=van_edu_db
MYSQL_USER=van_edu_user
MYSQL_PASSWORD=your_secure_password

# Security
BACKUP_ENCRYPTION_KEY=your_encryption_key_32_chars

# Ports
MYSQL_PORT=3306
PHPMYADMIN_PORT=8080
```

### 3. Initialize Database

```bash
# Start services and initialize
make init

# Or step by step
make up          # Start containers
make migrate     # Run migrations
make seed        # Add sample data
```

## 📊 Database Schema

### Core Tables

#### Users Table
- `id`: Primary key
- `email`: Unique email address
- `password`: Hashed password
- `full_name`: User's full name
- `role`: student, instructor, admin
- `phone`: Contact number
- `address`: User address
- `age`: User age
- Timestamps and profile settings

#### Courses Table
- Course metadata and content
- Pricing and enrollment info
- Instructor and category relationships
- Status and publication settings
- Performance metrics

#### Categories Table
- Hierarchical course categories
- Support for subcategories
- Ordering and activation status

#### Enrollments Table
- User course enrollments
- Progress tracking (0-100%)
- Completion status and certificates

#### Lessons Table
- Individual course lessons
- Video content and duration
- Ordering and free preview settings

#### Payments Table
- Transaction records
- Multiple payment gateway support
- Refund tracking

#### Reviews Table
- Course ratings and comments
- Approval workflow
- Helpful vote tracking

## 🎯 Usage

### Common Commands

```bash
# Database Management
make up              # Start database
make down            # Stop database
make restart         # Restart services
make status          # Check service status
make logs            # View logs

# Development
make up-dev          # Start with phpMyAdmin
make reset           # Reset database (WARNING: destroys data)
make seed            # Add sample data
make stats           # Show database statistics

# Migrations
make migrate         # Run pending migrations
make migrate-create  NAME=add_feature  # Create new migration
make migrate-status  # Show migration status

# Backup & Restore
make backup          # Create backup
make restore         # Restore from backup
make list-backups    # List available backups

# Database Access
make mysql           # Connect as root
make mysql-user      # Connect as app user
make mysql-readonly  # Connect as readonly user

# Monitoring
make health          # Run health checks
make performance     # Show performance metrics
make tables          # List all tables
```

### Database Connections

#### Connection Details
```
Host: localhost (or container name: van-edu-mysql)
Port: 3306
Database: van_edu_db
Username: van_edu_user
Password: [from .env file]
```

#### Connection Examples

**PHP PDO**:
```php
$pdo = new PDO(
    'mysql:host=localhost;port=3306;dbname=van_edu_db;charset=utf8mb4',
    'van_edu_user',
    'password',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);
```

**Node.js**:
```javascript
const mysql = require('mysql2/promise');

const connection = await mysql.createConnection({
    host: 'localhost',
    port: 3306,
    user: 'van_edu_user',
    password: 'password',
    database: 'van_edu_db',
    charset: 'utf8mb4'
});
```

**Python**:
```python
import pymysql

connection = pymysql.connect(
    host='localhost',
    port=3306,
    user='van_edu_user',
    password='password',
    database='van_edu_db',
    charset='utf8mb4'
)
```

## 🔐 Security

### Database Users

The system creates three database users:

1. **van_edu_user** (Application user)
   - SELECT, INSERT, UPDATE, DELETE on van_edu_db
   - CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE

2. **van_edu_readonly** (Read-only user)
   - SELECT only on van_edu_db
   - For reporting and analytics

3. **van_edu_backup** (Backup user)
   - SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER
   - For backup operations

### Security Best Practices

1. **Change Default Passwords**
   ```bash
   # Update passwords in .env file
   MYSQL_ROOT_PASSWORD=very_secure_root_password
   MYSQL_PASSWORD=secure_app_password
   ```

2. **Enable Backup Encryption**
   ```bash
   # Set 32-character encryption key
   BACKUP_ENCRYPTION_KEY=your_32_character_encryption_key
   ```

3. **Regular Security Checks**
   ```bash
   # Check user permissions
   make check-permissions
   
   # Monitor performance
   make performance
   ```

## 💾 Backup & Restore

### Automated Backups

```bash
# Create backup with encryption and compression
make backup

# Create backup without cleanup
make backup-no-cleanup

# List available backups
make list-backups
```

### Backup Features

- **Compression**: gzip compression
- **Encryption**: AES-256-CBC encryption
- **Retention**: Configurable retention policy (default: 30 days)
- **Integrity**: Automatic verification

### Restore Operations

```bash
# Interactive restore
make restore

# Force restore (no confirmation)
make restore-force

# Manual restore from specific file
./scripts/restore.sh -f /path/to/backup.sql.gz
```

## 🧪 Development

### Sample Data

The database includes comprehensive sample data:

- **6 users**: 1 admin, 2 instructors, 3 students
- **6 categories**: Programming, Web Dev, Data Science, Design, Business, Languages
- **4 courses**: JavaScript, React, Python Data Science, UI/UX Design
- **Multiple lessons** with video content
- **Enrollment records** with progress tracking
- **Payment transactions**
- **Course reviews and ratings**
- **Active coupon codes**

### Development Environment

```bash
# Start with phpMyAdmin for database management
make up-dev

# Access phpMyAdmin at http://localhost:8080
# Username: van_edu_user
# Password: [from .env file]

# Reset database with fresh sample data
make reset
```

### Creating Migrations

```bash
# Create new migration
make migrate-create NAME=add_user_preferences

# Edit the generated file
nano migrations/20241201_120000_add_user_preferences.sql

# Run migrations
make migrate

# Check migration status
make migrate-status
```

## 🌐 API Examples

### User Management

```sql
-- Create new user
INSERT INTO users (email, password, full_name, role) 
VALUES ('user@example.com', '$2y$10$...', 'John Doe', 'student');

-- Get user by email
SELECT * FROM users 
WHERE email = 'user@example.com' AND is_active = 1;

-- Update user profile
UPDATE users 
SET full_name = 'John Smith', phone = '+1234567890' 
WHERE id = 1;
```

### Course Operations

```sql
-- Get featured courses with instructor and category info
SELECT c.*, cat.name as category_name, u.full_name as instructor_name
FROM courses c
JOIN categories cat ON c.category_id = cat.id
JOIN users u ON c.instructor_id = u.id
WHERE c.featured = 1 AND c.status = 'published'
ORDER BY c.created_at DESC;

-- Get course with lesson count and total duration
SELECT c.*, 
       COUNT(l.id) as lesson_count,
       SUM(l.video_duration) as total_duration
FROM courses c
LEFT JOIN lessons l ON c.id = l.course_id
WHERE c.id = 1
GROUP BY c.id;
```

### Enrollment and Progress

```sql
-- Enroll user in course
INSERT INTO enrollments (user_id, course_id) VALUES (1, 1);

-- Update progress
UPDATE enrollments 
SET progress = 45.5, last_accessed_at = NOW()
WHERE user_id = 1 AND course_id = 1;

-- Mark lesson as completed
INSERT INTO lesson_progress (user_id, lesson_id, course_id, completed, watch_time)
VALUES (1, 1, 1, TRUE, 480)
ON DUPLICATE KEY UPDATE 
completed = TRUE, watch_time = 480, updated_at = NOW();
```

### Analytics Queries

```sql
-- Popular courses by enrollment
SELECT c.title, c.total_enrollments, c.average_rating
FROM courses c
WHERE c.status = 'published'
ORDER BY c.total_enrollments DESC, c.average_rating DESC
LIMIT 10;

-- Revenue by month
SELECT DATE_FORMAT(created_at, '%Y-%m') as month,
       COUNT(*) as transactions,
       SUM(amount) as revenue
FROM payments
WHERE status = 'completed'
GROUP BY month
ORDER BY month DESC;

-- User engagement metrics
SELECT u.full_name,
       COUNT(DISTINCT e.course_id) as courses_enrolled,
       AVG(e.progress) as avg_progress
FROM users u
JOIN enrollments e ON u.id = e.user_id
WHERE u.role = 'student'
GROUP BY u.id
ORDER BY avg_progress DESC;
```

## 🔍 Troubleshooting

### Common Issues

#### Database Won't Start
```bash
# Check container status
make status

# View logs for errors
make logs

# Reset if needed (WARNING: destroys data)
make reset
```

#### Connection Refused
```bash
# Wait for database to be ready
make wait

# Run health checks
make health

# Verify configuration
cat .env | grep MYSQL
```

#### Migration Errors
```bash
# Check migration status
make migrate-status

# View migration history
make migrate-history

# Connect manually to fix issues
make mysql-user
```

#### Performance Issues
```bash
# Check performance metrics
make performance

# Show database statistics
make stats

# Monitor disk usage
make health
```

### Log Analysis

```bash
# Container logs
make logs

# MySQL error log
docker exec van-edu-mysql tail -f /var/log/mysql/error.log

# Slow query log
docker exec van-edu-mysql tail -f /var/log/mysql/slow.log
```

## 📁 Directory Structure

```
van-edu-db/
├── docker-compose.yml          # Docker services configuration
├── env.example                 # Environment template
├── Makefile                    # Management commands
├── README.md                   # This documentation
├── config/
│   └── mysql.cnf              # MySQL configuration
├── scripts/
│   ├── init/
│   │   ├── 01-create-database.sql  # Database schema
│   │   ├── 02-create-user.sql      # User creation
│   │   └── 03-seed-data.sql        # Sample data
│   ├── backup.sh              # Backup script
│   ├── restore.sh             # Restore script
│   └── migrate.sh             # Migration script
├── migrations/                 # Database migrations
├── backups/                   # Backup storage
└── logs/                      # Application logs
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Update documentation
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Submit a pull request

### Development Guidelines

- Follow SQL naming conventions (snake_case)
- Add migration for any schema changes
- Update sample data if needed
- Test backup/restore functionality
- Document new features in README

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Documentation**: This README and inline code comments
- **Issues**: GitHub Issues for bug reports and feature requests
- **Discussions**: GitHub Discussions for questions and community support

---

**Van Edu Database Repository** - Built with ❤️ for online education platforms 