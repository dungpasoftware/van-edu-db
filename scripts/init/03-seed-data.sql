-- Sample data for Van Edu platform
-- This script populates the database with test data

USE van_edu_db;

-- Insert sample categories
INSERT INTO categories (name, description, slug, sort_order) VALUES
('Programming', 'Learn programming languages and software development', 'programming', 1),
('Web Development', 'Frontend and backend web development courses', 'web-development', 2),
('Data Science', 'Data analysis, machine learning, and AI courses', 'data-science', 3),
('Design', 'UI/UX design, graphic design, and visual arts', 'design', 4),
('Business', 'Business skills, entrepreneurship, and management', 'business', 5),
('Languages', 'Foreign language learning courses', 'languages', 6);

-- Insert subcategories
INSERT INTO categories (name, description, slug, parent_id, sort_order) VALUES
('JavaScript', 'JavaScript programming courses', 'javascript', 1, 1),
('Python', 'Python programming courses', 'python', 1, 2),
('React', 'React.js frontend development', 'react', 2, 1),
('Node.js', 'Backend development with Node.js', 'nodejs', 2, 2),
('Machine Learning', 'ML algorithms and applications', 'machine-learning', 3, 1),
('UI Design', 'User interface design principles', 'ui-design', 4, 1);

-- Insert sample users (passwords are hashed - in real app use bcrypt)
INSERT INTO users (email, password, full_name, role, phone, age) VALUES
('admin@vanedu.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin User', 'admin', '+1234567890', 30),
('instructor1@vanedu.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'John Smith', 'instructor', '+1234567891', 35),
('instructor2@vanedu.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Sarah Johnson', 'instructor', '+1234567892', 28),
('student1@vanedu.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Mike Davis', 'student', '+1234567893', 22),
('student2@vanedu.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Emma Wilson', 'student', '+1234567894', 24),
('student3@vanedu.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Alex Brown', 'student', '+1234567895', 26);

-- Insert sample courses
INSERT INTO courses (title, description, short_description, price, original_price, instructor_id, category_id, status, level, duration_minutes, requirements, what_you_learn, target_audience, featured, published_at) VALUES
(
    'Complete JavaScript Bootcamp 2024',
    'Master JavaScript from basics to advanced concepts. This comprehensive course covers ES6+, DOM manipulation, async programming, and modern frameworks.',
    'Learn JavaScript from zero to hero with hands-on projects',
    89.99,
    199.99,
    2,
    7,
    'published',
    'beginner',
    1200,
    '["Basic computer knowledge", "No programming experience required"]',
    '["JavaScript fundamentals", "DOM manipulation", "Async programming", "ES6+ features", "Project development"]',
    '["Complete beginners", "Self-taught developers", "Career changers"]',
    TRUE,
    NOW()
),
(
    'React.js - The Complete Guide',
    'Build powerful web applications with React.js. Learn hooks, context, routing, and state management with real-world projects.',
    'Master React.js with practical projects and modern techniques',
    129.99,
    249.99,
    2,
    9,
    'published',
    'intermediate',
    1800,
    '["JavaScript knowledge", "HTML & CSS basics", "Basic programming concepts"]',
    '["React components", "Hooks and state management", "Routing", "API integration", "Testing"]',
    '["JavaScript developers", "Frontend developers", "Web developers"]',
    TRUE,
    NOW()
),
(
    'Python for Data Science',
    'Learn Python programming for data analysis, visualization, and machine learning. Includes pandas, numpy, matplotlib, and scikit-learn.',
    'Complete Python data science course with real projects',
    149.99,
    299.99,
    3,
    11,
    'published',
    'intermediate',
    2400,
    '["Basic math knowledge", "No programming experience required"]',
    '["Python programming", "Data analysis with pandas", "Data visualization", "Machine learning basics", "Statistical analysis"]',
    '["Data enthusiasts", "Career changers", "Students", "Professionals"]',
    FALSE,
    NOW()
),
(
    'UI/UX Design Fundamentals',
    'Master the principles of user interface and user experience design. Learn design thinking, prototyping, and industry-standard tools.',
    'Complete guide to UI/UX design principles and tools',
    99.99,
    179.99,
    3,
    12,
    'published',
    'beginner',
    900,
    '["Basic computer skills", "Design interest", "No experience required"]',
    '["Design principles", "User research", "Wireframing", "Prototyping", "Design tools"]',
    '["Aspiring designers", "Developers", "Entrepreneurs", "Students"]',
    FALSE,
    NOW()
);

-- Insert sample lessons for JavaScript course
INSERT INTO lessons (course_id, title, content, video_duration, sort_order, is_free) VALUES
(1, 'Introduction to JavaScript', 'Welcome to the JavaScript bootcamp! In this lesson, we will cover what JavaScript is and why it is important for web development.', 480, 1, TRUE),
(1, 'Variables and Data Types', 'Learn about JavaScript variables, let, const, and different data types including strings, numbers, booleans, arrays, and objects.', 720, 2, TRUE),
(1, 'Functions and Scope', 'Understanding JavaScript functions, parameters, return values, and scope concepts.', 900, 3, FALSE),
(1, 'DOM Manipulation', 'Learn how to interact with HTML elements using JavaScript and the Document Object Model.', 1080, 4, FALSE),
(1, 'Event Handling', 'Master JavaScript events, event listeners, and creating interactive web pages.', 840, 5, FALSE);

-- Insert sample lessons for React course
INSERT INTO lessons (course_id, title, content, video_duration, sort_order, is_free) VALUES
(2, 'React Introduction', 'Introduction to React.js, component-based architecture, and setting up your development environment.', 600, 1, TRUE),
(2, 'Components and JSX', 'Learn about React components, JSX syntax, and how to create your first React components.', 780, 2, FALSE),
(3, 'Python Basics', 'Introduction to Python programming language, syntax, and basic concepts.', 540, 1, TRUE),
(4, 'Design Principles', 'Fundamental principles of good design: contrast, repetition, alignment, and proximity.', 420, 1, TRUE);

-- Insert sample enrollments
INSERT INTO enrollments (user_id, course_id, progress) VALUES
(4, 1, 45.50),
(4, 2, 12.25),
(5, 1, 78.90),
(5, 3, 23.75),
(6, 1, 100.00),
(6, 4, 56.30);

-- Insert sample lesson progress
INSERT INTO lesson_progress (user_id, lesson_id, course_id, completed, watch_time) VALUES
(4, 1, 1, TRUE, 480),
(4, 2, 1, TRUE, 720),
(4, 3, 1, FALSE, 450),
(5, 1, 1, TRUE, 480),
(5, 2, 1, TRUE, 720),
(5, 3, 1, TRUE, 900),
(5, 4, 1, FALSE, 320),
(6, 1, 1, TRUE, 480),
(6, 2, 1, TRUE, 720),
(6, 3, 1, TRUE, 900),
(6, 4, 1, TRUE, 1080),
(6, 5, 1, TRUE, 840);

-- Insert sample payments
INSERT INTO payments (user_id, course_id, amount, status, payment_method, transaction_id, gateway, processed_at) VALUES
(4, 1, 89.99, 'completed', 'credit_card', 'txn_1234567890', 'stripe', NOW()),
(4, 2, 129.99, 'completed', 'paypal', 'pp_9876543210', 'paypal', NOW()),
(5, 1, 89.99, 'completed', 'credit_card', 'txn_1234567891', 'stripe', NOW()),
(5, 3, 149.99, 'completed', 'credit_card', 'txn_1234567892', 'stripe', NOW()),
(6, 1, 89.99, 'completed', 'credit_card', 'txn_1234567893', 'stripe', NOW()),
(6, 4, 99.99, 'completed', 'paypal', 'pp_9876543211', 'paypal', NOW());

-- Insert sample reviews
INSERT INTO reviews (user_id, course_id, rating, comment, is_approved) VALUES
(5, 1, 5, 'Excellent course! Very comprehensive and easy to follow. The instructor explains everything clearly.', TRUE),
(6, 1, 4, 'Great content and practical examples. Would recommend to anyone starting with JavaScript.', TRUE),
(4, 1, 5, 'Amazing course structure and pacing. Perfect for beginners!', TRUE),
(6, 4, 5, 'Best UI/UX course I have taken. Very practical and industry-relevant.', TRUE);

-- Insert sample coupons
INSERT INTO coupons (code, type, value, minimum_amount, usage_limit, valid_from, valid_until) VALUES
('WELCOME20', 'percentage', 20.00, 50.00, 100, NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY)),
('STUDENT50', 'fixed', 50.00, 100.00, 50, NOW(), DATE_ADD(NOW(), INTERVAL 60 DAY)),
('BLACKFRIDAY', 'percentage', 40.00, 0.00, 1000, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY));

-- Update course statistics
UPDATE courses SET 
    total_lessons = (SELECT COUNT(*) FROM lessons WHERE course_id = courses.id),
    total_enrollments = (SELECT COUNT(*) FROM enrollments WHERE course_id = courses.id),
    average_rating = (SELECT ROUND(AVG(rating), 2) FROM reviews WHERE course_id = courses.id AND is_approved = TRUE),
    total_reviews = (SELECT COUNT(*) FROM reviews WHERE course_id = courses.id AND is_approved = TRUE);

-- Update enrollment completion status
UPDATE enrollments SET 
    status = 'completed',
    completed_at = NOW()
WHERE progress = 100.00; 