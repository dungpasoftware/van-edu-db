-- Van Edu Premium Subscription Platform - Sample Data
-- Version: 2.0 - PostgreSQL
-- Architecture: Premium subscription platform with QR payment system

-- Connect to the database
\c van_edu_db;

-- Clear existing data (PostgreSQL syntax)
TRUNCATE TABLE payment_transaction RESTART IDENTITY CASCADE;
TRUNCATE TABLE lessons RESTART IDENTITY CASCADE;
TRUNCATE TABLE courses RESTART IDENTITY CASCADE;
TRUNCATE TABLE categories RESTART IDENTITY CASCADE;
TRUNCATE TABLE package RESTART IDENTITY CASCADE;
TRUNCATE TABLE users RESTART IDENTITY CASCADE;

-- Insert subscription packages
INSERT INTO package (name, type, description, price, duration_days, is_active) VALUES
('Monthly Premium', 'monthly', 'Get unlimited access to all courses and premium content for 30 days', 9.99, 30, TRUE),
('Annual Premium', 'annual', 'Get unlimited access to all courses and premium content for 12 months. Save 40%!', 71.99, 365, TRUE),
('Lifetime Premium', 'lifetime', 'Get unlimited access to all courses and premium content forever. One-time payment!', 199.99, NULL, TRUE);

-- Insert sample users with admin permissions
INSERT INTO users (full_name, email, password, phone, address, age, role, is_premium, premium_expiry_date, current_package, permissions) VALUES
-- Admin users
('Admin Super User', 'admin@vanedu.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBdXIG/QYuZ7NW', '+1234567890', '123 Admin Street, Tech City', 30, 'admin', FALSE, NULL, NULL, 
'["upload_video", "edit_video", "delete_video", "create_category", "edit_category", "delete_category", "view_users", "edit_users", "delete_users", "view_analytics", "manage_settings"]'::jsonb),

('Content Manager', 'content@vanedu.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBdXIG/QYuZ7NW', '+1234567891', '456 Content Ave, Media City', 28, 'admin', FALSE, NULL, NULL, 
'["upload_video", "edit_video", "create_category", "edit_category"]'::jsonb),

-- Normal users - Free accounts
('John Smith', 'john@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBdXIG/QYuZ7NW', '+1555123456', '789 Student Lane, Learning City', 22, 'user', FALSE, NULL, NULL, NULL),
('Sarah Johnson', 'sarah@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBdXIG/QYuZ7NW', '+1555123457', '321 Knowledge Street, Study Town', 25, 'user', FALSE, NULL, NULL, NULL),

-- Premium users
('Michael Brown', 'michael@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBdXIG/QYuZ7NW', '+1555123458', '654 Premium Blvd, Elite District', 29, 'user', TRUE, '2024-12-31 23:59:59'::timestamp, 'monthly', NULL),
('Emily Davis', 'emily@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBdXIG/QYuZ7NW', '+1555123459', '987 Annual Ave, Subscriber City', 26, 'user', TRUE, '2025-06-30 23:59:59'::timestamp, 'annual', NULL),
('David Wilson', 'david@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBdXIG/QYuZ7NW', '+1555123460', '147 Lifetime Lane, Forever City', 35, 'user', TRUE, NULL, 'lifetime', NULL);

-- Insert categories
INSERT INTO categories (name, description, is_active) VALUES
('Web Development', 'Learn modern web development technologies and frameworks', TRUE),
('Mobile Development', 'Build mobile applications for iOS and Android', TRUE),
('Data Science', 'Master data analysis, machine learning, and AI', TRUE),
('Design', 'User interface and user experience design courses', TRUE),
('DevOps', 'Deployment, infrastructure, and automation tools', TRUE),
('Business', 'Entrepreneurship, marketing, and business strategy', TRUE);

-- Insert courses
INSERT INTO courses (title, description, category_id, thumbnail_url, is_premium, is_active) VALUES
-- Web Development Courses
('Complete JavaScript Mastery', 'Master JavaScript from basics to advanced concepts including ES6+, async programming, and modern frameworks', 1, 'https://example.com/thumbnails/javascript.jpg', TRUE, TRUE),
('React.js for Beginners', 'Learn React.js from scratch and build modern web applications with hooks and context', 1, 'https://example.com/thumbnails/react.jpg', TRUE, TRUE),
('Full Stack Development', 'Complete full-stack development course covering frontend, backend, and database integration', 1, 'https://example.com/thumbnails/fullstack.jpg', TRUE, TRUE),

-- Mobile Development Courses  
('iOS Development with Swift', 'Build native iOS applications using Swift and Xcode', 2, 'https://example.com/thumbnails/ios.jpg', TRUE, TRUE),
('React Native Mobile Apps', 'Create cross-platform mobile apps with React Native', 2, 'https://example.com/thumbnails/reactnative.jpg', TRUE, TRUE),

-- Data Science Courses
('Python for Data Science', 'Complete data science course using Python, pandas, and machine learning', 3, 'https://example.com/thumbnails/datascience.jpg', TRUE, TRUE),
('Machine Learning Fundamentals', 'Learn machine learning algorithms and implement them from scratch', 3, 'https://example.com/thumbnails/ml.jpg', TRUE, TRUE),

-- Design Courses
('UI/UX Design Masterclass', 'Complete design course covering user research, wireframing, and prototyping', 4, 'https://example.com/thumbnails/uiux.jpg', TRUE, TRUE),
('Adobe Creative Suite', 'Master Photoshop, Illustrator, and other Adobe tools for design', 4, 'https://example.com/thumbnails/adobe.jpg', TRUE, TRUE),

