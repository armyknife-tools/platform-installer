# ArmyknifeLabs Platform Installer - Rust Ecosystem Module
# Makefile.Rust.mk
#
# The most comprehensive Rust development environment
# For: Systems programmers, WebAssembly developers, Embedded developers, Performance engineers
# Features: Multiple toolchains, cargo extensions, WASM tools, embedded targets, and more

# Import parent variables
ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-rust-$(shell date +%Y%m%d-%H%M%S).log
RUST_DIR := $(ARMYKNIFE_DIR)/rust

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

# Rust toolchains and targets
RUST_CHANNELS := stable beta nightly
DEFAULT_CHANNEL := stable
RUST_TARGETS := wasm32-unknown-unknown wasm32-wasi aarch64-apple-darwin x86_64-pc-windows-gnu

# Rustup installer
RUSTUP_INSTALLER := https://sh.rustup.rs

# Phony targets
.PHONY: all minimal install-system-deps install-rustup install-toolchains \
        install-components install-cargo-tools install-dev-tools install-web-tools \
        install-wasm-tools install-embedded-tools install-cli-tools install-testing \
        install-linters install-security-tools install-performance-tools \
        install-build-tools configure-rust create-projects verify-rust

# Main target - install everything
all: install-system-deps install-rustup install-toolchains install-components \
     install-cargo-tools install-dev-tools install-web-tools install-wasm-tools \
     install-embedded-tools install-cli-tools install-testing install-linters \
     install-security-tools install-performance-tools install-build-tools \
     configure-rust create-projects verify-rust

# Minimal installation
minimal: install-system-deps install-rustup install-toolchains install-components \
         install-cargo-tools install-linters configure-rust

# Install system dependencies
install-system-deps:
	@echo -e "${BLUE}ℹ${NC} Installing Rust system dependencies..."
	@mkdir -p $$(dirname $(LOG_FILE))
ifeq ($(PACKAGE_MANAGER),apt)
	@sudo apt update && sudo apt install -y \
		build-essential curl wget git \
		gcc g++ make cmake pkg-config \
		libssl-dev libcurl4-openssl-dev \
		llvm-dev libclang-dev clang \
		musl-tools mingw-w64 \
		qemu-user-static \
		2>&1 | tee -a $(LOG_FILE)
else ifeq ($(PACKAGE_MANAGER),dnf)
	@sudo dnf install -y gcc gcc-c++ make cmake curl wget git \
		openssl-devel libcurl-devel \
		llvm-devel clang-devel clang \
		musl-gcc mingw64-gcc \
		qemu-user-static \
		2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@brew install cmake pkg-config openssl curl \
		llvm musl-cross 2>/dev/null || true
endif
	@echo -e "${GREEN}✓${NC} System dependencies installed"

# Install rustup
install-rustup:
	@echo -e "${BLUE}ℹ${NC} Installing rustup..."
	@if command -v rustup &> /dev/null; then \
		echo -e "${GREEN}✓${NC} rustup already installed, updating..."; \
		rustup self update; \
	else \
		curl --proto '=https' --tlsv1.2 -sSf $(RUSTUP_INSTALLER) | sh -s -- -y 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} rustup installed"; \
	fi
	@# Configure shell
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q ".cargo/bin" $$rc; then \
			echo '' >> $$rc; \
			echo '# Rust' >> $$rc; \
			echo 'source "$$HOME/.cargo/env"' >> $$rc; \
		fi; \
	done
	@source "$$HOME/.cargo/env"

# Install Rust toolchains
install-toolchains:
	@echo -e "${BLUE}ℹ${NC} Installing Rust toolchains..."
	@source "$$HOME/.cargo/env" && \
	for channel in $(RUST_CHANNELS); do \
		echo "  Installing $$channel toolchain..."; \
		rustup toolchain install $$channel 2>&1 | tee -a $(LOG_FILE); \
	done
	@rustup default $(DEFAULT_CHANNEL)
	@# Install additional targets
	@echo "  Installing cross-compilation targets..."
	@for target in $(RUST_TARGETS); do \
		rustup target add $$target 2>/dev/null || true; \
	done
	@echo -e "${GREEN}✓${NC} Toolchains installed"

# Install Rust components
install-components:
	@echo -e "${BLUE}ℹ${NC} Installing Rust components..."
	@rustup component add rustfmt clippy rust-analyzer
	@rustup component add rust-src rust-docs
	@rustup component add llvm-tools-preview
	@rustup component add rustc-dev
	@# Nightly components
	@rustup component add miri --toolchain nightly 2>/dev/null || true
	@rustup component add rust-analyzer --toolchain nightly 2>/dev/null || true
	@echo -e "${GREEN}✓${NC} Components installed"

