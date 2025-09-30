# ArmyknifeLabs Platform Installer - Go Ecosystem Module
# Makefile.Golang.mk
#
# The most comprehensive Go development environment
# For: Backend developers, DevOps engineers, Cloud native developers, System programmers
# Features: Multiple Go versions, modern tools, frameworks, testing, and cloud-native development

# Import parent variables
ARMYKNIFE_DIR ?= $(HOME)/.armyknife
LOG_FILE ?= $(ARMYKNIFE_DIR)/logs/install-golang-$(shell date +%Y%m%d-%H%M%S).log
GO_DIR := $(ARMYKNIFE_DIR)/golang

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

# Go versions
GO_VERSIONS := 1.20.14 1.21.13 1.22.10 1.23.3
DEFAULT_GO := 1.23.3

# Go installation
GVM_INSTALLER := https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer
G_INSTALLER := https://raw.githubusercontent.com/stefanmaric/g/master/bin/install

# Architecture mapping for Go
ifeq ($(ARCH),x86_64)
    GO_ARCH := amd64
else ifeq ($(ARCH),aarch64)
    GO_ARCH := arm64
else ifeq ($(ARCH),arm64)
    GO_ARCH := arm64
else
    GO_ARCH := $(ARCH)
endif

# Phony targets
.PHONY: all minimal install-system-deps install-gvm install-g install-go-versions \
        install-core-tools install-web-frameworks install-modern-tools install-cli-tools \
        install-testing install-linters install-cloud-native install-database-tools \
        install-devops install-security-tools install-performance-tools install-build-tools \
        configure-go create-projects verify-golang

# Main target - install everything
all: install-system-deps install-gvm install-go-versions install-core-tools \
     install-web-frameworks install-modern-tools install-cli-tools install-testing \
     install-linters install-cloud-native install-database-tools install-devops \
     install-security-tools install-performance-tools install-build-tools \
     configure-go create-projects verify-golang

# Minimal installation
minimal: install-system-deps install-gvm install-go-versions install-core-tools \
         install-linters configure-go

# Install system dependencies
install-system-deps:
	@echo -e "${BLUE}ℹ${NC} Installing Go system dependencies..."
	@mkdir -p $$(dirname $(LOG_FILE))
ifeq ($(PACKAGE_MANAGER),apt)
	@sudo apt update && sudo apt install -y \
		build-essential git mercurial curl wget \
		gcc g++ make pkg-config \
		libssl-dev libcurl4-openssl-dev \
		protobuf-compiler upx-ucl \
		2>&1 | tee -a $(LOG_FILE)
else ifeq ($(PACKAGE_MANAGER),dnf)
	@sudo dnf install -y gcc gcc-c++ make git mercurial \
		curl wget openssl-devel libcurl-devel \
		protobuf-compiler upx \
		2>&1 | tee -a $(LOG_FILE)
else ifeq ($(IS_MACOS),true)
	@brew install git mercurial curl wget \
		protobuf upx pkg-config 2>/dev/null || true
endif
	@echo -e "${GREEN}✓${NC} System dependencies installed"

# Install gvm (Go Version Manager)
install-gvm:
	@echo -e "${BLUE}ℹ${NC} Installing gvm..."
	@if [ -d "$$HOME/.gvm" ]; then \
		echo -e "${GREEN}✓${NC} gvm already installed"; \
	else \
		bash < <(curl -s -S -L $(GVM_INSTALLER)) 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} gvm installed"; \
	fi
	@# Configure shell
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ] && ! grep -q "gvm/scripts/gvm" $$rc; then \
			echo '' >> $$rc; \
			echo '# GVM' >> $$rc; \
			echo '[[ -s "$$HOME/.gvm/scripts/gvm" ]] && source "$$HOME/.gvm/scripts/gvm"' >> $$rc; \
		fi; \
	done

# Install g (alternative Go version manager)
install-g:
	@echo -e "${BLUE}ℹ${NC} Installing g version manager..."
	@if command -v g &> /dev/null; then \
		echo -e "${GREEN}✓${NC} g already installed"; \
	else \
		curl -sSL $(G_INSTALLER) | sh -s 2>&1 | tee -a $(LOG_FILE); \
		echo -e "${GREEN}✓${NC} g installed"; \
	fi

