# Van Edu Database Makefile
# Simplifies common database operations

.PHONY: help build up down restart logs backup restore migrate seed clean status

# Default target
help: ## Show this help message
	@echo "Van Edu Database Management Commands"
	@echo "===================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Environment files:"
	@echo "  - Copy env.example to .env and configure your settings"
	@echo "  - Set BACKUP_ENCRYPTION_KEY for secure backups"

# Docker Operations
build: ## Build MySQL container
	docker-compose build

up: ## Start the database services
	docker-compose up -d
	@echo "Waiting for MySQL to be ready..."
	@sleep 10
	@make status

up-dev: ## Start services with phpMyAdmin for development
	docker-compose --profile dev up -d
	@echo "Waiting for services to be ready..."
	@sleep 15
	@make status
	@echo ""
	@echo "🌐 phpMyAdmin: http://localhost:8080"

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	@make down
	@make up

logs: ## Show container logs
	docker-compose logs -f mysql

logs-all: ## Show all service logs
	docker-compose logs -f

status: ## Show service status
	@echo "Service Status:"
	@docker-compose ps
	@echo ""
	@echo "Database Connection Test:"
	@docker exec van-edu-mysql mysqladmin ping -h localhost -u root -p$(MYSQL_ROOT_PASSWORD) 2>/dev/null && echo "✅ MySQL is running" || echo "❌ MySQL is not responding"

# Database Operations
init: up migrate seed ## Initialize database (start, migrate, seed)
	@echo "🚀 Database initialized successfully!"
	@make status

migrate: ## Run database migrations
	@chmod +x scripts/migrate.sh
	@./scripts/migrate.sh

migrate-create: ## Create new migration (usage: make migrate-create NAME=add_user_avatar)
	@chmod +x scripts/migrate.sh
	@./scripts/migrate.sh create $(NAME)

migrate-status: ## Show migration status
	@chmod +x scripts/migrate.sh
	@./scripts/migrate.sh list

migrate-history: ## Show migration history
	@chmod +x scripts/migrate.sh
	@./scripts/migrate.sh history

seed: ## Seed database with sample data
	@echo "Seeding database with sample data..."
	@docker exec -i van-edu-mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) van_edu_db < scripts/init/03-seed-data.sql
	@echo "✅ Database seeded successfully"

# Backup Operations
backup: ## Create database backup
	@chmod +x scripts/backup.sh
	@./scripts/backup.sh

backup-no-cleanup: ## Create backup without cleanup
	@chmod +x scripts/backup.sh
	@./scripts/backup.sh --no-cleanup

restore: ## Restore database from backup (interactive)
	@chmod +x scripts/restore.sh
	@./scripts/restore.sh

restore-force: ## Force restore from latest backup
	@chmod +x scripts/restore.sh
	@./scripts/restore.sh -f

list-backups: ## List available backups
	@chmod +x scripts/restore.sh
	@./scripts/restore.sh -l

# Database Access
mysql: ## Connect to MySQL as root
	docker exec -it van-edu-mysql mysql -u root -p$(MYSQL_ROOT_PASSWORD)

mysql-app: ## Connect to MySQL as application user
	docker exec -it van-edu-mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) $(MYSQL_DATABASE)

mysql-readonly: ## Connect to MySQL as readonly user
	docker exec -it van-edu-mysql mysql -u van_edu_readonly -p readonly_secure_2024! $(MYSQL_DATABASE)

mysql-admin: ## Connect to MySQL as admin user
	docker exec -it van-edu-mysql mysql -u van_edu_admin -p admin_secure_2024! $(MYSQL_DATABASE)

# Development Operations
reset: ## Reset database (WARNING: destroys all data)
	@echo "⚠️  WARNING: This will destroy all database data!"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@make down
	@docker volume rm van-edu-mysql-data || true
	@docker volume rm van-edu-mysql-logs || true
	@make up
	@sleep 10
	@make migrate
	@make seed
	@echo "🔄 Database reset complete"

clean: ## Clean up containers and volumes
	@make down
	docker-compose down -v --remove-orphans
	docker volume prune -f
	docker system prune -f

# Monitoring Operations
stats: ## Show database statistics
	@echo "Van Edu Premium Platform Statistics:"
	@docker exec van-edu-mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) -e "\
		USE $(MYSQL_DATABASE); \
		SELECT 'Users' as Table_Name, COUNT(*) as Count FROM users \
		UNION ALL SELECT 'Premium Users', COUNT(*) FROM users WHERE isPremium = TRUE \
		UNION ALL SELECT 'Admin Users', COUNT(*) FROM users WHERE role = 'admin' \
		UNION ALL SELECT 'Packages', COUNT(*) FROM package \
		UNION ALL SELECT 'Payment Transactions', COUNT(*) FROM payment_transaction \
		UNION ALL SELECT 'Confirmed Payments', COUNT(*) FROM payment_transaction WHERE status = 'confirmed' \
		UNION ALL SELECT 'Pending Payments', COUNT(*) FROM payment_transaction WHERE status = 'pending' \
		UNION ALL SELECT 'Categories', COUNT(*) FROM categories \
		UNION ALL SELECT 'Courses', COUNT(*) FROM courses \
		UNION ALL SELECT 'Premium Courses', COUNT(*) FROM courses WHERE isPremium = TRUE \
		UNION ALL SELECT 'Lessons', COUNT(*) FROM lessons \
		UNION ALL SELECT 'Premium Lessons', COUNT(*) FROM lessons WHERE isPremium = TRUE;" --table

