# ArmyknifeLabs Platform Installer - Database Module
# Makefile.Database.mk
#
# The most comprehensive database development environment ever created
# Installs: PostgreSQL, MySQL, MariaDB, SQLite, MongoDB, Redis, Cassandra,
# Neo4j, InfluxDB, TimescaleDB, DuckDB, and all management tools
#
# Features: Multiple database engines, GUI tools, CLI tools, migration tools,
# backup utilities, monitoring, and performance tuning

# Import parent variables
ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-database-$(shell date +%Y%m%d-%H%M%S).log
DB_DIR := $(ARMYKNIFE_DIR)/databases
DB_DATA_DIR := $(HOME)/armyknife-db-data

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m

# Shell configuration - use bash for all commands
SHELL := /bin/bash
.SHELLFLAGS := -ec

# OS detection
OS_TYPE := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo macos)
OS_LIKE := $(shell . /etc/os-release 2>/dev/null && echo $$ID_LIKE || echo "")
IS_MACOS := $(shell if [ "$$(uname -s)" = "Darwin" ]; then echo true; else echo false; fi)
IS_LINUX := $(shell if [ "$$(uname -s)" = "Linux" ]; then echo true; else echo false; fi)
ARCH := $(shell uname -m)

# Package manager detection
ifeq ($(OS_TYPE),ubuntu)
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifeq ($(OS_TYPE),linuxmint)
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifeq ($(OS_TYPE),debian)
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifneq (,$(findstring ubuntu,$(OS_LIKE)))
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifneq (,$(findstring debian,$(OS_LIKE)))
    PACKAGE_MANAGER := apt
    SUDO := sudo
else ifeq ($(OS_TYPE),fedora)
    PACKAGE_MANAGER := dnf
    SUDO := sudo
else ifeq ($(IS_MACOS),true)
    PACKAGE_MANAGER := brew
    SUDO :=
endif

# Database versions
POSTGRESQL_VERSION := 18
MYSQL_VERSION := 8.0
MARIADB_VERSION := 11.2
MONGODB_VERSION := 7.0
REDIS_VERSION := 7.2
CASSANDRA_VERSION := 5.0
NEO4J_VERSION := 5

# Phony targets
.PHONY: all minimal install-system-deps install-postgresql install-mysql \
        install-mariadb install-sqlite install-mongodb install-redis \
        install-cassandra install-neo4j install-influxdb install-timescaledb \
        install-duckdb install-clickhouse install-tools install-gui-tools \
        install-cli-tools install-migration-tools install-backup-tools \
        install-database-monitoring configure-databases create-users setup-examples \
        verify-databases help-database start-services stop-services

# Main target - install everything
all: install-system-deps install-postgresql install-mysql install-sqlite \
     install-mongodb install-redis install-duckdb install-influxdb \
     install-timescaledb install-tools install-gui-tools install-cli-tools \
     install-migration-tools install-backup-tools configure-databases \
     create-users setup-examples verify-databases

# Minimal installation - just PostgreSQL, SQLite, and essential tools
minimal: install-system-deps install-postgresql install-sqlite \
         install-duckdb install-cli-tools configure-databases

# Developer profile - common databases for development
developer: install-system-deps install-postgresql install-mysql \
           install-redis install-mongodb install-sqlite install-duckdb \
           install-cli-tools install-migration-tools configure-databases

# Install system dependencies
install-system-deps:
	@echo -e "${BLUE}ℹ${NC} Installing database system dependencies..."
	@mkdir -p $$(dirname $(LOG_FILE))
	@mkdir -p $(DB_DIR) $(DB_DATA_DIR)
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) apt install -y \
		build-essential libssl-dev libreadline-dev zlib1g-dev \
		libpq-dev libmysqlclient-dev libsqlite3-dev \
		libbz2-dev libncurses5-dev libncursesw5-dev \
		libxml2-dev libxslt1-dev libffi-dev \
		wget curl gnupg lsb-release software-properties-common \
		2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@brew install \
		openssl readline sqlite3 \
		libpq mysql-client \
		2>/dev/null || true