# Install Go versions
install-go-versions:
	@echo -e "${BLUE}ℹ${NC} Installing Go versions..."
	@if [ -d "$$HOME/.gvm" ]; then \
		source $$HOME/.gvm/scripts/gvm && \
		for version in $(GO_VERSIONS); do \
			if ! gvm list | grep -q "go$$version"; then \
				echo "  Installing Go $$version..."; \
				gvm install go$$version --binary 2>&1 | tee -a $(LOG_FILE) || \
				gvm install go$$version 2>&1 | tee -a $(LOG_FILE); \
			else \
				echo -e "  ${GREEN}✓${NC} Go $$version already installed"; \
			fi; \
		done && \
		gvm use go$(DEFAULT_GO) --default; \
	else \
		echo "  Installing Go $(DEFAULT_GO) directly..."; \
		wget -q -O /tmp/go.tar.gz https://go.dev/dl/go$(DEFAULT_GO).linux-$(GO_ARCH).tar.gz && \
		sudo rm -rf /usr/local/go && \
		sudo tar -C /usr/local -xzf /tmp/go.tar.gz && \
		rm /tmp/go.tar.gz; \
	fi
	@echo -e "${GREEN}✓${NC} Go versions installed"

# Install core Go tools
install-core-tools:
	@echo -e "${BLUE}ℹ${NC} Installing core Go tools..."
	@# Language servers and development tools
	@go install golang.org/x/tools/gopls@latest  # Language server
	@go install github.com/go-delve/delve/cmd/dlv@latest  # Debugger
	@go install github.com/ramya-rao-a/go-outline@latest
	@go install github.com/uudashr/gopkgs/v2/cmd/gopkgs@latest
	@go install github.com/josharian/impl@latest  # Generate interface implementations
	@go install github.com/fatih/gomodifytags@latest  # Modify struct tags
	@go install github.com/cweill/gotests/gotests@latest  # Generate tests
	@go install github.com/koron/iferr@latest  # Generate if err != nil
	@# Documentation
	@go install golang.org/x/tools/cmd/godoc@latest
	@go install github.com/davecheney/httpstat@latest
	@# Package management
	@go install github.com/golang/dep/cmd/dep@latest 2>/dev/null || true
	@go install github.com/tools/godep@latest 2>/dev/null || true
	@go install github.com/Masterminds/glide@latest 2>/dev/null || true
	@# Code generation
	@go install github.com/golang/mock/mockgen@latest
	@go install github.com/vektra/mockery/v2@latest
	@go install golang.org/x/tools/cmd/stringer@latest
	@go install github.com/deepmap/oapi-codegen/cmd/oapi-codegen@latest
	@echo -e "${GREEN}✓${NC} Core tools installed"

# Install web frameworks and tools
install-web-frameworks:
	@echo -e "${BLUE}ℹ${NC} Installing Go web frameworks and tools..."
	@# Web frameworks
	@go install github.com/gin-gonic/gin@latest 2>/dev/null || true
	@go install github.com/labstack/echo/v4@latest 2>/dev/null || true
	@go install github.com/gofiber/fiber/v2@latest 2>/dev/null || true
	@go install github.com/beego/bee/v2@latest
	@go install github.com/revel/cmd/revel@latest
	@# API development
	@go install github.com/swaggo/swag/cmd/swag@latest  # Swagger generator
	@go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
	@go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	@go install github.com/bufbuild/buf/cmd/buf@latest  # Protocol buffer tool
	@# GraphQL
	@go install github.com/99designs/gqlgen@latest
	@go install github.com/Khan/genqlient@latest
	@# WebSocket & real-time
	@go install github.com/centrifugal/centrifugo/v5@latest
	@go install github.com/dunglas/mercure/cmd/mercure@latest
	@echo -e "${GREEN}✓${NC} Web frameworks installed"

