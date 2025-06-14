# Van Edu Premium Subscription Platform Database

A complete PostgreSQL database solution for Van Edu's premium subscription-based online learning platform. This system supports QR code payments with admin confirmation, automatic premium subscription management, and role-based access control.

## 🎯 Platform Overview

Van Edu is a **premium subscription platform** where users pay for unlimited access to all courses and content. Key features include:

- **Subscription Model**: Monthly, Annual, and Lifetime premium packages
- **QR Payment System**: Secure QR code payments with admin confirmation
- **Role-Based Access**: Normal users (students) and admins (content managers)
- **Automatic Expiry**: Automated premium subscription expiry management
- **Content Protection**: Premium content locked for non-premium users

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- 4GB+ available RAM
- 10GB+ disk space

### Installation

```bash
# Clone repository
git clone <repository-url>
cd van-edu-db

# Setup environment
make setup

# Edit .env file with your configuration
nano .env

# Initialize complete system
make init

# Start with development tools
make up-dev
```

**🌐 Access Points:**
- **pgAdmin**: http://localhost:8080
- **PostgreSQL Port**: 5432 (for backend connection)

## 📋 Features

### ✅ Premium Subscription System
- Monthly ($9.99), Annual ($71.99), Lifetime ($199.99) packages
- Automatic premium expiry management
- QR code payment processing
- Admin payment confirmation workflow

### ✅ User Management
- Two-role system: `user` and `admin`
- Premium status tracking with expiry dates
- Admin permissions system (JSONB-based)
- bcrypt password hashing

### ✅ Content Management
- Course categories and hierarchical organization
- Premium and free content segregation
- Video lessons with duration tracking
- Course thumbnails and metadata

### ✅ Payment Processing
- QR code generation for payments
- 24-hour payment expiry system
- Admin confirmation workflow
- Payment status tracking (pending, confirmed, expired, cancelled)

### ✅ Security & Performance
- Role-based database users
- Encrypted backups (AES-256-CBC)
- Optimized PostgreSQL configuration
- Comprehensive indexing strategy
- Full-text search capabilities

### ✅ Development Tools
- Docker containerization
- Automated migration system
- Sample data seeding
- Health monitoring
- Performance metrics

## 🗄️ Database Schema

### Core Tables

#### `users` - User Management
```sql
- id (SERIAL, PRIMARY KEY)
- full_name (VARCHAR(255))
- email (VARCHAR(255), UNIQUE)
- password (VARCHAR(255)) -- bcrypt hashed
- phone, address, age (OPTIONAL)
- role (VARCHAR(20)) -- 'user' or 'admin'
- is_premium (BOOLEAN) -- Premium status for users
- premium_expiry_date (TIMESTAMP) -- null for lifetime
- current_package (VARCHAR(50)) -- monthly/annual/lifetime
- permissions (JSONB) -- Admin permissions array
- created_at, updated_at (TIMESTAMP)
```

#### `package` - Subscription Plans
```sql
- id (SERIAL, PRIMARY KEY)
- name (VARCHAR(255)) -- "Monthly Premium"
- type (VARCHAR(50), UNIQUE) -- monthly/annual/lifetime
- description (TEXT)
- price (DECIMAL(10,2))
- duration_days (INTEGER) -- null for lifetime
- is_active (BOOLEAN)
- created_at, updated_at (TIMESTAMP)
```

#### `payment_transaction` - QR Payment System
```sql
- id (SERIAL, PRIMARY KEY)
- user_id (INTEGER, FK -> users.id)
- package_id (INTEGER, FK -> package.id)
- amount (DECIMAL(10,2))
- status (VARCHAR(20)) -- 'pending', 'confirmed', 'expired', 'cancelled'
- qr_code_data (TEXT) -- JSON payment data
- reference_number (VARCHAR(255), UNIQUE)
- expires_at (TIMESTAMP) -- 24-hour expiry
- confirmed_by_id (INTEGER, FK -> users.id) -- Admin who confirmed
- confirmed_at (TIMESTAMP)
- notes (TEXT) -- Admin notes
- created_at, updated_at (TIMESTAMP)
```

#### Content Tables
- `categories` - Course categorization
- `courses` - Course metadata with premium flags
- `lessons` - Individual content units with premium protection

### Entity Relationships