endif
	@echo -e "${GREEN}✓${NC} System dependencies installed"

# Install PostgreSQL
install-postgresql:
	@echo -e "${BLUE}ℹ${NC} Installing PostgreSQL $(POSTGRESQL_VERSION)..."
ifeq ($(PACKAGE_MANAGER),apt)
	@# Add PostgreSQL official repository
	@$(SUDO) sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $$(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
	@wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | $(SUDO) apt-key add -
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) apt install -y \
		postgresql-$(POSTGRESQL_VERSION) \
		postgresql-client-$(POSTGRESQL_VERSION) \
		postgresql-contrib-$(POSTGRESQL_VERSION) \
		postgresql-$(POSTGRESQL_VERSION)-postgis-3 \
		postgresql-$(POSTGRESQL_VERSION)-pgvector \
		2>&1 | tee -a $(LOG_FILE) || \
		$(SUDO) apt install -y postgresql postgresql-client postgresql-contrib 2>&1 | tee -a $(LOG_FILE)
	@# Install extensions
	@$(SUDO) apt install -y \
		postgresql-$(POSTGRESQL_VERSION)-pgtap \
		postgresql-$(POSTGRESQL_VERSION)-pg-stat-kcache \
		postgresql-$(POSTGRESQL_VERSION)-pg-qualstats \
		2>/dev/null || true
else ifeq ($(IS_MACOS),true)
	@if ! command -v psql &> /dev/null; then \
		brew install postgresql@$(POSTGRESQL_VERSION); \
		brew services start postgresql@$(POSTGRESQL_VERSION); \
	else \
		echo -e "${GREEN}✓${NC} PostgreSQL already installed"; \
	fi
endif
	@echo -e "${GREEN}✓${NC} PostgreSQL installed"

# Install MySQL
install-mysql:
	@echo -e "${BLUE}ℹ${NC} Installing MySQL $(MYSQL_VERSION)..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt install -y mysql-server mysql-client 2>&1 | tee -a $(LOG_FILE)
	@$(SUDO) mysql_secure_installation 2>/dev/null || true
else ifeq ($(IS_MACOS),true)
	@if ! command -v mysql &> /dev/null; then \
		brew install mysql; \
		brew services start mysql; \
	else \
		echo -e "${GREEN}✓${NC} MySQL already installed"; \
	fi
endif
	@echo -e "${GREEN}✓${NC} MySQL installed"

# Install MariaDB
install-mariadb:
	@echo -e "${BLUE}ℹ${NC} Installing MariaDB..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt install -y mariadb-server mariadb-client 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@if ! command -v mariadb &> /dev/null; then \
		brew install mariadb; \
		brew services start mariadb; \
	else \
		echo -e "${GREEN}✓${NC} MariaDB already installed"; \
	fi
endif
	@echo -e "${GREEN}✓${NC} MariaDB installed"

# Install SQLite
install-sqlite:
	@echo -e "${BLUE}ℹ${NC} Installing SQLite..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt install -y sqlite3 libsqlite3-dev 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@brew install sqlite3 2>/dev/null || true
endif
	@echo -e "${GREEN}✓${NC} SQLite installed"

# Install MongoDB
install-mongodb:
	@echo -e "${BLUE}ℹ${NC} Installing MongoDB $(MONGODB_VERSION)..."
