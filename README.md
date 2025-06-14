# Van Edu Premium Subscription Platform Database

A complete MySQL database solution for Van Edu's premium subscription-based online learning platform. This system supports QR code payments with admin confirmation, automatic premium subscription management, and role-based access control.

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
- **phpMyAdmin**: http://localhost:8080
- **MySQL Port**: 3306 (for backend connection)

## 📋 Features

### ✅ Premium Subscription System
- Monthly ($9.99), Annual ($71.99), Lifetime ($199.99) packages
- Automatic premium expiry management
- QR code payment processing
- Admin payment confirmation workflow

### ✅ User Management
- Two-role system: `user` and `admin`
- Premium status tracking with expiry dates
- Admin permissions system (JSON-based)
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
- Optimized MySQL configuration
- Comprehensive indexing strategy

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
- id (INT, PRIMARY KEY)
- fullName (VARCHAR(255))
- email (VARCHAR(255), UNIQUE)
- password (VARCHAR(255)) -- bcrypt hashed
- phone, address, age (OPTIONAL)
- role (ENUM: 'user', 'admin')
- isPremium (BOOLEAN) -- Premium status for users
- premiumExpiryDate (DATETIME) -- null for lifetime
- currentPackage (VARCHAR(50)) -- monthly/annual/lifetime
- permissions (JSON) -- Admin permissions array
- createdAt, updatedAt (DATETIME)
```

#### `package` - Subscription Plans
```sql
- id (INT, PRIMARY KEY)
- name (VARCHAR(255)) -- "Monthly Premium"
- type (VARCHAR(50), UNIQUE) -- monthly/annual/lifetime
- description (TEXT)
- price (DECIMAL(10,2))
- durationDays (INT) -- null for lifetime
- isActive (BOOLEAN)
- createdAt, updatedAt (DATETIME)
```

#### `payment_transaction` - QR Payment System
```sql
- id (INT, PRIMARY KEY)
- userId (INT, FK -> users.id)
- packageId (INT, FK -> package.id)
- amount (DECIMAL(10,2))
- status (ENUM: 'pending', 'confirmed', 'expired', 'cancelled')
- qrCodeData (TEXT) -- JSON payment data
- referenceNumber (VARCHAR(255), UNIQUE)
- expiresAt (DATETIME) -- 24-hour expiry
- confirmedById (INT, FK -> users.id) -- Admin who confirmed
- confirmedAt (DATETIME)
- notes (TEXT) -- Admin notes
- createdAt, updatedAt (DATETIME)
```

#### Content Tables
- `categories` - Course categorization
- `courses` - Course metadata with premium flags
- `lessons` - Individual content units with premium protection

### Entity Relationships

```
users (1) ----< payment_transaction (M)
package (1) ----< payment_transaction (M)
users (admin) (1) ----< payment_transaction.confirmedById (M)
categories (1) ----< courses (M)
courses (1) ----< lessons (M)
```

## 🔧 Configuration

### Environment Variables (.env)

```bash
# Database Configuration
MYSQL_ROOT_PASSWORD=van_edu_root_2024!
MYSQL_DATABASE=van_edu_db
MYSQL_USER=van_edu_app
MYSQL_PASSWORD=van_edu_app_2024!

# Additional Database Users
DB_READONLY_USER=van_edu_readonly
DB_READONLY_PASSWORD=readonly_secure_2024!
DB_BACKUP_USER=van_edu_backup
DB_BACKUP_PASSWORD=backup_secure_2024!
DB_ADMIN_USER=van_edu_admin
DB_ADMIN_PASSWORD=admin_secure_2024!

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
make up-dev          # Development with phpMyAdmin

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
make mysql          # Connect as root
make mysql-app      # Connect as application user
make mysql-readonly # Connect as readonly user
make mysql-admin    # Connect as admin user
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

### Sample Admin User Permissions

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
- System tracks `premiumExpiryDate`
- Automated expiry checks (configurable interval)
- Grace period handling

## 🔗 Backend Integration

### Database Connection (Node.js)

```javascript
const mysql = require('mysql2/promise');

const connection = await mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'van_edu_app',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'van_edu_db'
});
```

### Check Premium Status

```javascript
// Check if user has premium access
const checkPremiumAccess = async (userId) => {
  const [rows] = await connection.execute(
    'SELECT isPremium, premiumExpiryDate FROM users WHERE id = ?',
    [userId]
  );
  
  const user = rows[0];
  if (!user.isPremium) return false;
  
  // Check expiry (null = lifetime)
  if (user.premiumExpiryDate === null) return true;
  
  return new Date() < new Date(user.premiumExpiryDate);
};
```

### Create Payment Transaction

```javascript
const createPaymentTransaction = async (userId, packageId, qrCodeData) => {
  const referenceNumber = `PAY${Date.now()}REF2024`;
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours
  
  const [result] = await connection.execute(`
    INSERT INTO payment_transaction 
    (userId, packageId, amount, qrCodeData, referenceNumber, expiresAt)
    SELECT ?, ?, p.price, ?, ?, ?
    FROM package p WHERE p.id = ?
  `, [userId, packageId, JSON.stringify(qrCodeData), referenceNumber, expiresAt, packageId]);
  
  return { transactionId: result.insertId, referenceNumber };
};
```

### Confirm Payment (Admin)