# Install modern cutting-edge tools (2024-2025)
install-modern-tools:
	@echo -e "${BLUE}ℹ${NC} Installing modern Go tools..."
	@# Terminal UI frameworks (Charm tools)
	@go install github.com/charmbracelet/bubbletea@latest
	@go install github.com/charmbracelet/bubbles/...@latest
	@go install github.com/charmbracelet/lipgloss@latest
	@go install github.com/charmbracelet/huh@latest  # Forms and inputs
	@go install github.com/charmbracelet/log@latest  # Structured logging
	@go install github.com/charmbracelet/wish@latest  # SSH apps
	@go install github.com/charmbracelet/vhs@latest  # Terminal recorder
	@# Modern web frameworks
	@go install github.com/a-h/templ/cmd/templ@latest  # HTML templating
	@# Database tools
	@go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	@go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest  # Type-safe SQL
	@go install github.com/pressly/goose/v3/cmd/goose@latest  # Migrations
	@go install entgo.io/ent/cmd/ent@latest  # Entity framework
	@# Development tools
	@go install github.com/air-verse/air@latest  # Live reload
	@go install github.com/cweill/gotests/gotests@latest  # Test generation
	@go install github.com/fatih/gomodifytags@latest  # Struct tag editor
	@go install github.com/josharian/impl@latest  # Interface implementation
	@go install github.com/go-task/task/v3/cmd/task@latest  # Task runner
	@# Desktop/Mobile apps
	@go install fyne.io/fyne/v2/cmd/fyne@latest  # Cross-platform GUI
	@go install github.com/wailsapp/wails/v2/cmd/wails@latest 2>/dev/null || true  # Desktop apps
	@echo -e "${GREEN}✓${NC} Modern tools installed"

# Install CLI tools
install-cli-tools:
	@echo -e "${BLUE}ℹ${NC} Installing CLI development tools..."
	@go install github.com/spf13/cobra-cli@latest  # CLI framework
	@go install github.com/urfave/cli/v2@latest 2>/dev/null || true
	@go install github.com/alecthomas/kingpin/v2@latest 2>/dev/null || true
	@go install github.com/charmbracelet/glow@latest  # Markdown renderer
	@go install github.com/charmbracelet/gum@latest  # Shell scripting
	@go install github.com/charmbracelet/soft-serve/cmd/soft@latest  # Git server
	@go install github.com/jesseduffield/lazygit@latest  # Git TUI
	@go install github.com/jesseduffield/lazydocker@latest  # Docker TUI
	@go install github.com/derailed/k9s@latest  # K8s TUI
	@go install github.com/muesli/duf@latest  # Disk usage
	@go install github.com/antonmedv/fx@latest  # JSON viewer
	@go install github.com/guptarohit/asciigraph/cmd/asciigraph@latest
	@echo -e "${GREEN}✓${NC} CLI tools installed"

# Install testing tools
install-testing:
	@echo -e "${BLUE}ℹ${NC} Installing testing tools..."
	@go install github.com/onsi/ginkgo/v2/ginkgo@latest  # BDD testing
	@go install github.com/onsi/gomega/...@latest
	@go install gotest.tools/gotestsum@latest  # Better test output
	@go install github.com/stretchr/testify@latest 2>/dev/null || true
	@go install github.com/smartystreets/goconvey@latest
	@go install github.com/gavv/httpexpect/v2@latest 2>/dev/null || true
	@go install github.com/zimmski/go-mutesting/cmd/go-mutesting@latest  # Mutation testing
	@go install github.com/gotestyourself/gotestsum@latest
	@# Benchmarking
	@go install github.com/benchstat/cmd/benchstat@latest 2>/dev/null || true
	@go install golang.org/x/perf/cmd/benchstat@latest
	@go install github.com/cespare/prettybench@latest
	@# Coverage
	@go install github.com/axw/gocov/gocov@latest
	@go install github.com/matm/gocov-html/cmd/gocov-html@latest
	@go install github.com/AlekSi/gocov-xml@latest
	@# Fuzz testing
	@go install github.com/dvyukov/go-fuzz/go-fuzz@latest
	@go install github.com/dvyukov/go-fuzz/go-fuzz-build@latest
	@echo -e "${GREEN}✓${NC} Testing tools installed"

# Install linters and formatters
install-linters:
	@echo -e "${BLUE}ℹ${NC} Installing linters and formatters..."
	@# Meta linter
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@# Individual linters
	@go install golang.org/x/tools/cmd/goimports@latest
	@go install golang.org/x/lint/golint@latest 2>/dev/null || true
	@go install github.com/kisielk/errcheck@latest
	@go install honnef.co/go/tools/cmd/staticcheck@latest
	@go install github.com/securego/gosec/v2/cmd/gosec@latest  # Security
	@go install github.com/mgechev/revive@latest
	@go install github.com/jgautheron/goconst/cmd/goconst@latest
	@go install github.com/mdempsky/unconvert@latest
	@go install github.com/mvdan/gofumpt@latest  # Stricter gofmt
	@go install mvdan.cc/sh/v3/cmd/shfmt@latest  # Shell formatter
	@# Complexity analysis
	@go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
	@go install github.com/uudashr/gocognit/cmd/gocognit@latest
	@go install github.com/segmentio/golines@latest  # Long lines
	@go install github.com/daixiang0/gci@latest  # Import formatter
	@echo -e "${GREEN}✓${NC} Linters installed"

