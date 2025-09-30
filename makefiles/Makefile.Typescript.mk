# ArmyknifeLabs Platform Installer - TypeScript/JavaScript Ecosystem Module
# Makefile.Typescript.mk
#
# The most comprehensive JavaScript/TypeScript development environment
# For: Full-stack developers, Frontend engineers, Node.js developers, React/Vue/Angular devs
# Features: Multiple Node versions, modern package managers, frameworks, bundlers, testing tools

# Import parent variables
ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-typescript-$(shell date +%Y%m%d-%H%M%S).log
TS_DIR := $(ARMYKNIFE_DIR)/typescript

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
IS_MACOS := $(shell if [ "$$(uname -s)" = "Darwin" ]; then echo true; else echo false; fi)
IS_LINUX := $(shell if [ "$$(uname -s)" = "Linux" ]; then echo true; else echo false; fi)
ARCH := $(shell uname -m)

# Node versions
NODE_VERSIONS := 18.20.5 20.18.0 21.7.3 22.11.0
DEFAULT_NODE := 20.18.0

# Version manager installers
FNM_INSTALLER := https://fnm.vercel.app/install
NVM_INSTALLER := https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh
VOLTA_INSTALLER := https://get.volta.sh

# Package manager installers
PNPM_INSTALLER := https://get.pnpm.io/install.sh
BUN_INSTALLER := https://bun.sh/install
NI_NPM := @antfu/ni

# Phony targets
.PHONY: all minimal install-system-deps install-fnm install-nvm install-volta \
        install-node-versions install-pnpm install-yarn install-bun install-ni \
        install-typescript install-modern-tools install-bundlers install-frameworks \
        install-testing install-linters install-mobile install-desktop install-backend \
        install-devtools install-build-tools configure-npm create-projects verify-typescript

# Main target - install everything
all: install-system-deps install-fnm install-node-versions install-pnpm \
     install-yarn install-bun install-ni install-typescript install-modern-tools \
     install-bundlers install-frameworks install-testing install-linters \
     install-mobile install-desktop install-backend install-devtools \
     install-build-tools configure-npm create-projects verify-typescript

# Minimal installation
minimal: install-system-deps install-fnm install-node-versions install-pnpm \
         install-typescript install-bundlers install-linters configure-npm

# Install system dependencies
install-system-deps:
	@echo -e "${BLUE}ℹ${NC} Installing TypeScript/JavaScript system dependencies..."
	@mkdir -p $$(dirname $(LOG_FILE))
ifeq ($(OS_TYPE),ubuntu)
	@sudo apt update && sudo apt install -y \
		build-essential python3 make gcc g++ \
		libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev \
		libpixman-1-dev libpng-dev libtool autoconf automake \
		chromium-browser firefox 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(OS_TYPE),fedora)
	@sudo dnf install -y gcc gcc-c++ make python3 \
		cairo-devel pango-devel libjpeg-devel giflib-devel librsvg2-devel \
		pixman-devel libpng-devel libtool autoconf automake \
		chromium firefox 2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@brew install cairo pango libpng jpeg giflib librsvg pixman \
		pkg-config autoconf automake libtool 2>/dev/null || true
endif
	@echo -e "${GREEN}✓${NC} System dependencies installed"

# Install fnm (Fast Node Manager)
install-fnm:
	@echo -e "${BLUE}ℹ${NC} Installing fnm..."
	@if command -v fnm &> /dev/null; then \
		echo -e "${GREEN}✓${NC} fnm already installed ($$(fnm --version))"; \
	else \
		curl -fsSL $(FNM_INSTALLER) | bash -s -- --skip-shell 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} fnm installed"; \
	fi
	@# Configure shell
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q "fnm env" $$rc; then \
			echo '' >> $$rc; \
			echo '# fnm' >> $$rc; \
			echo 'export PATH="$$HOME/.local/share/fnm:$$PATH"' >> $$rc; \
			echo 'eval "$$(fnm env --use-on-cd)"' >> $$rc; \
		fi; \
	done

# Install nvm (Node Version Manager) as alternative
install-nvm:
	@echo -e "${BLUE}ℹ${NC} Installing nvm..."
	@if [ -d "$$HOME/.nvm" ]; then \
		echo -e "${GREEN}✓${NC} nvm already installed"; \
	else \
		curl -o- $(NVM_INSTALLER) | bash 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} nvm installed"; \
	fi

# Install Volta (alternative version manager)
install-volta:
	@echo -e "${BLUE}ℹ${NC} Installing Volta..."
	@if command -v volta &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Volta already installed"; \
	else \
		curl -sSf $(VOLTA_INSTALLER) | bash 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} Volta installed"; \
	fi