ifeq ($(PACKAGE_MANAGER),apt)
	@# Add MongoDB repository
	@curl -fsSL https://pgp.mongodb.com/server-$(MONGODB_VERSION).asc | \
		$(SUDO) gpg --dearmor -o /usr/share/keyrings/mongodb-server-$(MONGODB_VERSION).gpg
	@echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-$(MONGODB_VERSION).gpg ] \
		https://repo.mongodb.org/apt/ubuntu $$(lsb_release -cs)/mongodb-org/$(MONGODB_VERSION) multiverse" | \
		$(SUDO) tee /etc/apt/sources.list.d/mongodb-org-$(MONGODB_VERSION).list
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) apt install -y mongodb-org 2>&1 | tee -a $(LOG_FILE) || \
		$(SUDO) apt install -y mongodb 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@if ! command -v mongod &> /dev/null; then \
		brew tap mongodb/brew; \
		brew install mongodb-community; \
		brew services start mongodb-community; \
	else \
		echo -e "${GREEN}✓${NC} MongoDB already installed"; \
	fi
endif
	@echo -e "${GREEN}✓${NC} MongoDB installed"

# Install Redis
install-redis:
	@echo -e "${BLUE}ℹ${NC} Installing Redis..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt install -y redis-server redis-tools 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@if ! command -v redis-server &> /dev/null; then \
		brew install redis; \
		brew services start redis; \
	else \
		echo -e "${GREEN}✓${NC} Redis already installed"; \
	fi
endif
	@echo -e "${GREEN}✓${NC} Redis installed"

# Install Cassandra
install-cassandra:
	@echo -e "${BLUE}ℹ${NC} Installing Cassandra..."
ifeq ($(PACKAGE_MANAGER),apt)
	@echo "deb https://debian.cassandra.apache.org 41x main" | \
		$(SUDO) tee /etc/apt/sources.list.d/cassandra.list
	@curl https://downloads.apache.org/cassandra/KEYS | $(SUDO) apt-key add -
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) apt install -y cassandra 2>&1 | tee -a $(LOG_FILE) || true
else ifeq ($(IS_MACOS),true)
	@if ! command -v cassandra &> /dev/null; then \
		brew install cassandra; \
		brew services start cassandra; \
	else \
		echo -e "${GREEN}✓${NC} Cassandra already installed"; \
	fi
endif
	@echo -e "${GREEN}✓${NC} Cassandra installed"

# Install Neo4j
install-neo4j:
	@echo -e "${BLUE}ℹ${NC} Installing Neo4j..."
ifeq ($(PACKAGE_MANAGER),apt)
	@wget -O - https://debian.neo4j.com/neotechnology.gpg.key | $(SUDO) apt-key add -
	@echo 'deb https://debian.neo4j.com stable latest' | \
		$(SUDO) tee /etc/apt/sources.list.d/neo4j.list
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) apt install -y neo4j 2>&1 | tee -a $(LOG_FILE) || true
else ifeq ($(IS_MACOS),true)
	@if ! command -v neo4j &> /dev/null; then \
		brew install neo4j; \
	else \
		echo -e "${GREEN}✓${NC} Neo4j already installed"; \
	fi
endif
	@echo -e "${GREEN}✓${NC} Neo4j installed"

# Install InfluxDB
install-influxdb:
	@echo -e "${BLUE}ℹ${NC} Installing InfluxDB..."
	@if ! command -v influxd &> /dev/null; then \
		wget -q https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.5-amd64.deb -O /tmp/influxdb.deb 2>/dev/null || \
		wget -q https://dl.influxdata.com/influxdb/releases/influxdb2-2.7.5-linux-amd64.tar.gz -O /tmp/influxdb.tar.gz; \
		if [ -f /tmp/influxdb.deb ]; then \
			$(SUDO) dpkg -i /tmp/influxdb.deb; \
			rm /tmp/influxdb.deb; \
		elif [ -f /tmp/influxdb.tar.gz ]; then \
			tar xzf /tmp/influxdb.tar.gz -C $(DB_DIR); \
			rm /tmp/influxdb.tar.gz; \
		fi; \
	else \
		echo -e "${GREEN}✓${NC} InfluxDB already installed"; \
	fi
	@echo -e "${GREEN}✓${NC} InfluxDB installed"

