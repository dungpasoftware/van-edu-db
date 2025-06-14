# Van Edu Premium Subscription Platform - PostgreSQL Makefile
# Simplifies common database operations

.PHONY: help build up down restart logs backup restore migrate seed clean status

# Default target
help: ## Show this help message
	@echo "Van Edu Premium Subscription Platform - PostgreSQL Management"
	@echo "============================================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Environment files:"
	@echo "  - Copy env.example to .env and configure your settings"
	@echo "  - Set BACKUP_ENCRYPTION_KEY for secure backups"

# Docker Operations
build: ## Build PostgreSQL container
	docker-compose build

up: ## Start the database services
	docker-compose up -d
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 10
	@make status

up-dev: ## Start services with pgAdmin for development
	docker-compose --profile dev up -d
	@echo "Waiting for services to be ready..."
	@sleep 15
	@make status
	@echo ""
	@echo "🌐 pgAdmin: http://localhost:8080"

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	@make down
	@make up

logs: ## Show container logs
	docker-compose logs -f postgres

logs-all: ## Show all service logs
	docker-compose logs -f

status: ## Show service status
	@echo "Service Status:"
	@docker-compose ps
	@echo ""
	@echo "Database Connection Test:"
	@docker exec van-edu-postgres pg_isready -U $(POSTGRES_USER) -d $(POSTGRES_DB) 2>/dev/null && echo "✅ PostgreSQL is running" || echo "❌ PostgreSQL is not responding"

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
	@docker exec -i van-edu-postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) < scripts/init/03-seed-data.sql
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
psql: ## Connect to PostgreSQL as superuser
	docker exec -it van-edu-postgres psql -U postgres

psql-app: ## Connect to PostgreSQL as application user
	docker exec -it van-edu-postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

psql-readonly: ## Connect to PostgreSQL as readonly user
	docker exec -it van-edu-postgres psql -U van_edu_readonly -d $(POSTGRES_DB)

psql-admin: ## Connect to PostgreSQL as admin user
	docker exec -it van-edu-postgres psql -U van_edu_admin -d $(POSTGRES_DB)

# Development Operations
reset: ## Reset database (WARNING: destroys all data)
	@echo "⚠️  WARNING: This will destroy all database data!"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@make down
	@docker volume rm van-edu-postgres-data || true
	@docker volume rm van-edu-postgres-logs || true
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
	@docker exec van-edu-postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "\
		SELECT 'Users' as table_name, COUNT(*) as count FROM users \
		UNION ALL SELECT 'Premium Users', COUNT(*) FROM users WHERE is_premium = TRUE \
		UNION ALL SELECT 'Admin Users', COUNT(*) FROM users WHERE role = 'admin' \
		UNION ALL SELECT 'Packages', COUNT(*) FROM package \
		UNION ALL SELECT 'Payment Transactions', COUNT(*) FROM payment_transaction \
		UNION ALL SELECT 'Confirmed Payments', COUNT(*) FROM payment_transaction WHERE status = 'confirmed' \
		UNION ALL SELECT 'Pending Payments', COUNT(*) FROM payment_transaction WHERE status = 'pending' \
		UNION ALL SELECT 'Categories', COUNT(*) FROM categories \
		UNION ALL SELECT 'Courses', COUNT(*) FROM courses \
		UNION ALL SELECT 'Premium Courses', COUNT(*) FROM courses WHERE is_premium = TRUE \
		UNION ALL SELECT 'Lessons', COUNT(*) FROM lessons \
		UNION ALL SELECT 'Premium Lessons', COUNT(*) FROM lessons WHERE is_premium = TRUE;"

tables: ## List all tables
	@docker exec van-edu-postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "\dt"

describe: ## Describe table structure (usage: make describe TABLE=users)
	@docker exec van-edu-postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "\d $(TABLE)"