# Install Node.js versions
install-node-versions:
	@echo -e "${BLUE}ℹ${NC} Installing Node.js versions..."
	@export PATH="$$HOME/.local/share/fnm:$$PATH" && \
	eval "$$(fnm env)" && \
	for version in $(NODE_VERSIONS); do \
		if ! fnm list | grep -q $$version 2>/dev/null; then \
			echo "  Installing Node.js $$version..."; \
			fnm install $$version 2>&1 | tee -a $(LOG_FILE); \
		else \
			echo -e "  ${GREEN}✓${NC} Node.js $$version already installed"; \
		fi; \
	done
	@fnm default $(DEFAULT_NODE) 2>/dev/null || true
	@fnm use $(DEFAULT_NODE) 2>/dev/null || true
	@# Install corepack for package manager management
	@npm install -g corepack
	@corepack enable
	@echo -e "${GREEN}✓${NC} Node.js versions installed"

# Install pnpm
install-pnpm:
	@echo -e "${BLUE}ℹ${NC} Installing pnpm..."
	@if command -v pnpm &> /dev/null; then \
		echo -e "${GREEN}✓${NC} pnpm already installed ($$(pnpm --version))"; \
		pnpm self-update 2>/dev/null || true; \
	else \
		curl -fsSL $(PNPM_INSTALLER) | sh - 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} pnpm installed"; \
	fi
	@pnpm setup 2>/dev/null || true
	@pnpm config set store-dir ~/.pnpm-store

# Install Yarn
install-yarn:
	@echo -e "${BLUE}ℹ${NC} Installing Yarn..."
	@if command -v yarn &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Yarn already installed ($$(yarn --version))"; \
	else \
		npm install -g yarn 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} Yarn installed"; \
	fi
	@# Also install Yarn Berry
	@yarn set version berry 2>/dev/null || true

# Install Bun
install-bun:
	@echo -e "${BLUE}ℹ${NC} Installing Bun..."
	@if command -v bun &> /dev/null; then \
		echo -e "${GREEN}✓${NC} Bun already installed ($$(bun --version))"; \
		bun upgrade 2>/dev/null || true; \
	else \
		curl -fsSL $(BUN_INSTALLER) | bash 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} Bun installed"; \
	fi

# Install ni (package manager abstraction)
install-ni:
	@echo -e "${BLUE}ℹ${NC} Installing ni..."
	@npm install -g $(NI_NPM)
	@echo -e "${GREEN}✓${NC} ni installed"

# Install TypeScript and related tools
install-typescript:
	@echo -e "${BLUE}ℹ${NC} Installing TypeScript ecosystem..."
	@npm install -g typescript ts-node tsx ts-node-dev
	@npm install -g @swc/cli @swc/core  # Super-fast TS compiler
	@npm install -g esbuild  # Another fast bundler/compiler
	@npm install -g tsup  # Bundle TypeScript libraries
	@npm install -g tsc-watch
	@npm install -g typescript-language-server
	@echo -e "${GREEN}✓${NC} TypeScript ecosystem installed"

# Install modern cutting-edge tools (2024-2025)
install-modern-tools:
	@echo -e "${BLUE}ℹ${NC} Installing modern JavaScript/TypeScript tools..."
	@# Rust-based toolchain
	@npm install -g @biomejs/biome  # Fast formatter/linter written in Rust
	@npm install -g @oxlint/cli 2>/dev/null || true  # Rust-based linter
	@# Modern testing
	@npm install -g vitest  # Fast Vite-native test runner
	@npm install -g @playwright/test playwright  # Modern end-to-end testing
	@# Lightning CSS
	@npm install -g lightningcss-cli  # Extremely fast CSS transformer
	@# Package management
	@curl -fsSL https://get.volta.sh | bash 2>/dev/null || true  # JS toolchain manager
	@# Runtime alternatives
	@curl -fsSL https://deno.land/install.sh | sh 2>/dev/null || true  # Deno runtime
	@# SSR/SSG frameworks
	@npm install -g solid-start  # SolidJS meta-framework
	@npm install -g @analogjs/cli  # Angular meta-framework
	@npm install -g qwik  # Resumable framework
	@# Build optimization
	@npm install -g million  # Optimizing compiler for React
	@npm install -g unplugin-auto-import unplugin-vue-components  # Auto imports
	@echo -e "${GREEN}✓${NC} Modern tools installed"

