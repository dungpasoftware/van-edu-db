# Van Edu Database Schema Documentation

This document provides detailed information about the Van Edu database schema, including table structures, relationships, and usage patterns.

## Database Overview

The Van Edu database is designed to support a comprehensive online learning platform with the following core features:

- User management (students, instructors, administrators)
- Course creation and management
- Hierarchical course categorization
- Enrollment and progress tracking
- Payment processing
- Course reviews and ratings
- Coupon/discount system

## Entity Relationship Diagram

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Users    │    │  Categories │    │   Coupons   │
│             │    │             │    │             │
│ • id (PK)   │    │ • id (PK)   │    │ • id (PK)   │
│ • email     │    │ • name      │    │ • code      │
│ • password  │    │ • slug      │    │ • type      │
│ • role      │    │ • parent_id │    │ • value     │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Courses   │    │   Lessons   │    │  Payments   │
│             │    │             │    │             │
│ • id (PK)   │    │ • id (PK)   │    │ • id (PK)   │
│ • title     │    │ • title     │    │ • amount    │
│ • price     │    │ • content   │    │ • status    │
│ • status    │    │ • video_url │    │ • gateway   │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Enrollments │    │Lesson_Progress│  │   Reviews   │
│             │    │             │    │             │
│ • id (PK)   │    │ • id (PK)   │    │ • id (PK)   │
│ • user_id   │    │ • user_id   │    │ • user_id   │
│ • course_id │    │ • lesson_id │    │ • course_id │
│ • progress  │    │ • completed │    │ • rating    │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Table Specifications

### Users Table

**Purpose**: Store user account information for students, instructors, and administrators.

```sql
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role ENUM('student', 'instructor', 'admin') NOT NULL DEFAULT 'student',
    phone VARCHAR(20) NULL,
    address TEXT NULL,
    age INT UNSIGNED NULL,
    profile_image VARCHAR(500) NULL,
    email_verified_at TIMESTAMP NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Key Fields**:
- `id`: Primary key, auto-incrementing user identifier
- `email`: Unique email address for authentication
- `password`: Hashed password (use bcrypt or similar)
- `role`: User permission level (student/instructor/admin)
- `is_active`: Account status flag

**Indexes**:
- `idx_email`: Fast lookup by email for authentication
- `idx_role`: Filter users by role
- `idx_created_at`: Sort users by registration date

### Categories Table

**Purpose**: Hierarchical categorization system for courses.

```sql
CREATE TABLE categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    parent_id BIGINT UNSIGNED NULL,
    image VARCHAR(500) NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
);
```

**Key Fields**:
- `parent_id`: Self-referencing foreign key for hierarchical structure
- `slug`: URL-friendly identifier
- `sort_order`: Custom ordering within same level

**Usage Examples**:
- Top-level: Programming, Design, Business
- Sub-level: JavaScript (under Programming), UI/UX (under Design)

### Courses Table

**Purpose**: Core course information and metadata.

```sql
CREATE TABLE courses (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    short_description TEXT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    original_price DECIMAL(10,2) NULL,
    instructor_id BIGINT UNSIGNED NOT NULL,
    category_id BIGINT UNSIGNED NOT NULL,
    thumbnail VARCHAR(500) NULL,
    preview_video VARCHAR(500) NULL,
    status ENUM('draft', 'published', 'archived', 'pending_review') NOT NULL DEFAULT 'draft',
    level ENUM('beginner', 'intermediate', 'advanced') NOT NULL DEFAULT 'beginner',
    language VARCHAR(10) NOT NULL DEFAULT 'en',
    duration_minutes INT UNSIGNED NULL,
    total_lessons INT UNSIGNED DEFAULT 0,
    total_enrollments INT UNSIGNED DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_reviews INT UNSIGNED DEFAULT 0,
    requirements TEXT NULL,
    what_you_learn TEXT NULL,
    target_audience TEXT NULL,
    certificate_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    featured BOOLEAN NOT NULL DEFAULT FALSE,
    published_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (instructor_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
);
```

**Key Fields**:
- `instructor_id`: Reference to course creator
- `status`: Publication workflow state
- `featured`: Homepage promotion flag
- Statistics fields: `total_enrollments`, `average_rating`, etc.

**Pricing**:
- `price`: Current selling price
- `original_price`: For displaying discounts

### Lessons Table

**Purpose**: Individual course content units.

```sql
CREATE TABLE lessons (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    course_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    content LONGTEXT NULL,
    video_url VARCHAR(500) NULL,
    video_duration INT UNSIGNED NULL COMMENT 'Duration in seconds',
    lesson_type ENUM('video', 'text', 'quiz', 'assignment') NOT NULL DEFAULT 'video',
    sort_order INT NOT NULL DEFAULT 0,
    is_free BOOLEAN NOT NULL DEFAULT FALSE,
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    resources JSON NULL COMMENT 'Additional resources and files',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);
```

**Key Fields**:
- `lesson_type`: Content format (video/text/quiz/assignment)
- `is_free`: Preview lessons available without enrollment
- `resources`: JSON field for additional files and links
- `sort_order`: Lesson sequence within course

### Enrollments Table

**Purpose**: Track student course enrollments and progress.

```sql
CREATE TABLE enrollments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    course_id BIGINT UNSIGNED NOT NULL,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    progress DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Progress percentage (0-100)',
    last_accessed_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    certificate_issued_at TIMESTAMP NULL,
    status ENUM('active', 'suspended', 'completed', 'refunded') NOT NULL DEFAULT 'active',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    UNIQUE KEY unique_enrollment (user_id, course_id)
);
```

**Key Fields**:
- `progress`: Percentage completion (0.00 to 100.00)
- `status`: Enrollment state management
- `unique_enrollment`: Prevents duplicate enrollments

### Lesson Progress Table

**Purpose**: Detailed tracking of individual lesson completion.

```sql
CREATE TABLE lesson_progress (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    lesson_id BIGINT UNSIGNED NOT NULL,
    course_id BIGINT UNSIGNED NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    watch_time INT UNSIGNED DEFAULT 0 COMMENT 'Time watched in seconds',
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    UNIQUE KEY unique_lesson_progress (user_id, lesson_id)
);
```

**Usage**: Calculate overall course progress and resume functionality.

### Payments Table

**Purpose**: Transaction records and payment processing.

```sql
CREATE TABLE payments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    course_id BIGINT UNSIGNED NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    status ENUM('pending', 'completed', 'failed', 'refunded', 'cancelled') NOT NULL DEFAULT 'pending',
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(255) NULL,
    gateway_response JSON NULL,
    gateway VARCHAR(50) NOT NULL COMMENT 'stripe, paypal, etc',
    refund_amount DECIMAL(10,2) DEFAULT 0.00,
    refund_reason TEXT NULL,
    processed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);