```
users (1) ----< payment_transaction (M)
package (1) ----< payment_transaction (M)
users (admin) (1) ----< payment_transaction.confirmed_by_id (M)
categories (1) ----< courses (M)
courses (1) ----< lessons (M)
```

### PostgreSQL Features

- **JSONB Support**: Efficient storage and querying of admin permissions
- **Full-Text Search**: GIN indexes for course and lesson content search
- **Triggers**: Automatic `updated_at` timestamp updates
- **Functions**: Premium access checking and expiry management
- **Views**: Convenient access to premium users and payment summaries

## 🔧 Configuration

### Environment Variables (.env)

```bash
# PostgreSQL Configuration
POSTGRES_DB=van_edu_db
POSTGRES_USER=van_edu_app
POSTGRES_PASSWORD=van_edu_app_2024!

# Additional Database Users
DB_READONLY_USER=van_edu_readonly
DB_READONLY_PASSWORD=readonly_secure_2024!
DB_BACKUP_USER=van_edu_backup
DB_BACKUP_PASSWORD=backup_secure_2024!
DB_ADMIN_USER=van_edu_admin
DB_ADMIN_PASSWORD=admin_secure_2024!

# pgAdmin Configuration
PGADMIN_EMAIL=admin@vanedu.com
PGADMIN_PASSWORD=admin123

# Premium Subscription Configuration
PAYMENT_QR_EXPIRY_HOURS=24
AUTO_EXPIRE_PREMIUM_ENABLED=true
PREMIUM_CHECK_INTERVAL_MINUTES=60

# Backup Configuration
BACKUP_ENCRYPTION_KEY=your_32_character_encryption_key_here
```

## 📖 Usage Guide

### Database Operations

```bash
# Start services
make up              # Production mode
make up-dev          # Development with pgAdmin

# Database management
make migrate         # Run pending migrations
make seed           # Load sample data
make backup         # Create encrypted backup
make restore        # Interactive restore

# Statistics and monitoring
make stats          # Show platform statistics
make premium-stats  # Premium subscription analytics
make payment-status # Payment transaction status
make expire-premium # Check expired subscriptions
```

### Database Access

```bash
make psql           # Connect as superuser
make psql-app       # Connect as application user
make psql-readonly  # Connect as readonly user
make psql-admin     # Connect as admin user
```

### Development Commands

```bash
make migrate-create NAME=feature_name  # Create new migration
make health                           # Run health checks
make performance                      # Show performance metrics
make reset                           # Reset database (DANGER!)
```

## 🔐 Admin Permissions System

### Available Permissions

- **Video Management**: `upload_video`, `edit_video`, `delete_video`
- **Category Management**: `create_category`, `edit_category`, `delete_category`
- **User Management**: `view_users`, `edit_users`, `delete_users`
- **Analytics**: `view_analytics`
- **System**: `manage_settings`

### Sample Admin User Permissions (JSONB)

```json
[
  "upload_video",
  "edit_video",
  "delete_video", 
  "create_category",
  "edit_category",
  "delete_category",
  "view_users",
  "edit_users",
  "delete_users",
  "view_analytics",
  "manage_settings"
]
```

## 💰 Premium Subscription Flow

### 1. Package Selection
User selects from available packages:
- **Monthly Premium**: $9.99 (30 days)
- **Annual Premium**: $71.99 (365 days) 
- **Lifetime Premium**: $199.99 (unlimited)

### 2. QR Code Generation
System generates QR code with:
```json
{
  "bank": "Bank Name",
  "account": "1234567890",
  "amount": 9.99,
  "reference": "PAY001"
}
```

### 3. Payment Process
- QR code expires in 24 hours
- User makes payment using QR code
- Transaction status: `pending`

### 4. Admin Confirmation
- Admin reviews payment evidence
- Updates transaction status to `confirmed`
- User premium status activated automatically

### 5. Premium Expiry Management
- System tracks `premium_expiry_date`
- Automated expiry checks (configurable interval)
- Grace period handling

## 🔗 Backend Integration

### Database Connection (Node.js)

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'van_edu_app',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'van_edu_db',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

### Check Premium Status