# Install bundlers and build tools
install-bundlers:
	@echo -e "${BLUE}ℹ${NC} Installing bundlers and build tools..."
	@npm install -g vite webpack webpack-cli
	@npm install -g parcel rollup
	@npm install -g turbo  # Monorepo build system
	@npm install -g nx  # Monorepo tools
	@npm install -g lerna rush  # Monorepo management
	@npm install -g snowpack  # ESM-based bundler
	@npm install -g wmr  # Preact's bundler
	@npm install -g @rspack/cli  # Rust-based webpack alternative
	@echo -e "${GREEN}✓${NC} Bundlers installed"

# Install frameworks and libraries
install-frameworks:
	@echo -e "${BLUE}ℹ${NC} Installing frameworks and CLIs..."
	@# React ecosystem
	@npm install -g create-react-app
	@npm install -g create-next-app
	@npm install -g gatsby-cli
	@npm install -g create-remix
	@# Vue ecosystem
	@npm install -g @vue/cli
	@npm install -g create-vue
	@npm install -g nuxi  # Nuxt 3
	@npm install -g @quasar/cli
	@# Angular
	@npm install -g @angular/cli
	@# Svelte
	@npm install -g degit  # For Svelte templates
	@npm install -g create-svelte
	@# Solid
	@npm install -g solid-cli
	@# Qwik
	@npm install -g create-qwik
	@# Astro
	@npm install -g astro
	@# Meta-frameworks
	@npm install -g @shopify/hydrogen-cli
	@npm install -g @builder.io/cli
	@# Static site generators
	@npm install -g @11ty/eleventy
	@npm install -g hexo-cli
	@npm install -g docusaurus
	@npm install -g vuepress
	@npm install -g docsify-cli
	@echo -e "${GREEN}✓${NC} Frameworks installed"

# Install testing tools
install-testing:
	@echo -e "${BLUE}ℹ${NC} Installing testing tools..."
	@npm install -g jest vitest mocha chai ava tape
	@npm install -g playwright @playwright/test
	@npm install -g puppeteer
	@npm install -g cypress
	@npm install -g webdriverio
	@npm install -g nightwatch
	@npm install -g testcafe
	@npm install -g @storybook/cli
	@npm install -g karma-cli
	@npm install -g jasmine
	@npm install -g qunit
	@npm install -g sinon
	@npm install -g c8 nyc  # Code coverage
	@npm install -g codeceptjs
	@npm install -g newman  # Postman CLI
	@npm install -g k6  # Load testing
	@npm install -g artillery  # Performance testing
	@echo -e "${GREEN}✓${NC} Testing tools installed"

# Install linters and formatters
install-linters:
	@echo -e "${BLUE}ℹ${NC} Installing linters and formatters..."
	@npm install -g eslint prettier
	@npm install -g @typescript-eslint/parser @typescript-eslint/eslint-plugin
	@npm install -g eslint-config-airbnb eslint-config-standard
	@npm install -g xo  # Opinionated linter
	@npm install -g standard  # JavaScript Standard Style
	@npm install -g jshint jslint
	@npm install -g stylelint
	@npm install -g htmlhint
	@npm install -g markdownlint-cli
	@npm install -g commitlint @commitlint/cli @commitlint/config-conventional
	@npm install -g husky lint-staged
	@npm install -g pretty-quick
	@npm install -g sort-package-json
	@npm install -g npm-check-updates
	@npm install -g depcheck
	@npm install -g license-checker
	@npm install -g bundlewatch bundlesize
	@echo -e "${GREEN}✓${NC} Linters and formatters installed"

# Install mobile development tools
install-mobile:
	@echo -e "${BLUE}ℹ${NC} Installing mobile development tools..."
	@npm install -g expo-cli eas-cli
	@npm install -g react-native-cli
	@npm install -g @ionic/cli
	@npm install -g @capacitor/cli
	@npm install -g @nativescript/cli
	@npm install -g cordova
	@npm install -g create-react-native-app
	@npm install -g ignite-cli  # React Native boilerplate
	@npm install -g @quasar/cli  # Also does mobile
	@echo -e "${GREEN}✓${NC} Mobile development tools installed"

# Install desktop development tools
install-desktop:
	@echo -e "${BLUE}ℹ${NC} Installing desktop development tools..."
	@npm install -g electron electron-forge
	@npm install -g @tauri-apps/cli
	@npm install -g @neutralinojs/neu
	@npm install -g @nodegui/nodegui
	@npm install -g carlo  # Chrome app framework
	@npm install -g nwjs  # NW.js
	@echo -e "${GREEN}✓${NC} Desktop development tools installed"