# Install TimescaleDB
install-timescaledb:
	@echo -e "${BLUE}ℹ${NC} Installing TimescaleDB..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) sh -c "echo 'deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $$(lsb_release -c -s) main' > /etc/apt/sources.list.d/timescaledb.list"
	@wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | $(SUDO) apt-key add -
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) apt install -y timescaledb-2-postgresql-$(POSTGRESQL_VERSION) 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) timescaledb-tune --quiet --yes 2>/dev/null || true
endif
	@echo -e "${GREEN}✓${NC} TimescaleDB installed"

# Install DuckDB
install-duckdb:
	@echo -e "${BLUE}ℹ${NC} Installing DuckDB..."
	@if ! command -v duckdb &> /dev/null; then \
		if [ "$(ARCH)" = "x86_64" ]; then \
			wget -q https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-amd64.zip -O /tmp/duckdb.zip; \
		else \
			wget -q https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-aarch64.zip -O /tmp/duckdb.zip; \
		fi; \
		unzip -q /tmp/duckdb.zip -d $(HOME)/.local/bin/; \
		rm /tmp/duckdb.zip; \
		chmod +x $(HOME)/.local/bin/duckdb; \
	else \
		echo -e "${GREEN}✓${NC} DuckDB already installed"; \
	fi
	@echo -e "${GREEN}✓${NC} DuckDB installed"

# Install ClickHouse
install-clickhouse:
	@echo -e "${BLUE}ℹ${NC} Installing ClickHouse..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt install -y apt-transport-https ca-certificates dirmngr
	@$(SUDO) apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8919F6BD2B48D754
	@echo "deb https://packages.clickhouse.com/deb stable main" | \
		$(SUDO) tee /etc/apt/sources.list.d/clickhouse.list
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) apt install -y clickhouse-server clickhouse-client 2>&1 | tee -a $(LOG_FILE) || true
else ifeq ($(IS_MACOS),true)
	@if ! command -v clickhouse &> /dev/null; then \
		brew install clickhouse; \
	else \
		echo -e "${GREEN}✓${NC} ClickHouse already installed"; \
	fi
endif
	@echo -e "${GREEN}✓${NC} ClickHouse installed"

# Install database tools
install-tools: install-cli-tools install-gui-tools install-migration-tools install-backup-tools

# Install CLI database tools
install-cli-tools:
	@echo -e "${BLUE}ℹ${NC} Installing database CLI tools..."
	@# PostgreSQL tools
	@if command -v pip3 &> /dev/null; then \
		pip3 install --user pgcli 2>/dev/null || true; \
		pip3 install --user mycli 2>/dev/null || true; \
		pip3 install --user litecli 2>/dev/null || true; \
		pip3 install --user mssql-cli 2>/dev/null || true; \
	fi
	@# Install usql - universal database CLI
	@if ! command -v usql &> /dev/null; then \
		wget -q https://github.com/xo/usql/releases/latest/download/usql-linux-amd64.tar.gz -O /tmp/usql.tar.gz; \
		tar xzf /tmp/usql.tar.gz -C $(HOME)/.local/bin/ usql; \
		rm /tmp/usql.tar.gz; \
	fi
	@# Install database modeling tools
	@if command -v npm &> /dev/null; then \
		npm install -g sql-formatter 2>/dev/null || true; \
		npm install -g @dbml/cli 2>/dev/null || true; \
	fi
	@echo -e "${GREEN}✓${NC} CLI tools installed"

# Install GUI database tools
install-gui-tools:
	@echo -e "${BLUE}ℹ${NC} Installing database GUI tools..."
ifeq ($(PACKAGE_MANAGER),apt)
	@# DBeaver - Universal database manager
	@if ! command -v dbeaver &> /dev/null; then \
		wget -O /tmp/dbeaver.deb https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb; \
		$(SUDO) dpkg -i /tmp/dbeaver.deb || $(SUDO) apt-get install -f -y; \
		rm /tmp/dbeaver.deb; \
	fi
	@# pgAdmin
	@$(SUDO) sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
	@$(SUDO) curl -fsSL https://www.pgadmin.org/static/packages_pgadmin_org.pub | $(SUDO) apt-key add -
	@$(SUDO) apt update 2>&1 | tee -a $(LOG_FILE) || true
	@$(SUDO) apt install -y pgadmin4-desktop 2>/dev/null || true