```javascript
// Check if user has premium access using PostgreSQL function
const checkPremiumAccess = async (userId) => {
  const result = await pool.query(
    'SELECT check_premium_access($1) as has_access',
    [userId]
  );
  
  return result.rows[0].has_access;
};

// Alternative manual check
const checkPremiumAccessManual = async (userId) => {
  const result = await pool.query(
    'SELECT is_premium, premium_expiry_date FROM users WHERE id = $1',
    [userId]
  );
  
  const user = result.rows[0];
  if (!user.is_premium) return false;
  
  // Check expiry (null = lifetime)
  if (user.premium_expiry_date === null) return true;
  
  return new Date() < new Date(user.premium_expiry_date);
};
```

### Create Payment Transaction

```javascript
const createPaymentTransaction = async (userId, packageId, qrCodeData) => {
  const referenceNumber = `PAY${Date.now()}REF2024`;
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours
  
  const result = await pool.query(`
    INSERT INTO payment_transaction 
    (user_id, package_id, amount, qr_code_data, reference_number, expires_at)
    SELECT $1, $2, p.price, $3, $4, $5
    FROM package p WHERE p.id = $2
    RETURNING id, reference_number
  `, [userId, packageId, JSON.stringify(qrCodeData), referenceNumber, expiresAt]);
  
  return { 
    transactionId: result.rows[0].id, 
    referenceNumber: result.rows[0].reference_number 
  };
};
```

### Confirm Payment (Admin)

```javascript
const confirmPayment = async (transactionId, adminId, notes) => {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Update payment status
    await client.query(`
      UPDATE payment_transaction 
      SET status = 'confirmed', confirmed_by_id = $1, confirmed_at = CURRENT_TIMESTAMP, notes = $2
      WHERE id = $3 AND status = 'pending'
    `, [adminId, notes, transactionId]);
    
    // Get payment details
    const paymentResult = await client.query(`
      SELECT pt.user_id, p.type, p.duration_days 
      FROM payment_transaction pt
      JOIN package p ON pt.package_id = p.id
      WHERE pt.id = $1
    `, [transactionId]);
    
    if (paymentResult.rows.length === 0) throw new Error('Payment not found');
    
    // Update user premium status
    const { user_id, type, duration_days } = paymentResult.rows[0];
    let expiryDate = null;
    
    if (duration_days !== null) {
      expiryDate = new Date(Date.now() + duration_days * 24 * 60 * 60 * 1000);
    }
    
    await client.query(`
      UPDATE users 
      SET is_premium = TRUE, premium_expiry_date = $1, current_package = $2
      WHERE id = $3
    `, [expiryDate, type, user_id]);
    
    await client.query('COMMIT');
    return { success: true };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};
```

### Search Content with Full-Text Search

```javascript
// PostgreSQL full-text search for courses
const searchCourses = async (searchTerm) => {
  const result = await pool.query(`
    SELECT id, title, description, 
           ts_rank(to_tsvector('english', title || ' ' || description), plainto_tsquery('english', $1)) as rank
    FROM courses 
    WHERE to_tsvector('english', title || ' ' || description) @@ plainto_tsquery('english', $1)
    ORDER BY rank DESC, title
  `, [searchTerm]);
  
  return result.rows;
};
```

## 📊 Sample Data

The system includes comprehensive sample data:

### Users
- **2 Admin users** (super admin + content manager)
- **5 Normal users** (2 free, 3 premium with different packages)
- All passwords: `password123` (bcrypt hashed)

### Packages
- Monthly Premium: $9.99 (30 days)
- Annual Premium: $71.99 (365 days) 
- Lifetime Premium: $199.99 (unlimited)

### Content
- **6 Categories**: Web Dev, Mobile, Data Science, Design, DevOps, Business
- **10 Courses**: JavaScript, React, Python, iOS, etc.
- **15+ Lessons**: Video content with premium flags
- **1 Free Course**: "Introduction to Programming"

### Payment Transactions
- **3 Confirmed payments** (different packages)
- **2 Pending payments** (awaiting admin confirmation)
- **1 Expired payment** (QR code timeout)

## 🔒 Security Features

### Database Users & Privileges

- **van_edu_app**: Application user with CRUD operations
- **van_edu_readonly**: Read-only access for analytics
- **van_edu_backup**: Backup operations only
- **van_edu_admin**: Database administration

### Backup Security

- **AES-256-CBC encryption** for all backups
- **Gzip compression** to reduce storage
- **30-day retention** with automatic cleanup
- **Integrity verification** after backup creation

### Password Security