```

**Key Fields**:
- `gateway`: Payment processor (Stripe, PayPal, etc.)
- `gateway_response`: Store provider-specific data
- `transaction_id`: External transaction reference

### Reviews Table

**Purpose**: Course ratings and feedback system.

```sql
CREATE TABLE reviews (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    course_id BIGINT UNSIGNED NOT NULL,
    rating TINYINT UNSIGNED NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NULL,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    helpful_count INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    UNIQUE KEY unique_review (user_id, course_id)
);
```

**Features**:
- 5-star rating system
- Moderation workflow (`is_approved`)
- Community voting (`helpful_count`)

### Coupons Table

**Purpose**: Discount and promotion management.

```sql
CREATE TABLE coupons (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    type ENUM('percentage', 'fixed') NOT NULL DEFAULT 'percentage',
    value DECIMAL(10,2) NOT NULL,
    minimum_amount DECIMAL(10,2) DEFAULT 0.00,
    maximum_discount DECIMAL(10,2) NULL,
    usage_limit INT UNSIGNED NULL,
    used_count INT UNSIGNED DEFAULT 0,
    valid_from TIMESTAMP NOT NULL,
    valid_until TIMESTAMP NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Coupon Types**:
- `percentage`: Discount percentage (e.g., 20% off)
- `fixed`: Fixed amount discount (e.g., $10 off)

## Relationships and Constraints

### Foreign Key Relationships

1. **courses.instructor_id → users.id**
   - CASCADE DELETE: Remove courses when instructor is deleted
   
2. **courses.category_id → categories.id**
   - RESTRICT DELETE: Prevent category deletion if courses exist
   
3. **enrollments.user_id → users.id**
   - CASCADE DELETE: Remove enrollments when user is deleted
   
4. **enrollments.course_id → courses.id**
   - CASCADE DELETE: Remove enrollments when course is deleted

### Unique Constraints

- `users.email`: One account per email address
- `categories.name`: Unique category names
- `categories.slug`: URL-friendly identifiers
- `enrollments(user_id, course_id)`: One enrollment per user per course
- `reviews(user_id, course_id)`: One review per user per course

## Performance Considerations

### Indexing Strategy

1. **Primary Keys**: Auto-indexed
2. **Foreign Keys**: Indexed for join performance
3. **Search Fields**: Full-text indexes on course titles/descriptions
4. **Filter Fields**: Indexes on status, role, and date fields

### Query Optimization

1. **Course Listings**: Use materialized statistics (total_enrollments, average_rating)
2. **Progress Calculation**: Denormalized progress percentage in enrollments
3. **Search**: Full-text search on courses with category filtering

## Common Query Patterns

### User Authentication
```sql
SELECT id, email, password, role, is_active 
FROM users 
WHERE email = ? AND is_active = 1;
```

### Course Catalog
```sql
SELECT c.*, cat.name as category_name, u.full_name as instructor_name
FROM courses c
JOIN categories cat ON c.category_id = cat.id
JOIN users u ON c.instructor_id = u.id
WHERE c.status = 'published'
ORDER BY c.featured DESC, c.created_at DESC;
```

### User Progress
```sql
SELECT e.*, c.title, 
       (SELECT COUNT(*) FROM lessons WHERE course_id = c.id) as total_lessons,
       (SELECT COUNT(*) FROM lesson_progress lp 
        WHERE lp.user_id = e.user_id AND lp.course_id = e.course_id AND lp.completed = 1) as completed_lessons
FROM enrollments e
JOIN courses c ON e.course_id = c.id
WHERE e.user_id = ?;
```

## Data Integrity Rules

1. **Email Validation**: Ensure valid email format at application level
2. **Password Security**: Hash passwords with bcrypt (minimum cost 10)
3. **Progress Bounds**: Progress percentage must be between 0.00 and 100.00
4. **Rating Bounds**: Review ratings must be between 1 and 5
5. **Price Validation**: Prices must be non-negative
6. **Date Consistency**: Enrollment date ≤ Progress dates ≤ Completion date

## Security Considerations

1. **User Roles**: Implement role-based access control
2. **Data Encryption**: Encrypt sensitive data at rest
3. **SQL Injection**: Use parameterized queries
4. **Audit Trail**: Log important data changes
5. **Privacy**: Implement GDPR compliance for user data

## Backup and Maintenance

1. **Daily Backups**: Automated encrypted backups with retention
2. **Index Maintenance**: Regular ANALYZE TABLE operations
3. **Statistics Updates**: Refresh course statistics nightly
4. **Log Rotation**: Manage MySQL slow query and error logs

This schema provides a solid foundation for a scalable online learning platform with room for future enhancements and optimizations. 