# Install essential cargo tools
install-cargo-tools:
	@echo -e "${BLUE}ℹ${NC} Installing essential cargo tools..."
	@cargo install cargo-edit  # Add/remove/upgrade dependencies
	@cargo install cargo-watch  # Watch for changes and rebuild
	@cargo install cargo-make  # Task runner
	@cargo install cargo-generate  # Project templates
	@cargo install cargo-expand  # Expand macros
	@cargo install cargo-outdated  # Check for outdated dependencies
	@cargo install cargo-audit  # Security audit
	@cargo install cargo-deny  # Supply chain security
	@cargo install cargo-tree  # Dependency tree
	@cargo install cargo-deps  # Dependency graph
	@cargo install cargo-update  # Update installed crates
	@cargo install cargo-cache  # Cache management
	@cargo install cargo-sweep  # Clean old build artifacts
	@cargo install cargo-machete  # Find unused dependencies
	@cargo install cargo-udeps  # Find unused dependencies
	@cargo install cargo-nextest  # Next-generation test runner
	@cargo install cargo-hack  # Feature testing
	@cargo install cargo-sort  # Sort dependencies
	@echo -e "${GREEN}✓${NC} Cargo tools installed"

# Install development tools
install-dev-tools:
	@echo -e "${BLUE}ℹ${NC} Installing development tools..."
	@cargo install rust-analyzer  # LSP server
	@cargo install bacon  # Background compiler
	@cargo install cargo-binutils  # Rust binutils
	@cargo install cargo-asm  # Show assembly
	@cargo install cargo-show-asm  # Better assembly viewer
	@cargo install cargo-bloat  # Find code bloat
	@cargo install cargo-sizeof  # Print type sizes
	@cargo install cargo-modules  # Show module structure
	@cargo install cargo-workspaces  # Workspace management
	@cargo install cargo-chef  # Docker layer caching
	@cargo install cargo-readme  # Generate README from doc comments
	@cargo install cargo-doc2readme  # Another README generator
	@cargo install cargo-release  # Release automation
	@cargo install cargo-smart-release  # Smarter releases
	@cargo install cargo-dist  # Distribution building
	@cargo install cargo-deb  # Debian packages
	@cargo install cargo-rpm  # RPM packages
	@cargo install cargo-pkgbuild  # Arch packages
	@cargo install cargo-bundle  # Application bundler
	@cargo install cargo-zigbuild  # Cross compilation with Zig
	@echo -e "${GREEN}✓${NC} Development tools installed"

# Install web development tools
install-web-tools:
	@echo -e "${BLUE}ℹ${NC} Installing web development tools..."
	@cargo install trunk  # WASM web app bundler
	@cargo install wasm-pack  # WASM packaging
	@cargo install cargo-web  # Web development
	@cargo install basic-http-server  # Simple HTTP server
	@cargo install miniserve  # File serving
	@cargo install zola  # Static site generator
	@cargo install mdbook  # Book generator
	@cargo install mdbook-mermaid  # Mermaid diagrams
	@cargo install mdbook-katex  # Math rendering
	@cargo install mdbook-plantuml  # PlantUML diagrams
	@cargo install perseus-cli  # Perseus framework
	@cargo install dioxus-cli  # Dioxus framework
	@cargo install leptos-cli  # Leptos framework
	@cargo install sycamore-cli 2>/dev/null || true  # Sycamore framework
	@cargo install seed-cli 2>/dev/null || true  # Seed framework
	@cargo install sqlx-cli  # SQLx migrations
	@cargo install diesel_cli --no-default-features --features postgres,sqlite,mysql
	@cargo install sea-orm-cli  # SeaORM migrations
	@echo -e "${GREEN}✓${NC} Web tools installed"

# Install WebAssembly tools
install-wasm-tools:
	@echo -e "${BLUE}ℹ${NC} Installing WebAssembly tools..."
	@cargo install wasm-bindgen-cli
	@cargo install wasm-opt  # WASM optimizer
	@cargo install twiggy  # WASM code size profiler
	@cargo install wasm-snip  # Remove functions from WASM
	@cargo install wasmtime  # WASM runtime
	@cargo install wasmer-cli  # Another WASM runtime
	@cargo install wasmcloud  # Distributed WASM
	@cargo install wit-bindgen-cli  # WebAssembly Interface Types
	@cargo install cargo-component  # Component model
	@cargo install warg  # WebAssembly package registry
	@cargo install wabt  # WebAssembly Binary Toolkit
	@echo -e "${GREEN}✓${NC} WASM tools installed"