tables: ## List all tables
	@docker exec van-edu-mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) -e "USE $(MYSQL_DATABASE); SHOW TABLES;" --table

describe: ## Describe table structure (usage: make describe TABLE=users)
	@docker exec van-edu-mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) -e "USE $(MYSQL_DATABASE); DESCRIBE $(TABLE);" --table

performance: ## Show performance metrics
	@echo "MySQL Performance Metrics:"
	@docker exec van-edu-mysql mysql -u root -p$(MYSQL_ROOT_PASSWORD) -e "\
		SHOW GLOBAL STATUS WHERE Variable_name IN ('Connections', 'Uptime', 'Queries', 'Slow_queries', 'Threads_connected'); \
		SELECT ENGINE, COUNT(*) as Tables, ROUND(SUM(data_length)/1024/1024, 2) as 'Data(MB)', ROUND(SUM(index_length)/1024/1024, 2) as 'Index(MB)' \
		FROM information_schema.TABLES WHERE table_schema='$(MYSQL_DATABASE)' GROUP BY ENGINE;" --table

# Security Operations
create-users: ## Create additional database users
	@echo "Creating database users..."
	@docker exec van-edu-mysql mysql -u root -p$(MYSQL_ROOT_PASSWORD) < scripts/init/02-create-user.sql
	@echo "✅ Database users created"

check-permissions: ## Check user permissions
	@echo "Database User Permissions:"
	@docker exec van-edu-mysql mysql -u root -p$(MYSQL_ROOT_PASSWORD) -e "\
		SELECT User, Host, db, Select_priv, Insert_priv, Update_priv, Delete_priv \
		FROM mysql.db WHERE User LIKE 'van_edu_%' ORDER BY User;" --table

# Premium Operations
premium-stats: ## Show premium subscription statistics
	@echo "Premium Subscription Statistics:"
	@docker exec van-edu-mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) -e "\
		USE $(MYSQL_DATABASE); \
		SELECT p.name as Package, p.price as Price, COUNT(pt.id) as Purchases, SUM(CASE WHEN pt.status='confirmed' THEN pt.amount ELSE 0 END) as Revenue \
		FROM package p LEFT JOIN payment_transaction pt ON p.id = pt.packageId \
		GROUP BY p.id, p.name, p.price ORDER BY Revenue DESC;" --table

payment-status: ## Show payment transaction status
	@echo "Payment Transaction Status:"
	@docker exec van-edu-mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) -e "\
		USE $(MYSQL_DATABASE); \
		SELECT status, COUNT(*) as count, SUM(amount) as total_amount, AVG(amount) as avg_amount \
		FROM payment_transaction GROUP BY status;" --table

expire-premium: ## Check for expired premium subscriptions
	@echo "Checking for expired premium subscriptions..."
	@docker exec van-edu-mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) -e "\
		USE $(MYSQL_DATABASE); \
		SELECT fullName, email, premiumExpiryDate, currentPackage \
		FROM users WHERE isPremium = TRUE AND premiumExpiryDate < NOW();" --table

# Environment Operations
setup: ## Initial setup (copy env file, make scripts executable)
	@if [ ! -f .env ]; then \
		cp env.example .env; \
		echo "📝 Created .env file from env.example"; \
		echo "🔧 Please edit .env file with your configuration"; \
	else \
		echo "✅ .env file already exists"; \
	fi
	@chmod +x scripts/*.sh
	@echo "✅ Made scripts executable"
	@echo ""
	@echo "Next steps:"
	@echo "1. Edit .env file with your configuration"
	@echo "2. Run 'make init' to initialize the database"

# Health Checks
health: ## Run health checks
	@echo "🏥 Running health checks..."
	@echo ""
	@echo "1. Container Status:"
	@docker-compose ps
	@echo ""
	@echo "2. MySQL Connection:"
	@docker exec van-edu-mysql mysqladmin ping -h localhost -u root -p$(MYSQL_ROOT_PASSWORD) 2>/dev/null && echo "✅ MySQL connection: OK" || echo "❌ MySQL connection: FAILED"
	@echo ""
	@echo "3. Database Exists:"
	@docker exec van-edu-mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) -e "USE $(MYSQL_DATABASE); SELECT 'Database exists' as Status;" --silent 2>/dev/null && echo "✅ Database: OK" || echo "❌ Database: FAILED"
	@echo ""
	@echo "4. Tables Count:"
	@docker exec van-edu-mysql mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) -e "USE $(MYSQL_DATABASE); SELECT COUNT(*) as Tables FROM information_schema.tables WHERE table_schema='$(MYSQL_DATABASE)';" --silent --skip-column-names 2>/dev/null | xargs echo "Tables found:"
	@echo ""
	@echo "5. Disk Usage:"
	@docker exec van-edu-mysql df -h /var/lib/mysql
	@echo ""

# Utility Commands
wait: ## Wait for database to be ready
	@echo "Waiting for database to be ready..."
	@while ! docker exec van-edu-mysql mysqladmin ping -h localhost -u root -p$(MYSQL_ROOT_PASSWORD) 2>/dev/null; do \
		echo "Waiting for MySQL..."; \
		sleep 2; \
	done
	@echo "✅ Database is ready"

# Load environment variables
ifneq (,$(wildcard .env))
    include .env
    export
endif 