-- Free introductory course
('Introduction to Programming', 'Free introductory course to get started with programming concepts', 1, 'https://example.com/thumbnails/intro.jpg', FALSE, TRUE);

-- Insert lessons for JavaScript course
INSERT INTO lessons (course_id, title, content, video_url, duration, lesson_order, is_premium) VALUES
-- JavaScript Course (Course ID: 1)
(1, 'Introduction to JavaScript', 'Learn what JavaScript is and why it''s important for web development', 'https://example.com/videos/js-intro.mp4', 900, 1, TRUE),
(1, 'Variables and Data Types', 'Understanding variables, strings, numbers, and boolean values in JavaScript', 'https://example.com/videos/js-variables.mp4', 1200, 2, TRUE),
(1, 'Functions and Scope', 'Master JavaScript functions, parameters, and variable scope', 'https://example.com/videos/js-functions.mp4', 1800, 3, TRUE),
(1, 'DOM Manipulation', 'Learn how to interact with HTML elements using JavaScript', 'https://example.com/videos/js-dom.mp4', 2400, 4, TRUE),
(1, 'Async JavaScript & Promises', 'Understanding asynchronous programming and promises', 'https://example.com/videos/js-async.mp4', 2700, 5, TRUE),

-- React Course (Course ID: 2)
(2, 'React Introduction', 'Getting started with React.js and understanding components', 'https://example.com/videos/react-intro.mp4', 1200, 1, TRUE),
(2, 'JSX and Components', 'Learn JSX syntax and how to create reusable components', 'https://example.com/videos/react-jsx.mp4', 1500, 2, TRUE),
(2, 'State and Props', 'Managing component state and passing data through props', 'https://example.com/videos/react-state.mp4', 1800, 3, TRUE),
(2, 'React Hooks', 'Modern React development with hooks like useState and useEffect', 'https://example.com/videos/react-hooks.mp4', 2100, 4, TRUE),

-- Free course lessons (Course ID: 10)
(10, 'What is Programming?', 'Introduction to programming concepts and logic', 'https://example.com/videos/intro-programming.mp4', 600, 1, FALSE),
(10, 'Your First Code', 'Write your first simple program', 'https://example.com/videos/first-code.mp4', 900, 2, FALSE);

-- Insert sample payment transactions
INSERT INTO payment_transaction (user_id, package_id, amount, status, qr_code_data, reference_number, expires_at, confirmed_by_id, confirmed_at, notes) VALUES
-- Confirmed payments
(5, 1, 9.99, 'confirmed', 
'{"bank":"Bank ABC","account":"1234567890","amount":9.99,"reference":"PAY001"}', 
'PAY001REF2024', 
CURRENT_TIMESTAMP + INTERVAL '24 hours', 
1, 
CURRENT_TIMESTAMP, 
'Payment confirmed by admin - Monthly subscription activated'),

(6, 2, 71.99, 'confirmed', 
'{"bank":"Bank XYZ","account":"0987654321","amount":71.99,"reference":"PAY002"}', 
'PAY002REF2024', 
CURRENT_TIMESTAMP + INTERVAL '24 hours', 
1, 
CURRENT_TIMESTAMP - INTERVAL '2 hours', 
'Payment confirmed by admin - Annual subscription activated'),

(7, 3, 199.99, 'confirmed', 
'{"bank":"Bank DEF","account":"1122334455","amount":199.99,"reference":"PAY003"}', 
'PAY003REF2024', 
CURRENT_TIMESTAMP + INTERVAL '24 hours', 
2, 
CURRENT_TIMESTAMP - INTERVAL '1 day', 
'Payment confirmed by content manager - Lifetime subscription activated'),

-- Pending payments
(3, 1, 9.99, 'pending', 
'{"bank":"Bank GHI","account":"5566778899","amount":9.99,"reference":"PAY004"}', 
'PAY004REF2024', 
CURRENT_TIMESTAMP + INTERVAL '20 hours', 
NULL, 
NULL, 
NULL),

(4, 2, 71.99, 'pending', 
'{"bank":"Bank JKL","account":"9988776655","amount":71.99,"reference":"PAY005"}', 
'PAY005REF2024', 
CURRENT_TIMESTAMP + INTERVAL '18 hours', 
NULL, 
NULL, 
NULL),

-- Expired payment
(3, 1, 9.99, 'expired', 
'{"bank":"Bank MNO","account":"1357924680","amount":9.99,"reference":"PAY006"}', 
'PAY006REF2024', 
CURRENT_TIMESTAMP - INTERVAL '2 hours', 
NULL, 
NULL, 
'Payment expired - QR code timed out');

-- Display seeded data summary
SELECT 'SEEDING COMPLETED' as status;
SELECT 'Users created:' as info, COUNT(*) as count FROM users;
SELECT 'Packages created:' as info, COUNT(*) as count FROM package;
SELECT 'Categories created:' as info, COUNT(*) as count FROM categories;
SELECT 'Courses created:' as info, COUNT(*) as count FROM courses;
SELECT 'Lessons created:' as info, COUNT(*) as count FROM lessons;
SELECT 'Payment transactions created:' as info, COUNT(*) as count FROM payment_transaction;

-- Show premium users
SELECT 
    full_name, 
    email, 
    role,
    is_premium, 
    premium_expiry_date, 
    current_package 
FROM users 
WHERE role = 'user' 
ORDER BY is_premium DESC, full_name;

-- Show payment transaction status summary
SELECT 
    status, 
    COUNT(*) as count, 
    SUM(amount) as total_amount 
FROM payment_transaction 
GROUP BY status; 