```javascript
const confirmPayment = async (transactionId, adminId, notes) => {
  // Start transaction
  await connection.beginTransaction();
  
  try {
    // Update payment status
    await connection.execute(`
      UPDATE payment_transaction 
      SET status = 'confirmed', confirmedById = ?, confirmedAt = NOW(), notes = ?
      WHERE id = ? AND status = 'pending'
    `, [adminId, notes, transactionId]);
    
    // Get payment details
    const [payment] = await connection.execute(`
      SELECT pt.userId, p.type, p.durationDays 
      FROM payment_transaction pt
      JOIN package p ON pt.packageId = p.id
      WHERE pt.id = ?
    `, [transactionId]);
    
    if (payment.length === 0) throw new Error('Payment not found');
    
    // Update user premium status
    const { userId, type, durationDays } = payment[0];
    let expiryDate = null;
    
    if (durationDays !== null) {
      expiryDate = new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000);
    }
    
    await connection.execute(`
      UPDATE users 
      SET isPremium = TRUE, premiumExpiryDate = ?, currentPackage = ?
      WHERE id = ?
    `, [expiryDate, type, userId]);
    
    await connection.commit();
    return { success: true };
  } catch (error) {
    await connection.rollback();
    throw error;
  }
};
```

## 📊 Sample Data

The system includes comprehensive sample data:

### Users
- **2 Admin users** (super admin + content manager)
- **4 Normal users** (2 free, 2 premium)
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
- **3 Confirmed payments** (active premium users)
- **2 Pending payments** (awaiting admin confirmation)
- **1 Expired payment** (QR code timeout)

## 🛡️ Security Features

### Database Security
- **Limited privilege users** for different access levels
- **Environment-based configuration** (no hardcoded credentials)
- **Encrypted backups** using AES-256-CBC
- **Foreign key constraints** for data integrity

### User Security
- **bcrypt password hashing** (12 rounds)
- **Role-based access control**
- **Premium expiry validation**
- **Admin permission granularity**

### Payment Security
- **QR code expiry** (24-hour timeout)
- **Reference number uniqueness**
- **Admin confirmation requirement**
- **Transaction status tracking**

## 📈 Performance Optimization

### Database Indexes
- **Primary/Foreign keys**: Automatic clustering
- **User lookups**: email, role, premium status
- **Payment queries**: status, reference, expiry
- **Content searches**: premium flags, categories
- **Full-text search**: course/lesson content

### MySQL Configuration
- **InnoDB engine** for ACID compliance
- **UTF8MB4 charset** for international support
- **Optimized buffer pools** for performance
- **Query cache enabled** for repeated queries

## 🔧 Maintenance

### Backup & Recovery

```bash
# Automated backups (recommended cron job)
0 2 * * * cd /path/to/van-edu-db && make backup

# Restore operations
make restore           # Interactive restore
make restore-force     # Latest backup restore
make list-backups     # Show available backups
```

### Health Monitoring

```bash
# System health
make health           # Complete health check
make status          # Service status
make performance     # Performance metrics

# Premium monitoring
make premium-stats   # Subscription analytics
make expire-premium  # Check expiring subscriptions
make payment-status  # Payment transaction status
```

### Migration Management

```bash
# Migration operations
make migrate-status  # Show migration status
make migrate-history # Show migration history
make migrate-create NAME=feature_name  # Create new migration
```

## 🔄 Premium Expiry Automation

### Cron Job Setup

Add to your crontab for automatic premium expiry management:

```bash
# Check every hour for expired premium subscriptions
0 * * * * cd /path/to/van-edu-db && make expire-premium

# Daily premium statistics report
0 8 * * * cd /path/to/van-edu-db && make premium-stats | mail -s "Daily Premium Report" admin@vanedu.com
```

### Expiry Script (Backend)

```javascript
// Automated premium expiry checker
const expirePremiumUsers = async () => {
  await connection.execute(`
    UPDATE users 
    SET isPremium = FALSE, currentPackage = NULL
    WHERE isPremium = TRUE 
    AND premiumExpiryDate IS NOT NULL 
    AND premiumExpiryDate < NOW()
  `);
};

// Run every hour
setInterval(expirePremiumUsers, 60 * 60 * 1000);
```

## 🚨 Troubleshooting

### Common Issues

#### Database Connection Failed
```bash
# Check service status
make status
make health

# Restart services
make restart
```

#### Premium Status Issues
```bash
# Check expired subscriptions
make expire-premium

# Verify payment transactions
make payment-status

# Check user premium status
make mysql-app
SELECT fullName, isPremium, premiumExpiryDate, currentPackage FROM users WHERE role = 'user';
```

#### Payment Processing Issues
```bash
# Check pending payments
SELECT * FROM payment_transaction WHERE status = 'pending' AND expiresAt > NOW();

# Review expired payments
SELECT * FROM payment_transaction WHERE status = 'expired';
```

## 📞 Support

### Getting Help

- **Documentation**: Complete setup and usage docs included
- **Health Checks**: `make health` for system diagnostics
- **Logs**: `make logs` for container logs
- **Performance**: `make performance` for metrics

### Development

```bash
# Development environment
make up-dev          # Start with phpMyAdmin
make reset          # Reset for testing (DANGER!)
make clean          # Clean containers/volumes
```

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**🎓 Van Edu Premium Platform** - Empowering education through premium subscription technology. 