# Install cloud-native and Kubernetes tools
install-cloud-native:
	@echo -e "${BLUE}ℹ${NC} Installing cloud-native tools..."
	@# Kubernetes
	@go install sigs.k8s.io/kind@latest  # Local K8s clusters
	@go install github.com/kubernetes-sigs/kubebuilder/cmd/kubebuilder@latest
	@go install sigs.k8s.io/kustomize/kustomize/v5@latest
	@go install github.com/ahmetb/kubectx/cmd/kubectx@latest
	@go install github.com/ahmetb/kubectx/cmd/kubens@latest
	@go install github.com/vmware-tanzu/octant/cmd/octant@latest 2>/dev/null || true
	@go install github.com/pulumi/kubespy@latest
	@go install github.com/kubeshark/kubeshark/cli@latest 2>/dev/null || true
	@# Helm
	@go install helm.sh/helm/v3/cmd/helm@latest 2>/dev/null || true
	@go install github.com/databus23/helm-diff@latest 2>/dev/null || true
	@# Service mesh
	@go install github.com/linkerd/linkerd2/cli/cmd@latest 2>/dev/null || true
	@go install istio.io/istio/istioctl/cmd/istioctl@latest 2>/dev/null || true
	@# Container tools
	@go install github.com/google/go-containerregistry/cmd/crane@latest
	@go install github.com/google/ko@latest  # Container builder
	@go install github.com/buildpacks/pack/cmd/pack@latest 2>/dev/null || true
	@go install github.com/GoogleContainerTools/skaffold/v2/cmd/skaffold@latest 2>/dev/null || true
	@# Operators
	@go install sigs.k8s.io/controller-tools/cmd/controller-gen@latest
	@go install github.com/operator-framework/operator-sdk/cmd/operator-sdk@latest 2>/dev/null || true
	@echo -e "${GREEN}✓${NC} Cloud-native tools installed"

# Install database tools
install-database-tools:
	@echo -e "${BLUE}ℹ${NC} Installing database tools..."
	@# SQL
	@go install github.com/xo/usql@latest  # Universal SQL client
	@go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	@go install github.com/rubenv/sql-migrate/...@latest
	@go install github.com/pressly/goose/v3/cmd/goose@latest
	@go install github.com/amacneil/dbmate@latest
	@go install github.com/kyleconroy/sqlc/cmd/sqlc@latest  # SQL compiler
	@go install github.com/volatiletech/sqlboiler/v4@latest
	@go install entgo.io/ent/cmd/ent@latest  # Entity framework
	@# NoSQL
	@go install github.com/mongodb/mongo-tools/...@latest 2>/dev/null || true
	@go install github.com/redis/go-redis/v9@latest 2>/dev/null || true
	@# Database utilities
	@go install github.com/lesovsky/pgcenter@latest 2>/dev/null || true
	@go install github.com/sosedoff/pgweb@latest
	@echo -e "${GREEN}✓${NC} Database tools installed"

# Install DevOps tools
install-devops:
	@echo -e "${BLUE}ℹ${NC} Installing DevOps tools..."
	@# CI/CD
	@go install github.com/nektos/act@latest  # Run GitHub Actions locally
	@go install github.com/drone/drone-cli/cmd/drone@latest 2>/dev/null || true
	@go install github.com/tektoncd/cli/cmd/tkn@latest 2>/dev/null || true
	@# Infrastructure as Code
	@go install github.com/hashicorp/terraform@latest 2>/dev/null || true
	@go install github.com/gruntwork-io/terragrunt@latest 2>/dev/null || true
	@go install github.com/terraform-docs/terraform-docs@latest
	@go install github.com/terraform-linters/tflint@latest
	@go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
	@go install github.com/bridgecrewio/checkov@latest 2>/dev/null || true
	@# Configuration management
	@go install github.com/ansible/ansible@latest 2>/dev/null || true
	@go install github.com/hashicorp/consul@latest 2>/dev/null || true
	@go install github.com/hashicorp/vault@latest 2>/dev/null || true
	@# Monitoring
	@go install github.com/prometheus/prometheus/cmd/...@latest 2>/dev/null || true
	@go install github.com/grafana/loki/cmd/...@latest 2>/dev/null || true
	@echo -e "${GREEN}✓${NC} DevOps tools installed"