# Install embedded development tools
install-embedded-tools:
	@echo -e "${BLUE}ℹ${NC} Installing embedded development tools..."
	@cargo install cargo-embed  # Flash and debug embedded devices
	@cargo install cargo-flash  # Flash microcontrollers
	@cargo install cargo-binutils  # Binutils for embedded
	@cargo install cargo-hf2  # Microsoft HID flashing
	@cargo install probe-rs-cli  # Debug probe
	@cargo install flip-link  # Stack overflow protection
	@cargo install defmt-print  # Defmt decoder
	@cargo install elf2uf2-rs  # Convert ELF to UF2
	@cargo install espflash  # ESP32 flashing
	@cargo install espmonitor  # ESP32 monitor
	@cargo install cargo-call-stack  # Stack usage analysis
	@rustup target add thumbv7em-none-eabihf  # ARM Cortex-M4F
	@rustup target add thumbv6m-none-eabi  # ARM Cortex-M0
	@rustup target add riscv32i-unknown-none-elf  # RISC-V
	@echo -e "${GREEN}✓${NC} Embedded tools installed"

# Install CLI development tools
install-cli-tools:
	@echo -e "${BLUE}ℹ${NC} Installing CLI development tools..."
	@cargo install clap  # CLI argument parser
	@cargo install structopt 2>/dev/null || true  # Derive macro for clap
	@cargo install argh 2>/dev/null || true  # Another argument parser
	@# TUI libraries and tools
	@cargo install ratatui 2>/dev/null || true  # TUI framework
	@cargo install tui 2>/dev/null || true  # Terminal UI
	@# Utilities
	@cargo install ripgrep  # Fast grep
	@cargo install fd-find  # Fast find
	@cargo install bat  # Better cat
	@cargo install exa  # Better ls (deprecated)
	@cargo install eza  # Better ls (fork of exa)
	@cargo install zoxide  # Smarter cd
	@cargo install starship  # Shell prompt
	@cargo install bottom  # System monitor
	@cargo install dust  # Disk usage
	@cargo install procs  # Process viewer
	@cargo install sd  # Find and replace
	@cargo install hyperfine  # Benchmarking
	@cargo install tokei  # Code statistics
	@cargo install git-delta  # Better git diff
	@cargo install gitui  # Git TUI
	@cargo install lazygit 2>/dev/null || true  # Another git TUI
	@cargo install broot  # File explorer
	@cargo install xh  # HTTPie clone
	@cargo install jql  # JSON query
	@cargo install jq 2>/dev/null || true  # JSON processor
	@cargo install yq 2>/dev/null || true  # YAML processor
	@echo -e "${GREEN}✓${NC} CLI tools installed"

# Install testing tools
install-testing:
	@echo -e "${BLUE}ℹ${NC} Installing testing tools..."
	@cargo install cargo-nextest  # Better test runner
	@cargo install cargo-tarpaulin  # Code coverage
	@cargo install cargo-llvm-cov  # LLVM coverage
	@cargo install cargo-careful  # Careful test execution
	@cargo install cargo-fuzz  # Fuzz testing
	@cargo install cargo-afl  # AFL fuzzing
	@cargo install honggfuzz  # Another fuzzer
	@cargo install proptest 2>/dev/null || true  # Property testing
	@cargo install quickcheck 2>/dev/null || true  # Property testing
	@cargo install cargo-mutants  # Mutation testing
	@cargo install cargo-criterion  # Benchmarking
	@cargo install criterion 2>/dev/null || true  # Benchmarking framework
	@cargo install cargo-bench  # Benchmark runner
	@cargo install cargo-insta  # Snapshot testing
	@cargo install cargo-snapshot 2>/dev/null || true  # Another snapshot tool
	@echo -e "${GREEN}✓${NC} Testing tools installed"

# Install linters and formatters
install-linters:
	@echo -e "${BLUE}ℹ${NC} Installing linters and formatters..."
	@rustup component add rustfmt clippy
	@cargo install cargo-fmt-check  # Format checker
	@cargo install cargo-clippy  # Linter
	@cargo install cargo-cranky  # Stricter clippy
	@cargo install cargo-strict  # Strict mode
	@cargo install bacon  # Background checker
	@cargo install cargo-check-external-types  # API linting
	@cargo install cargo-semver-checks  # Semver compliance
	@cargo install cargo-public-api  # Public API tracking
	@cargo install taplo-cli  # TOML formatter
	@cargo install stylua  # Lua formatter
	@echo -e "${GREEN}✓${NC} Linters installed"