# Install backend/API tools
install-backend:
	@echo -e "${BLUE}ℹ${NC} Installing backend/API tools..."
	@npm install -g express-generator
	@npm install -g @nestjs/cli
	@npm install -g @adonisjs/cli
	@npm install -g fastify-cli
	@npm install -g @hapi/cli
	@npm install -g koa-generator
	@npm install -g loopback-cli
	@npm install -g sails
	@npm install -g strapi
	@npm install -g ghost-cli  # Blogging platform
	@npm install -g parse-server
	@npm install -g json-server  # Fake REST API
	@npm install -g graphql graphql-cli apollo
	@npm install -g hasura  # GraphQL engine
	@npm install -g prisma  # Database toolkit
	@npm install -g sequelize-cli
	@npm install -g typeorm
	@npm install -g knex
	@npm install -g db-migrate
	@npm install -g node-red  # Flow-based programming
	@npm install -g pm2  # Process manager
	@npm install -g forever nodemon
	@npm install -g concurrently
	@npm install -g cross-env dotenv-cli
	@echo -e "${GREEN}✓${NC} Backend tools installed"

# Install development utilities
install-devtools:
	@echo -e "${BLUE}ℹ${NC} Installing development utilities..."
	@npm install -g npm-run-all
	@npm install -g ntl  # Interactive npm scripts
	@npm install -g np  # Better npm publish
	@npm install -g release-it auto-changelog
	@npm install -g semantic-release
	@npm install -g standard-version
	@npm install -g verdaccio  # Private npm registry
	@npm install -g yalc  # Local package development
	@npm install -g patch-package
	@npm install -g madge  # Dependency graph
	@npm install -g dependency-cruiser
	@npm install -g size-limit @size-limit/preset-app
	@npm install -g source-map-explorer
	@npm install -g webpack-bundle-analyzer
	@npm install -g serve http-server live-server
	@npm install -g localtunnel ngrok
	@npm install -g json jq-cli
	@npm install -g uuid-cli
	@npm install -g faker-cli
	@npm install -g plop  # Micro-generator
	@npm install -g hygen  # Code generator
	@npm install -g yeoman-generator yo
	@echo -e "${GREEN}✓${NC} Development utilities installed"

# Install build and CI/CD tools
install-build-tools:
	@echo -e "${BLUE}ℹ${NC} Installing build and CI/CD tools..."
	@npm install -g grunt-cli gulp-cli
	@npm install -g brunch bower
	@npm install -g browserify watchify
	@npm install -g fuse-box
	@npm install -g microbundle  # Zero-config bundler
	@npm install -g tsdx  # TypeScript library development
	@npm install -g preconstruct  # Build tool
	@npm install -g changeset @changesets/cli
	@npm install -g beachball  # Semantic versioning
	@npm install -g danger  # Code review automation
	@npm install -g lighthouse  # Performance testing
	@npm install -g webhint  # Linting tool for web
	@npm install -g pa11y  # Accessibility testing
	@npm install -g start-server-and-test
	@npm install -g wait-on
	@npm install -g npm-check
	@npm install -g cost-of-modules
	@npm install -g npminstall  # Fast npm install
	@echo -e "${GREEN}✓${NC} Build tools installed"

# Configure npm and package managers
configure-npm:
	@echo -e "${BLUE}ℹ${NC} Configuring npm and package managers..."
	@# NPM configuration
	@npm config set init-author-name "$$(git config --global user.name 2>/dev/null || echo 'Developer')"
	@npm config set init-author-email "$$(git config --global user.email 2>/dev/null || echo 'dev@example.com')"
	@npm config set init-license "MIT"
	@npm config set save-exact false
	@npm config set progress true
	@# Create .npmrc
	@cat > ~/.npmrc <<-EOF
		registry=https://registry.npmjs.org/
		save-exact=false
		package-lock=true
		fund=false
		audit-level=moderate
		update-notifier=true
	EOF
	@# PNPM configuration
	@pnpm config set auto-install-peers true
	@pnpm config set strict-peer-dependencies false
	@# Create directories
	@mkdir -p $(TS_DIR)/{projects,templates,scripts}
	@mkdir -p ~/.npm-global
	@npm config set prefix ~/.npm-global
	@echo -e "${GREEN}✓${NC} Package managers configured"