- **bcrypt hashing** for all user passwords
- **SCRAM-SHA-256** for PostgreSQL authentication
- **Environment-based** configuration (no hardcoded secrets)

## 📈 Performance Features

### PostgreSQL Optimizations

- **Shared buffers**: 256MB for caching
- **Work memory**: 4MB for query operations
- **Effective cache size**: 1GB assumption
- **WAL configuration**: Optimized for performance and safety

### Indexing Strategy

- **Primary keys**: SERIAL with automatic indexing
- **Foreign keys**: Indexed for join performance
- **Search fields**: GIN indexes for full-text search
- **Query patterns**: Composite indexes for common queries

### Monitoring

```bash
# Performance metrics
make performance

# Database statistics
make stats

# Health checks
make health
```

## 🛠️ Development

### Creating Migrations

```bash
# Create new migration
make migrate-create NAME=add_user_avatar

# Run migrations
make migrate

# Check migration status
make migrate-status

# View migration history
make migrate-history
```

### Sample Migration (PostgreSQL)

```sql
-- Migration: add_user_avatar
-- Created: 2024-01-15

-- Connect to the database
\c van_edu_db;

-- Add avatar column to users table
ALTER TABLE users ADD COLUMN avatar_url VARCHAR(500);

-- Create index for avatar queries
CREATE INDEX idx_users_avatar ON users(avatar_url) WHERE avatar_url IS NOT NULL;

-- Rollback: ALTER TABLE users DROP COLUMN avatar_url;
```

### Backup & Restore

```bash
# Create backup
make backup

# List available backups
make list-backups

# Interactive restore
make restore

# Force restore from latest
make restore-force
```

## 🚀 Production Deployment

### Environment Setup

1. **Copy environment template**:
   ```bash
   cp env.example .env
   ```

2. **Configure production values**:
   - Strong passwords for all database users
   - Secure backup encryption key
   - Production-appropriate resource limits

3. **Initialize system**:
   ```bash
   make init
   ```

### Monitoring & Maintenance

```bash
# Daily operations
make health          # Check system health
make stats          # Review platform statistics
make premium-stats  # Monitor subscription metrics

# Weekly operations
make backup         # Create encrypted backup
make performance    # Review performance metrics

# Monthly operations
make expire-premium # Process expired subscriptions
```

### Automated Backups

Add to crontab for automated daily backups:

```bash
# Daily backup at 2 AM
0 2 * * * cd /path/to/van-edu-db && make backup >/dev/null 2>&1

# Weekly cleanup and health check
0 3 * * 0 cd /path/to/van-edu-db && make health
```

## 📚 API Examples

### Premium Content Access Control

```javascript
// Middleware to check premium access
const requirePremium = async (req, res, next) => {
  const userId = req.user.id;
  const hasAccess = await checkPremiumAccess(userId);
  
  if (!hasAccess) {
    return res.status(403).json({
      error: 'Premium subscription required',
      upgradeUrl: '/premium/packages'
    });
  }
  
  next();
};

// Protected route
app.get('/api/courses/:id/premium-lessons', requirePremium, async (req, res) => {
  const lessons = await pool.query(
    'SELECT * FROM lessons WHERE course_id = $1 AND is_premium = true',
    [req.params.id]
  );
  
  res.json(lessons.rows);
});
```

### Admin Permission Checking

```javascript
// Check admin permissions using JSONB
const hasPermission = async (userId, permission) => {
  const result = await pool.query(
    'SELECT permissions ? $2 as has_permission FROM users WHERE id = $1 AND role = $3',
    [userId, permission, 'admin']
  );
  
  return result.rows[0]?.has_permission || false;
};

// Admin middleware
const requirePermission = (permission) => async (req, res, next) => {
  const hasAccess = await hasPermission(req.user.id, permission);
  
  if (!hasAccess) {
    return res.status(403).json({ error: 'Insufficient permissions' });
  }
  
  next();
};
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Guidelines

- Follow PostgreSQL best practices
- Use camelCase for new table/column names
- Include migration scripts for schema changes
- Add appropriate indexes for new queries
- Update documentation for new features

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:

- Create an issue in the repository
- Check the troubleshooting section
- Review the PostgreSQL documentation
- Contact the development team

---

**Van Edu Premium Subscription Platform** - Empowering online education with robust database architecture. 