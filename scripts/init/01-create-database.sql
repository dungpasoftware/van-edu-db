-- Van Edu Premium Subscription Platform Database Schema
-- Version: 2.0
-- Architecture: Premium subscription platform with QR payment system
-- Created: 2024

USE van_edu_db;

-- Enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Users table - Premium subscription model
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fullName VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL COMMENT 'bcrypt hashed password',
    phone VARCHAR(255) NULL,
    address TEXT NULL,
    age INT NULL,
    role ENUM('user', 'admin') NOT NULL DEFAULT 'user',
    isPremium BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Premium access status for normal users',
    premiumExpiryDate DATETIME NULL COMMENT 'null for lifetime packages',
    currentPackage VARCHAR(50) NULL COMMENT 'monthly/annual/lifetime',
    permissions JSON NULL COMMENT 'Admin permissions array',
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_premium (isPremium),
    INDEX idx_premium_expiry (premiumExpiryDate),
    INDEX idx_created_at (createdAt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Package table - Subscription plans
CREATE TABLE package (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL COMMENT 'Monthly Premium, Annual Premium, Lifetime Premium',
    type VARCHAR(50) NOT NULL UNIQUE COMMENT 'monthly/annual/lifetime',
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    durationDays INT NULL COMMENT 'null for lifetime packages',
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_type (type),
    INDEX idx_active (isActive),
    INDEX idx_price (price)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Payment Transaction table - QR code payment system
CREATE TABLE payment_transaction (
    id INT AUTO_INCREMENT PRIMARY KEY,
    userId INT NOT NULL,
    packageId INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'confirmed', 'expired', 'cancelled') NOT NULL DEFAULT 'pending',
    qrCodeData TEXT NULL COMMENT 'JSON string for QR payment data',
    referenceNumber VARCHAR(255) NOT NULL UNIQUE,
    expiresAt DATETIME NOT NULL COMMENT 'QR code expiry (24 hours)',
    confirmedById INT NULL COMMENT 'Admin who confirmed payment',
    confirmedAt DATETIME NULL,
    notes TEXT NULL COMMENT 'Admin notes',
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (packageId) REFERENCES package(id) ON DELETE RESTRICT,
    FOREIGN KEY (confirmedById) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (userId),
    INDEX idx_package_id (packageId),
    INDEX idx_status (status),
    INDEX idx_reference (referenceNumber),
    INDEX idx_expires_at (expiresAt),
    INDEX idx_confirmed_by (confirmedById),
    INDEX idx_created_at (createdAt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Categories table - Content organization
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NULL,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_active (isActive)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Courses table - Content structure
CREATE TABLE courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    categoryId INT NOT NULL,
    thumbnailUrl VARCHAR(500) NULL,
    isPremium BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Most content is premium',
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE RESTRICT,
    INDEX idx_title (title),
    INDEX idx_category_id (categoryId),
    INDEX idx_premium (isPremium),
    INDEX idx_active (isActive),
    FULLTEXT idx_search (title, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Lessons table - Individual content units
CREATE TABLE lessons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    courseId INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    content LONGTEXT NULL,
    videoUrl VARCHAR(500) NULL,
    duration INT NULL COMMENT 'Duration in seconds',
    lessonOrder INT NOT NULL DEFAULT 0,
    isPremium BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Premium content flag',
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE,
    INDEX idx_course_id (courseId),
    INDEX idx_order (lessonOrder),
    INDEX idx_premium (isPremium),
    FULLTEXT idx_content (title, content)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 