else ifeq ($(IS_MACOS),true)
	@brew install --cask dbeaver-community 2>/dev/null || true
	@brew install --cask pgadmin4 2>/dev/null || true
	@brew install --cask sequel-ace 2>/dev/null || true
	@brew install --cask tableplus 2>/dev/null || true
endif
	@echo -e "${GREEN}✓${NC} GUI tools installed"

# Install migration tools
install-migration-tools:
	@echo -e "${BLUE}ℹ${NC} Installing database migration tools..."
	@# Install migration tools via different package managers
	@if command -v pip3 &> /dev/null; then \
		pip3 install --user alembic 2>/dev/null || true; \
		pip3 install --user yoyo-migrations 2>/dev/null || true; \
	fi
	@if command -v npm &> /dev/null; then \
		npm install -g db-migrate 2>/dev/null || true; \
		npm install -g knex 2>/dev/null || true; \
		npm install -g sequelize-cli 2>/dev/null || true; \
		npm install -g prisma 2>/dev/null || true; \
	fi
	@if command -v go &> /dev/null; then \
		go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest 2>/dev/null || true; \
		go install github.com/pressly/goose/v3/cmd/goose@latest 2>/dev/null || true; \
	fi
	@# Install Flyway
	@if ! command -v flyway &> /dev/null; then \
		wget -q https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/10.4.1/flyway-commandline-10.4.1-linux-x64.tar.gz -O /tmp/flyway.tar.gz; \
		mkdir -p $(DB_DIR)/flyway; \
		tar xzf /tmp/flyway.tar.gz -C $(DB_DIR)/flyway --strip-components=1; \
		ln -sf $(DB_DIR)/flyway/flyway $(HOME)/.local/bin/flyway; \
		rm /tmp/flyway.tar.gz; \
	fi
	@# Install Liquibase
	@if ! command -v liquibase &> /dev/null; then \
		wget -q https://github.com/liquibase/liquibase/releases/latest/download/liquibase.tar.gz -O /tmp/liquibase.tar.gz; \
		mkdir -p $(DB_DIR)/liquibase; \
		tar xzf /tmp/liquibase.tar.gz -C $(DB_DIR)/liquibase; \
		ln -sf $(DB_DIR)/liquibase/liquibase $(HOME)/.local/bin/liquibase; \
		rm /tmp/liquibase.tar.gz; \
	fi
	@echo -e "${GREEN}✓${NC} Migration tools installed"

# Install backup tools
install-backup-tools:
	@echo -e "${BLUE}ℹ${NC} Installing database backup tools..."
	@# PostgreSQL backup tools
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) apt install -y postgresql-client-common 2>&1 | tee -a $(LOG_FILE)
	@$(SUDO) apt install -y autopostgresqlbackup 2>/dev/null || true
	@$(SUDO) apt install -y automysqlbackup 2>/dev/null || true
endif
	@# Install pgBackRest
	@if ! command -v pgbackrest &> /dev/null; then \
		if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y pgbackrest 2>/dev/null || true; \
		fi; \
	fi
	@# Install Barman (PostgreSQL backup)
	@if command -v pip3 &> /dev/null; then \
		pip3 install --user barman 2>/dev/null || true; \
	fi
	@echo -e "${GREEN}✓${NC} Backup tools installed"