# Install security tools
install-security-tools:
	@echo -e "${BLUE}ℹ${NC} Installing security tools..."
	@go install github.com/securego/gosec/v2/cmd/gosec@latest
	@go install github.com/sonatype/nancy@latest 2>/dev/null || true
	@go install github.com/aquasecurity/trivy/cmd/trivy@latest 2>/dev/null || true
	@go install github.com/anchore/syft/cmd/syft@latest
	@go install github.com/anchore/grype/cmd/grype@latest
	@go install github.com/liamg/amass/v3/...@latest 2>/dev/null || true
	@go install github.com/OWASP/Amass/v3/...@latest 2>/dev/null || true
	@go install github.com/zricethezav/gitleaks/v8@latest  # Secret scanning
	@go install github.com/trufflesecurity/trufflehog/v3@latest 2>/dev/null || true
	@go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
	@go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
	@go install github.com/projectdiscovery/httpx/cmd/httpx@latest
	@go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
	@echo -e "${GREEN}✓${NC} Security tools installed"

# Install performance tools
install-performance-tools:
	@echo -e "${BLUE}ℹ${NC} Installing performance tools..."
	@go install github.com/google/pprof@latest
	@go install github.com/uber-archive/go-torch@latest 2>/dev/null || true
	@go install github.com/felixge/fgprof@latest 2>/dev/null || true
	@go install github.com/pkg/profile@latest 2>/dev/null || true
	@go install github.com/rakyll/hey@latest  # HTTP load testing
	@go install github.com/bojand/ghz@latest  # gRPC load testing
	@go install github.com/fortio/fortio@latest  # Load testing
	@go install github.com/tsenart/vegeta@latest  # HTTP load testing
	@go install github.com/codesenberg/bombardier@latest
	@go install github.com/nakabonne/ali@latest  # Load testing with TUI
	@echo -e "${GREEN}✓${NC} Performance tools installed"

# Install build and release tools
install-build-tools:
	@echo -e "${BLUE}ℹ${NC} Installing build and release tools..."
	@go install github.com/goreleaser/goreleaser@latest
	@go install github.com/mitchellh/gox@latest  # Cross-compilation
	@go install github.com/tcnksm/ghr@latest  # GitHub releases
	@go install github.com/aktau/github-release@latest
	@go install github.com/c4milo/github-release@latest 2>/dev/null || true
	@go install github.com/magefile/mage@latest  # Build tool
	@go install github.com/go-task/task/v3/cmd/task@latest
	@go install github.com/cortesi/modd/cmd/modd@latest  # File watcher
	@go install github.com/cosmtrek/air@latest  # Live reload
	@go install github.com/bokwoon95/wgo@latest  # Another watcher
	@echo -e "${GREEN}✓${NC} Build tools installed"

# Configure Go environment
configure-go:
	@echo -e "${BLUE}ℹ${NC} Configuring Go environment..."
	@# Create Go workspace
	@mkdir -p ~/go/{bin,src,pkg}
	@mkdir -p $(GO_DIR)/{projects,scripts,templates}
	@# Set environment variables
	@for rc in ~/.bashrc ~/.zshrc; do \
		if [ -f $$rc ]; then \
			grep -q "GOPATH" $$rc || echo 'export GOPATH=$$HOME/go' >> $$rc; \
			grep -q "GOBIN" $$rc || echo 'export GOBIN=$$GOPATH/bin' >> $$rc; \
			grep -q 'PATH.*GOBIN' $$rc || echo 'export PATH=$$GOBIN:$$PATH' >> $$rc; \
			grep -q "GO111MODULE" $$rc || echo 'export GO111MODULE=on' >> $$rc; \
			grep -q "GOPROXY" $$rc || echo 'export GOPROXY=https://proxy.golang.org,direct' >> $$rc; \
			grep -q "GOSUMDB" $$rc || echo 'export GOSUMDB=sum.golang.org' >> $$rc; \
		fi; \
	done
	@# Create .golangci.yml
	@cat > ~/.golangci.yml <<-EOF
		linters:
		  enable:
		    - goimports
		    - golint
		    - govet
		    - errcheck
		    - staticcheck
		    - gosec
		    - ineffassign
		    - typecheck
		    - gosimple
		    - goconst
		    - misspell
		    - unparam
		    - gocyclo
		    - gofmt
		issues:
		  exclude-use-default: false
		  max-issues-per-linter: 50
		  max-same-issues: 10
		run:
		  timeout: 5m
	EOF
	@echo -e "${GREEN}✓${NC} Go environment configured"