performance: ## Show performance metrics
	@echo "PostgreSQL Performance Metrics:"
	@docker exec van-edu-postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "\
		SELECT 'Database Size' as metric, pg_size_pretty(pg_database_size('$(POSTGRES_DB)')) as value \
		UNION ALL SELECT 'Active Connections', COUNT(*)::text FROM pg_stat_activity WHERE state = 'active' \
		UNION ALL SELECT 'Total Connections', COUNT(*)::text FROM pg_stat_activity \
		UNION ALL SELECT 'Cache Hit Ratio', ROUND(100.0 * sum(blks_hit) / (sum(blks_hit) + sum(blks_read)), 2)::text || '%' FROM pg_stat_database WHERE datname = '$(POSTGRES_DB)';"

# Security Operations
create-users: ## Create additional database users
	@echo "Creating database users..."
	@docker exec van-edu-postgres psql -U postgres -d $(POSTGRES_DB) < scripts/init/02-create-user.sql
	@echo "✅ Database users created"

check-permissions: ## Check user permissions
	@echo "Database User Permissions:"
	@docker exec van-edu-postgres psql -U postgres -d $(POSTGRES_DB) -c "\
		SELECT usename as user, \
		       CASE WHEN usesuper THEN 'Yes' ELSE 'No' END as superuser, \
		       CASE WHEN usecreatedb THEN 'Yes' ELSE 'No' END as create_db \
		FROM pg_user WHERE usename LIKE 'van_edu_%' ORDER BY usename;"

# Premium Operations
premium-stats: ## Show premium subscription statistics
	@echo "Premium Subscription Statistics:"
	@docker exec van-edu-postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "\
		SELECT p.name as package, p.price, COUNT(pt.id) as purchases, \
		       SUM(CASE WHEN pt.status='confirmed' THEN pt.amount ELSE 0 END) as revenue \
		FROM package p LEFT JOIN payment_transaction pt ON p.id = pt.package_id \
		GROUP BY p.id, p.name, p.price ORDER BY revenue DESC;"

payment-status: ## Show payment transaction status
	@echo "Payment Transaction Status:"
	@docker exec van-edu-postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "\
		SELECT status, COUNT(*) as count, SUM(amount) as total_amount, AVG(amount) as avg_amount \
		FROM payment_transaction GROUP BY status;"

expire-premium: ## Check for expired premium subscriptions
	@echo "Checking for expired premium subscriptions..."
	@docker exec van-edu-postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "\
		SELECT full_name, email, premium_expiry_date, current_package \
		FROM users WHERE is_premium = TRUE AND premium_expiry_date < CURRENT_TIMESTAMP;"

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
	@echo "2. PostgreSQL Connection:"
	@docker exec van-edu-postgres pg_isready -U $(POSTGRES_USER) -d $(POSTGRES_DB) 2>/dev/null && echo "✅ PostgreSQL connection: OK" || echo "❌ PostgreSQL connection: FAILED"
	@echo ""
	@echo "3. Database Exists:"
	@docker exec van-edu-postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "SELECT 'Database exists' as status;" -t 2>/dev/null && echo "✅ Database: OK" || echo "❌ Database: FAILED"
	@echo ""
	@echo "4. Tables Count:"
	@docker exec van-edu-postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" -t 2>/dev/null | xargs echo "Tables found:"
	@echo ""
	@echo "5. Disk Usage:"
	@docker exec van-edu-postgres df -h /var/lib/postgresql/data
	@echo ""

# Utility Commands
wait: ## Wait for database to be ready
	@echo "Waiting for database to be ready..."
	@while ! docker exec van-edu-postgres pg_isready -U $(POSTGRES_USER) -d $(POSTGRES_DB) 2>/dev/null; do \
		echo "Waiting for PostgreSQL..."; \
		sleep 2; \
	done
	@echo "✅ Database is ready"

# Load environment variables
ifneq (,$(wildcard .env))
    include .env
    export
endif 