# Install database monitoring tools
install-database-monitoring:
	@echo -e "${BLUE}ℹ${NC} Installing database monitoring tools..."
	@# pg_stat_statements and extensions
	@if command -v psql &> /dev/null; then \
		$(SUDO) -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;" 2>/dev/null || true; \
		$(SUDO) -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS pgstattuple;" 2>/dev/null || true; \
	fi
	@# Install pgBadger
	@if ! command -v pgbadger &> /dev/null; then \
		if [ "$(PACKAGE_MANAGER)" = "apt" ]; then \
			$(SUDO) apt install -y pgbadger 2>/dev/null || true; \
		fi; \
	fi
	@# Install pgCenter
	@if ! command -v pgcenter &> /dev/null; then \
		wget -q https://github.com/lesovsky/pgcenter/releases/latest/download/pgcenter_linux_amd64.tar.gz -O /tmp/pgcenter.tar.gz; \
		tar xzf /tmp/pgcenter.tar.gz -C $(HOME)/.local/bin/; \
		rm /tmp/pgcenter.tar.gz; \
	fi
	@echo -e "${GREEN}✓${NC} Monitoring tools installed"

# Configure databases
configure-databases:
	@echo -e "${BLUE}ℹ${NC} Configuring databases..."
	@# PostgreSQL configuration
	@if command -v psql &> /dev/null; then \
		$(SUDO) -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';" 2>/dev/null || true; \
		echo "# PostgreSQL connection string:" > $(DB_DIR)/connection-strings.txt; \
		echo "postgresql://postgres:postgres@localhost:5432/postgres" >> $(DB_DIR)/connection-strings.txt; \
	fi
	@# MySQL configuration
	@if command -v mysql &> /dev/null; then \
		echo "# MySQL connection string:" >> $(DB_DIR)/connection-strings.txt; \
		echo "mysql://root@localhost:3306" >> $(DB_DIR)/connection-strings.txt; \
	fi
	@# Redis configuration
	@if command -v redis-cli &> /dev/null; then \
		echo "# Redis connection string:" >> $(DB_DIR)/connection-strings.txt; \
		echo "redis://localhost:6379" >> $(DB_DIR)/connection-strings.txt; \
	fi
	@# MongoDB configuration
	@if command -v mongod &> /dev/null; then \
		echo "# MongoDB connection string:" >> $(DB_DIR)/connection-strings.txt; \
		echo "mongodb://localhost:27017" >> $(DB_DIR)/connection-strings.txt; \
	fi
	@echo -e "${GREEN}✓${NC} Databases configured"
	@echo -e "${YELLOW}Connection strings saved to: $(DB_DIR)/connection-strings.txt${NC}"

# Create database users
create-users:
	@echo -e "${BLUE}ℹ${NC} Creating database users..."
	@# PostgreSQL users
	@if command -v psql &> /dev/null; then \
		$(SUDO) -u postgres psql -c "CREATE USER developer WITH PASSWORD 'developer' CREATEDB;" 2>/dev/null || true; \
		$(SUDO) -u postgres psql -c "CREATE DATABASE developer OWNER developer;" 2>/dev/null || true; \
	fi
	@# MySQL users
	@if command -v mysql &> /dev/null; then \
		$(SUDO) mysql -e "CREATE USER IF NOT EXISTS 'developer'@'localhost' IDENTIFIED BY 'developer';" 2>/dev/null || true; \
		$(SUDO) mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'developer'@'localhost';" 2>/dev/null || true; \
		$(SUDO) mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true; \
	fi
	@echo -e "${GREEN}✓${NC} Database users created"
	@echo -e "${CYAN}Default user: developer / password: developer${NC}"

# Setup example databases
setup-examples:
	@echo -e "${BLUE}ℹ${NC} Setting up example databases..."
	@# Create sample databases
	@if command -v psql &> /dev/null; then \
		psql -U developer -c "CREATE DATABASE IF NOT EXISTS sample_app;" 2>/dev/null || true; \
		psql -U developer -c "CREATE DATABASE IF NOT EXISTS test_db;" 2>/dev/null || true; \
	fi
	@# Download sample data
	@mkdir -p $(DB_DATA_DIR)/samples
	@# Download Northwind for PostgreSQL
	@if [ ! -f $(DB_DATA_DIR)/samples/northwind.sql ]; then \
		wget -q https://raw.githubusercontent.com/pthom/northwind_psql/master/northwind.sql \
			-O $(DB_DATA_DIR)/samples/northwind.sql; \
	fi
	@# Download AdventureWorks for PostgreSQL
	@if [ ! -f $(DB_DATA_DIR)/samples/adventureworks.sql ]; then \
		wget -q https://github.com/lorint/AdventureWorks-for-Postgres/raw/master/install.sql \
			-O $(DB_DATA_DIR)/samples/adventureworks.sql 2>/dev/null || true; \
	fi
	@echo -e "${GREEN}✓${NC} Example databases ready"
	@echo -e "${CYAN}Sample data available in: $(DB_DATA_DIR)/samples${NC}"