# Create example projects
create-projects:
	@echo -e "${BLUE}ℹ${NC} Creating example project templates..."
	@# TypeScript library template
	@mkdir -p $(TS_DIR)/templates/ts-library
	@cat > $(TS_DIR)/templates/ts-library/tsconfig.json <<-EOF
		{
		  "compilerOptions": {
		    "target": "ES2022",
		    "module": "ESNext",
		    "lib": ["ES2022", "DOM"],
		    "declaration": true,
		    "declarationMap": true,
		    "sourceMap": true,
		    "outDir": "./dist",
		    "rootDir": "./src",
		    "strict": true,
		    "esModuleInterop": true,
		    "skipLibCheck": true,
		    "forceConsistentCasingInFileNames": true,
		    "moduleResolution": "node",
		    "resolveJsonModule": true,
		    "isolatedModules": true
		  },
		  "include": ["src"],
		  "exclude": ["node_modules", "dist"]
		}
	EOF
	@# Biome configuration
	@cat > $(TS_DIR)/templates/biome.json <<-EOF
		{
		  "organizeImports": { "enabled": true },
		  "linter": {
		    "enabled": true,
		    "rules": {
		      "recommended": true,
		      "complexity": { "noBannedTypes": "error" },
		      "correctness": { "noUnusedVariables": "error" },
		      "style": { "noVar": "error", "useConst": "error" }
		    }
		  },
		  "formatter": {
		    "enabled": true,
		    "indentStyle": "space",
		    "indentWidth": 2,
		    "lineWidth": 100
		  }
		}
	EOF
	@echo -e "${GREEN}✓${NC} Project templates created"

# Verify TypeScript installation
verify-typescript:
	@echo -e "${BLUE}ℹ${NC} Verifying TypeScript/JavaScript installation..."
	@echo "=== Runtime Versions ==="
	@command -v node &> /dev/null && echo -e "  ${GREEN}✓${NC} Node.js: $$(node --version)"
	@command -v bun &> /dev/null && echo -e "  ${GREEN}✓${NC} Bun: $$(bun --version)"
	@echo ""
	@echo "=== Package Managers ==="
	@command -v npm &> /dev/null && echo -e "  ${GREEN}✓${NC} npm: $$(npm --version)"
	@command -v pnpm &> /dev/null && echo -e "  ${GREEN}✓${NC} pnpm: $$(pnpm --version)"
	@command -v yarn &> /dev/null && echo -e "  ${GREEN}✓${NC} yarn: $$(yarn --version)"
	@command -v ni &> /dev/null && echo -e "  ${GREEN}✓${NC} ni installed"
	@echo ""
	@echo "=== TypeScript Tools ==="
	@command -v tsc &> /dev/null && echo -e "  ${GREEN}✓${NC} TypeScript: $$(tsc --version)"
	@command -v tsx &> /dev/null && echo -e "  ${GREEN}✓${NC} tsx installed"
	@command -v biome &> /dev/null && echo -e "  ${GREEN}✓${NC} Biome installed"
	@echo ""
	@echo "=== Build Tools ==="
	@command -v vite &> /dev/null && echo -e "  ${GREEN}✓${NC} Vite installed"
	@command -v webpack &> /dev/null && echo -e "  ${GREEN}✓${NC} Webpack installed"
	@command -v turbo &> /dev/null && echo -e "  ${GREEN}✓${NC} Turbo installed"
	@echo ""
	@echo "=== Testing Tools ==="
	@command -v vitest &> /dev/null && echo -e "  ${GREEN}✓${NC} Vitest installed"
	@command -v playwright &> /dev/null && echo -e "  ${GREEN}✓${NC} Playwright installed"
	@echo -e "${GREEN}✓${NC} TypeScript verification complete"

# Help
help-typescript:
	@echo "ArmyknifeLabs TypeScript/JavaScript Ecosystem Module"
	@echo "The most comprehensive Node.js development environment"
	@echo ""
	@echo "Installation Profiles:"
	@echo "  make all      - Complete installation (everything)"
	@echo "  make minimal  - Basic setup with essential tools"
	@echo ""
	@echo "Components:"
	@echo "  install-system-deps  - System libraries"
	@echo "  install-fnm         - Fast Node Manager"
	@echo "  install-node-versions - Multiple Node.js versions"
	@echo "  install-pnpm        - Fast package manager"
	@echo "  install-yarn        - Yarn package manager"
	@echo "  install-bun         - Bun runtime and toolkit"
	@echo "  install-typescript  - TypeScript and compilers"
	@echo "  install-bundlers    - Vite, Webpack, Rollup, etc."
	@echo "  install-frameworks  - React, Vue, Angular, Svelte, etc."
	@echo "  install-testing     - Jest, Vitest, Playwright, Cypress"
	@echo "  install-linters     - ESLint, Prettier, Biome"
	@echo "  install-mobile      - React Native, Expo, Ionic"
	@echo "  install-desktop     - Electron, Tauri"
	@echo "  install-backend     - Express, NestJS, Fastify"
	@echo "  install-devtools    - Development utilities"
	@echo ""
	@echo "Node.js Versions: $(NODE_VERSIONS)"
	@echo "Default Version: $(DEFAULT_NODE)"