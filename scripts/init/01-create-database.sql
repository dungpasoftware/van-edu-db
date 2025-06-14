-- Van Edu Premium Subscription Platform Database Schema
-- Version: 2.0 - PostgreSQL
-- Architecture: Premium subscription platform with QR payment system
-- Created: 2024

-- Connect to the database
\c van_edu_db;

-- Enable UUID extension for better primary keys (optional)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pg_stat_statements for performance monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Users table - Premium subscription model
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- bcrypt hashed password
    phone VARCHAR(255),
    address TEXT,
    age INTEGER,
    role VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    is_premium BOOLEAN NOT NULL DEFAULT FALSE, -- Premium access status for normal users
    premium_expiry_date TIMESTAMP, -- null for lifetime packages
    current_package VARCHAR(50), -- monthly/annual/lifetime
    permissions JSONB, -- Admin permissions array
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for users table
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_premium ON users(is_premium);
CREATE INDEX idx_users_premium_expiry ON users(premium_expiry_date);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Package table - Subscription plans
CREATE TABLE package (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL, -- 'Monthly Premium', 'Annual Premium', 'Lifetime Premium'
    type VARCHAR(50) NOT NULL UNIQUE, -- monthly/annual/lifetime
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    duration_days INTEGER, -- null for lifetime packages
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for package table
CREATE INDEX idx_package_type ON package(type);
CREATE INDEX idx_package_active ON package(is_active);
CREATE INDEX idx_package_price ON package(price);

-- Payment Transaction table - QR code payment system
CREATE TABLE payment_transaction (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    package_id INTEGER NOT NULL REFERENCES package(id) ON DELETE RESTRICT,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'expired', 'cancelled')),
    qr_code_data TEXT, -- JSON string for QR payment data
    reference_number VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL, -- QR code expiry (24 hours)
    confirmed_by_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Admin who confirmed payment
    confirmed_at TIMESTAMP,
    notes TEXT, -- Admin notes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for payment_transaction table
CREATE INDEX idx_payment_user_id ON payment_transaction(user_id);
CREATE INDEX idx_payment_package_id ON payment_transaction(package_id);
CREATE INDEX idx_payment_status ON payment_transaction(status);
CREATE INDEX idx_payment_reference ON payment_transaction(reference_number);
CREATE INDEX idx_payment_expires_at ON payment_transaction(expires_at);
CREATE INDEX idx_payment_confirmed_by ON payment_transaction(confirmed_by_id);
CREATE INDEX idx_payment_created_at ON payment_transaction(created_at);

-- Categories table - Content organization
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for categories table
CREATE INDEX idx_categories_name ON categories(name);
CREATE INDEX idx_categories_active ON categories(is_active);

-- Courses table - Content structure
CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    thumbnail_url VARCHAR(500),
    is_premium BOOLEAN NOT NULL DEFAULT TRUE, -- Most content is premium
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for courses table
CREATE INDEX idx_courses_title ON courses(title);
CREATE INDEX idx_courses_category_id ON courses(category_id);
CREATE INDEX idx_courses_premium ON courses(is_premium);
CREATE INDEX idx_courses_active ON courses(is_active);

-- Create full-text search index for courses
CREATE INDEX idx_courses_search ON courses USING gin(to_tsvector('english', title || ' ' || description));

-- Lessons table - Individual content units
CREATE TABLE lessons (
    id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    video_url VARCHAR(500),
    duration INTEGER, -- Duration in seconds
    lesson_order INTEGER NOT NULL DEFAULT 0,
    is_premium BOOLEAN NOT NULL DEFAULT TRUE, -- Premium content flag
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for lessons table
CREATE INDEX idx_lessons_course_id ON lessons(course_id);
CREATE INDEX idx_lessons_order ON lessons(lesson_order);
CREATE INDEX idx_lessons_premium ON lessons(is_premium);

-- Create full-text search index for lessons
CREATE INDEX idx_lessons_search ON lessons USING gin(to_tsvector('english', title || ' ' || COALESCE(content, '')));

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at columns
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_package_updated_at BEFORE UPDATE ON package
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_transaction_updated_at BEFORE UPDATE ON payment_transaction
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create views for common queries
CREATE VIEW premium_users AS
SELECT 
    id,
    full_name,
    email,
    is_premium,
    premium_expiry_date,
    current_package,
    created_at
FROM users 
WHERE role = 'user' AND is_premium = TRUE;

CREATE VIEW payment_summary AS
SELECT 
    pt.id,
    u.full_name as user_name,
    u.email,
    p.name as package_name,
    pt.amount,
    pt.status,
    pt.reference_number,
    pt.expires_at,
    pt.created_at
FROM payment_transaction pt
JOIN users u ON pt.user_id = u.id
JOIN package p ON pt.package_id = p.id
ORDER BY pt.created_at DESC;

-- Create function to check if user has premium access
CREATE OR REPLACE FUNCTION check_premium_access(user_id_param INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    user_record RECORD;
BEGIN
    SELECT is_premium, premium_expiry_date INTO user_record
    FROM users 
    WHERE id = user_id_param AND role = 'user';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    IF NOT user_record.is_premium THEN
        RETURN FALSE;
    END IF;
    
    -- Check expiry (null = lifetime)
    IF user_record.premium_expiry_date IS NULL THEN
        RETURN TRUE;
    END IF;
    
    RETURN user_record.premium_expiry_date > CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Create function to expire premium subscriptions
CREATE OR REPLACE FUNCTION expire_premium_subscriptions()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE users 
    SET is_premium = FALSE, current_package = NULL
    WHERE is_premium = TRUE 
    AND premium_expiry_date IS NOT NULL 
    AND premium_expiry_date < CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions to application user (will be created in next script)
-- These will be applied after user creation 