# Start all database services
start-services:
	@echo -e "${BLUE}ℹ${NC} Starting database services..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) systemctl start postgresql 2>/dev/null || true
	@$(SUDO) systemctl start mysql 2>/dev/null || true
	@$(SUDO) systemctl start redis-server 2>/dev/null || true
	@$(SUDO) systemctl start mongod 2>/dev/null || true
else ifeq ($(IS_MACOS),true)
	@brew services start postgresql 2>/dev/null || true
	@brew services start mysql 2>/dev/null || true
	@brew services start redis 2>/dev/null || true
	@brew services start mongodb-community 2>/dev/null || true
endif
	@echo -e "${GREEN}✓${NC} Database services started"

# Stop all database services
stop-services:
	@echo -e "${BLUE}ℹ${NC} Stopping database services..."
ifeq ($(PACKAGE_MANAGER),apt)
	@$(SUDO) systemctl stop postgresql 2>/dev/null || true
	@$(SUDO) systemctl stop mysql 2>/dev/null || true
	@$(SUDO) systemctl stop redis-server 2>/dev/null || true
	@$(SUDO) systemctl stop mongod 2>/dev/null || true
else ifeq ($(IS_MACOS),true)
	@brew services stop postgresql 2>/dev/null || true
	@brew services stop mysql 2>/dev/null || true
	@brew services stop redis 2>/dev/null || true
	@brew services stop mongodb-community 2>/dev/null || true
endif
	@echo -e "${GREEN}✓${NC} Database services stopped"

# Verify installation
verify-databases:
	@echo -e "${BLUE}ℹ${NC} Verifying database installations..."
	@echo "Traditional SQL Databases:"
	@command -v psql &> /dev/null && echo -e "  ${GREEN}✓${NC} PostgreSQL: $$(psql --version | head -1)" || echo -e "  ${RED}✗${NC} PostgreSQL"
	@command -v mysql &> /dev/null && echo -e "  ${GREEN}✓${NC} MySQL: $$(mysql --version)" || echo -e "  ${RED}✗${NC} MySQL"
	@command -v sqlite3 &> /dev/null && echo -e "  ${GREEN}✓${NC} SQLite: $$(sqlite3 --version)" || echo -e "  ${RED}✗${NC} SQLite"
	@echo ""
	@echo "NoSQL Databases:"
	@command -v mongod &> /dev/null && echo -e "  ${GREEN}✓${NC} MongoDB" || echo -e "  ${YELLOW}⚠${NC} MongoDB"
	@command -v redis-server &> /dev/null && echo -e "  ${GREEN}✓${NC} Redis: $$(redis-server --version | cut -d' ' -f3)" || echo -e "  ${RED}✗${NC} Redis"
	@echo ""
	@echo "Modern/Analytics Databases:"
	@command -v duckdb &> /dev/null && echo -e "  ${GREEN}✓${NC} DuckDB" || echo -e "  ${RED}✗${NC} DuckDB"
	@command -v influxd &> /dev/null && echo -e "  ${GREEN}✓${NC} InfluxDB" || echo -e "  ${YELLOW}⚠${NC} InfluxDB"
	@echo ""
	@echo "CLI Tools:"
	@command -v pgcli &> /dev/null && echo -e "  ${GREEN}✓${NC} pgcli" || echo -e "  ${YELLOW}⚠${NC} pgcli"
	@command -v mycli &> /dev/null && echo -e "  ${GREEN}✓${NC} mycli" || echo -e "  ${YELLOW}⚠${NC} mycli"
	@command -v litecli &> /dev/null && echo -e "  ${GREEN}✓${NC} litecli" || echo -e "  ${YELLOW}⚠${NC} litecli"
	@command -v usql &> /dev/null && echo -e "  ${GREEN}✓${NC} usql" || echo -e "  ${YELLOW}⚠${NC} usql"
	@echo ""
	@echo "Migration Tools:"
	@command -v flyway &> /dev/null && echo -e "  ${GREEN}✓${NC} Flyway" || echo -e "  ${YELLOW}⚠${NC} Flyway"
	@command -v liquibase &> /dev/null && echo -e "  ${GREEN}✓${NC} Liquibase" || echo -e "  ${YELLOW}⚠${NC} Liquibase"
	@command -v migrate &> /dev/null && echo -e "  ${GREEN}✓${NC} golang-migrate" || echo -e "  ${YELLOW}⚠${NC} golang-migrate"
	@command -v prisma &> /dev/null && echo -e "  ${GREEN}✓${NC} Prisma" || echo -e "  ${YELLOW}⚠${NC} Prisma"
	@echo ""
	$(call show_completion_banner,DATABASE READY)
	@echo -e "${GREEN}✓${NC} Database verification complete"
	@if [ -f $(DB_DIR)/connection-strings.txt ]; then \
		echo -e "${CYAN}Connection strings: $(DB_DIR)/connection-strings.txt${NC}"; \
	fi