# Install security tools
install-security-tools:
	@echo -e "${BLUE}ℹ${NC} Installing security tools..."
	@cargo install cargo-audit  # Security audit
	@cargo install cargo-deny  # Supply chain security
	@cargo install cargo-crev  # Code review system
	@cargo install cargo-supply-chain  # Supply chain info
	@cargo install cargo-vet  # Dependency vetting
	@cargo install cargo-geiger  # Unsafe code detection
	@cargo install cargo-osha  # Safety checks
	@cargo install sn0int  # OSINT framework
	@cargo install feroxbuster  # Content discovery
	@cargo install lychee  # Link checker
	@echo -e "${GREEN}✓${NC} Security tools installed"

# Install performance tools
install-performance-tools:
	@echo -e "${BLUE}ℹ${NC} Installing performance tools..."
	@cargo install flamegraph  # Flamegraph generator
	@cargo install cargo-flamegraph  # Integrated flamegraph
	@cargo install inferno  # Flamegraph tools
	@cargo install perf-event 2>/dev/null || true  # Performance events
	@cargo install cargo-profiling  # Profiling helper
	@cargo install cargo-count  # Code counting
	@cargo install cargo-bloat  # Binary size analysis
	@cargo install cargo-llvm-lines  # LLVM IR lines
	@cargo install cargo-asm  # Assembly output
	@cargo install cargo-expand  # Macro expansion
	@cargo install measurer  # Benchmarking
	@cargo install hyperfine  # Command benchmarking
	@cargo install poop  # Performance comparison
	@echo -e "${GREEN}✓${NC} Performance tools installed"

# Install build and deployment tools
install-build-tools:
	@echo -e "${BLUE}ℹ${NC} Installing build tools..."
	@cargo install cargo-make  # Task runner
	@cargo install just  # Command runner
	@cargo install mask  # Another task runner
	@cargo install cargo-xtask 2>/dev/null || true  # Workspace tasks
	@cargo install cargo-release  # Release automation
	@cargo install cargo-dist  # Distribution
	@cargo install cargo-wix  # Windows installer
	@cargo install cargo-deb  # Debian packages
	@cargo install cargo-rpm  # RPM packages
	@cargo install cargo-appimage  # AppImage
	@cargo install cross  # Cross compilation
	@cargo install cargo-xwin  # Windows cross-compilation
	@cargo install cargo-ndk  # Android NDK
	@cargo install cargo-apk  # Android APK
	@cargo install cargo-lipo  # iOS universal binaries
	@cargo install xargo  # Custom std builds
	@cargo install cargo-local-registry  # Local registry
	@echo -e "${GREEN}✓${NC} Build tools installed"

# Configure Rust environment
configure-rust:
	@echo -e "${BLUE}ℹ${NC} Configuring Rust environment..."
	@# Create directories
	@mkdir -p $(RUST_DIR)/{projects,templates,scripts}
	@mkdir -p ~/.cargo/{registry,git,bin}
	@# Configure cargo
	@cat > ~/.cargo/config.toml <<-EOF
		[build]
		jobs = 4
		incremental = true
		target-dir = "/tmp/cargo-target"

		[profile.release]
		opt-level = 3
		lto = "thin"
		codegen-units = 1

		[profile.release-with-debug]
		inherits = "release"
		debug = true

		[net]
		git-fetch-with-cli = true
		retry = 3

		[registries.crates-io]
		protocol = "sparse"

		[alias]
		b = "build"
		c = "check"
		t = "test"
		r = "run"
		rr = "run --release"
		br = "build --release"
		tr = "test --release"
		w = "watch"
		up = "update"
		d = "doc --open"
	EOF
	@# Clippy configuration
	@cat > ~/.clippy.toml <<-EOF
		avoid-breaking-exported-api = false
		msrv = "1.70.0"
		allow-expect-in-tests = true
		allow-unwrap-in-tests = true
		allow-dbg-in-tests = true
		allow-print-in-tests = true
	EOF
	@# Rustfmt configuration
	@cat > ~/.rustfmt.toml <<-EOF
		edition = "2021"
		max_width = 100
		tab_spaces = 4
		use_small_heuristics = "Default"
		reorder_imports = true
		reorder_modules = true
		remove_nested_parens = true
		use_try_shorthand = true
		use_field_init_shorthand = true
		force_explicit_abi = true
		format_code_in_doc_comments = true
		format_macro_matchers = true
		format_macro_bodies = true
		format_strings = true
		imports_granularity = "Crate"
		group_imports = "StdExternalCrate"
		wrap_comments = true
		comment_width = 80
		normalize_comments = true
	EOF
	@echo -e "${GREEN}✓${NC} Rust environment configured"