# Create example projects
create-projects:
	@echo -e "${BLUE}ℹ${NC} Creating example Go projects..."
	@# CLI app template
	@mkdir -p $(GO_DIR)/templates/cli-app
	@cat > $(GO_DIR)/templates/cli-app/main.go <<-EOF
		package main

		import (
			"fmt"
			"os"

			"github.com/spf13/cobra"
		)

		var rootCmd = &cobra.Command{
			Use:   "app",
			Short: "A sample CLI application",
			Run: func(cmd *cobra.Command, args []string) {
				fmt.Println("Hello from Go CLI!")
			},
		}

		func main() {
			if err := rootCmd.Execute(); err != nil {
				fmt.Fprintln(os.Stderr, err)
				os.Exit(1)
			}
		}
	EOF
	@# Web API template
	@mkdir -p $(GO_DIR)/templates/web-api
	@cat > $(GO_DIR)/templates/web-api/main.go <<-EOF
		package main

		import (
			"net/http"

			"github.com/gin-gonic/gin"
		)

		func main() {
			r := gin.Default()

			r.GET("/health", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"status": "healthy",
				})
			})

			r.Run(":8080")
		}
	EOF
	@# Makefile template
	@cat > $(GO_DIR)/templates/Makefile <<-EOF
		.PHONY: build test lint run clean

		build:
			go build -o bin/app ./...

		test:
			go test -v ./...

		lint:
			golangci-lint run

		run:
			go run main.go

		clean:
			rm -rf bin/
	EOF
	@echo -e "${GREEN}✓${NC} Example projects created"

# Verify Go installation
verify-golang:
	@echo -e "${BLUE}ℹ${NC} Verifying Go installation..."
	@echo "=== Go Version ==="
	@go version
	@echo ""
	@echo "=== Go Environment ==="
	@go env GOPATH GOBIN GOROOT
	@echo ""
	@echo "=== Installed Tools ==="
	@command -v gopls &> /dev/null && echo -e "  ${GREEN}✓${NC} gopls (language server)"
	@command -v dlv &> /dev/null && echo -e "  ${GREEN}✓${NC} dlv (debugger)"
	@command -v golangci-lint &> /dev/null && echo -e "  ${GREEN}✓${NC} golangci-lint"
	@command -v swag &> /dev/null && echo -e "  ${GREEN}✓${NC} swag (Swagger)"
	@command -v mockgen &> /dev/null && echo -e "  ${GREEN}✓${NC} mockgen"
	@command -v air &> /dev/null && echo -e "  ${GREEN}✓${NC} air (live reload)"
	@command -v goreleaser &> /dev/null && echo -e "  ${GREEN}✓${NC} goreleaser"
	@echo ""
	@echo "=== Go Modules ==="
	@ls -la ~/go/bin | head -10
	@echo -e "${GREEN}✓${NC} Go verification complete"

# Help
help-golang:
	@echo "ArmyknifeLabs Go Ecosystem Module"
	@echo "The most comprehensive Go development environment"
	@echo ""
	@echo "Installation Profiles:"
	@echo "  make all      - Complete installation"
	@echo "  make minimal  - Basic setup with essential tools"
	@echo ""
	@echo "Components:"
	@echo "  install-system-deps     - System libraries"
	@echo "  install-gvm            - Go Version Manager"
	@echo "  install-go-versions    - Multiple Go versions"
	@echo "  install-core-tools     - Core development tools"
	@echo "  install-web-frameworks - Web frameworks and tools"
	@echo "  install-cli-tools      - CLI development tools"
	@echo "  install-testing        - Testing frameworks"
	@echo "  install-linters        - Linters and formatters"
	@echo "  install-cloud-native   - Kubernetes and cloud tools"
	@echo "  install-database-tools - Database clients and ORMs"
	@echo "  install-devops         - DevOps and IaC tools"
	@echo "  install-security-tools - Security scanners"
	@echo "  install-performance-tools - Profiling and benchmarking"
	@echo ""
	@echo "Go Versions: $(GO_VERSIONS)"
	@echo "Default Version: $(DEFAULT_GO)"