# Help target
help-database:
	@echo "ArmyknifeLabs Database Module"
	@echo "=============================="
	@echo ""
	@echo "Installation Profiles:"
	@echo "  all        - Install all databases and tools"
	@echo "  minimal    - PostgreSQL, SQLite, DuckDB, and CLI tools"
	@echo "  developer  - Common development databases"
	@echo ""
	@echo "Individual Databases:"
	@echo "  install-postgresql  - PostgreSQL with extensions"
	@echo "  install-mysql       - MySQL server and client"
	@echo "  install-mariadb     - MariaDB server and client"
	@echo "  install-sqlite      - SQLite database"
	@echo "  install-mongodb     - MongoDB NoSQL database"
	@echo "  install-redis       - Redis key-value store"
	@echo "  install-cassandra   - Cassandra distributed database"
	@echo "  install-neo4j       - Neo4j graph database"
	@echo "  install-influxdb    - InfluxDB time-series database"
	@echo "  install-timescaledb - TimescaleDB for PostgreSQL"
	@echo "  install-duckdb      - DuckDB analytical database"
	@echo "  install-clickhouse  - ClickHouse OLAP database"
	@echo ""
	@echo "Tools:"
	@echo "  install-cli-tools       - pgcli, mycli, litecli, usql"
	@echo "  install-gui-tools       - DBeaver, pgAdmin, TablePlus"
	@echo "  install-migration-tools - Flyway, Liquibase, Prisma"
	@echo "  install-backup-tools    - Backup and restore utilities"
	@echo "  install-database-monitoring - Database monitoring tools"
	@echo ""
	@echo "Management:"
	@echo "  configure-databases - Configure all databases"
	@echo "  create-users        - Create developer users"
	@echo "  setup-examples      - Download sample databases"
	@echo "  start-services      - Start all database services"
	@echo "  stop-services       - Stop all database services"
	@echo "  verify-databases    - Verify installations"
	@echo ""
	@echo "Usage:"
	@echo "  make -f makefiles/Makefile.Database.mk all"
	@echo "  make -f makefiles/Makefile.Database.mk minimal"
	@echo "  make -f makefiles/Makefile.Database.mk start-services"
	@echo ""
	@echo "Default Credentials:"
	@echo "  Username: developer"
	@echo "  Password: developer"