# Create example projects
create-projects:
	@echo -e "${BLUE}ℹ${NC} Creating example Rust projects..."
	@# CLI app template
	@cargo new --bin $(RUST_DIR)/templates/cli-app 2>/dev/null || true
	@cat > $(RUST_DIR)/templates/cli-app/src/main.rs <<-EOF
		use clap::Parser;

		#[derive(Parser, Debug)]
		#[command(author, version, about, long_about = None)]
		struct Args {
		    /// Name of the person to greet
		    #[arg(short, long)]
		    name: String,

		    /// Number of times to greet
		    #[arg(short, long, default_value_t = 1)]
		    count: u8,
		}

		fn main() {
		    let args = Args::parse();

		    for _ in 0..args.count {
		        println!("Hello, {}!", args.name);
		    }
		}
	EOF
	@# Web API template
	@cargo new --lib $(RUST_DIR)/templates/web-api 2>/dev/null || true
	@cat > $(RUST_DIR)/templates/web-api/src/main.rs <<-EOF
		use axum::{
		    routing::{get, post},
		    http::StatusCode,
		    Json, Router,
		};
		use serde::{Deserialize, Serialize};
		use std::net::SocketAddr;

		#[tokio::main]
		async fn main() {
		    let app = Router::new()
		        .route("/", get(root))
		        .route("/health", get(health));

		    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
		    println!("listening on {}", addr);
		    axum::Server::bind(&addr)
		        .serve(app.into_make_service())
		        .await
		        .unwrap();
		}

		async fn root() -> &'static str {
		    "Hello, World!"
		}

		async fn health() -> (StatusCode, Json<HealthCheck>) {
		    let health = HealthCheck {
		        status: "healthy".to_string(),
		    };
		    (StatusCode::OK, Json(health))
		}

		#[derive(Serialize)]
		struct HealthCheck {
		    status: String,
		}
	EOF
	@echo -e "${GREEN}✓${NC} Example projects created"

# Verify Rust installation
verify-rust:
	@echo -e "${BLUE}ℹ${NC} Verifying Rust installation..."
	@echo "=== Rust Version ==="
	@rustc --version
	@cargo --version
	@echo ""
	@echo "=== Installed Toolchains ==="
	@rustup show
	@echo ""
	@echo "=== Installed Components ==="
	@rustup component list --installed
	@echo ""
	@echo "=== Key Tools ==="
	@command -v rust-analyzer &> /dev/null && echo -e "  ${GREEN}✓${NC} rust-analyzer"
	@command -v cargo-watch &> /dev/null && echo -e "  ${GREEN}✓${NC} cargo-watch"
	@command -v cargo-edit &> /dev/null && echo -e "  ${GREEN}✓${NC} cargo-edit"
	@command -v cargo-nextest &> /dev/null && echo -e "  ${GREEN}✓${NC} cargo-nextest"
	@command -v bacon &> /dev/null && echo -e "  ${GREEN}✓${NC} bacon"
	@command -v sccache &> /dev/null && echo -e "  ${GREEN}✓${NC} sccache" || true
	@echo ""
	@echo "=== Cargo Binaries ==="
	@ls -la ~/.cargo/bin | head -15
	@echo -e "${GREEN}✓${NC} Rust verification complete"

# Help
help-rust:
	@echo "ArmyknifeLabs Rust Ecosystem Module"
	@echo "The most comprehensive Rust development environment"
	@echo ""
	@echo "Installation Profiles:"
	@echo "  make all      - Complete installation"
	@echo "  make minimal  - Basic setup with essential tools"
	@echo ""
	@echo "Components:"
	@echo "  install-system-deps     - System libraries"
	@echo "  install-rustup         - Rust toolchain manager"
	@echo "  install-toolchains     - Multiple Rust versions"
	@echo "  install-components     - Rust components"
	@echo "  install-cargo-tools    - Essential cargo extensions"
	@echo "  install-dev-tools      - Development utilities"
	@echo "  install-web-tools      - Web frameworks and tools"
	@echo "  install-wasm-tools     - WebAssembly toolchain"
	@echo "  install-embedded-tools - Embedded development"
	@echo "  install-cli-tools      - CLI utilities"
	@echo "  install-testing        - Testing frameworks"
	@echo "  install-linters        - Linters and formatters"
	@echo "  install-security-tools - Security scanners"
	@echo "  install-performance-tools - Profiling tools"
	@echo "  install-build-tools    - Build and release tools"
	@echo ""
	@echo "Toolchains: $(RUST_CHANNELS)"
	@echo "Default: $(DEFAULT_CHANNEL)"
	@echo "Cross-compilation targets: $(RUST_TARGETS)"