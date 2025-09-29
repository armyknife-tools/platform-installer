# 🛠️ ArmyknifeLabs Platform Installer

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey)
![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-orange)

**The Ultimate Software Development Workstation Setup System**

Transform any Linux or macOS machine into a fully-configured development powerhouse with a single command.

[Installation](#-quick-install) • [Features](#-features) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 🚀 Quick Install

```bash
# One-liner installation (recommended)
curl -fsSL https://raw.githubusercontent.com/armyknife-labs/platform-installer/main/install.sh | bash

# Or with wget
wget -qO- https://raw.githubusercontent.com/armyknife-labs/platform-installer/main/install.sh | bash

# Or clone and install manually
git clone https://github.com/armyknife-labs/platform-installer.git ~/armyknife-platform
cd ~/armyknife-platform
make standard
```

## 📦 Installation Profiles

Choose from pre-configured profiles based on your needs:

| Profile | Description | Time | Components |
|---------|-------------|------|------------|
| **minimal** | Base system + shell only | ~15 min | OS updates, build tools, Oh-My-Bash/Zsh |
| **standard** | Common developer tools | ~45 min | + Languages, containers, git tools |
| **full** | Everything | ~90 min | + VMs, all cloud providers, Tailscale |
| **custom** | Choose your components | Varies | Interactive selection |

### Advanced Installation Options

```bash
# Install specific profile
curl -fsSL https://armyknife.dev/install.sh | bash -s -- --profile minimal

# Install to custom location
curl -fsSL https://armyknife.dev/install.sh | bash -s -- --prefix /opt/armyknife

# Non-interactive mode (for CI/CD)
curl -fsSL https://armyknife.dev/install.sh | bash -s -- --yes --profile standard

# Install specific version
curl -fsSL https://armyknife.dev/install.sh | bash -s -- --version v1.2.3
```

## ✨ Features

### 🖥️ Operating System Support

- ✅ **Ubuntu** 20.04 LTS, 22.04 LTS, 24.04 LTS
- ✅ **Debian** 11 (Bullseye), 12 (Bookworm)
- ✅ **Linux Mint** 20, 21, 22 (Ubuntu-based)
- ✅ **Fedora** 39, 40
- ✅ **RHEL/AlmaLinux/Rocky** 9+
- ✅ **macOS** 13+ (Intel & Apple Silicon)
- ✅ **WSL** Windows Subsystem for Linux

### 🔧 Core Components

#### Base System
- Automatic OS updates and security patches
- Build tools and compiler toolchains
- Essential development libraries
- Automatic update scheduling

#### Shell Environment
- **Oh-My-Bash** (Linux) / **Oh-My-Zsh** (macOS)
- Modern prompts (Powerline, Starship)
- Shell enhancements and productivity tools
- Custom ArmyknifeLabs aliases and functions

#### Programming Languages
- **Python**: pyenv, uv/uvx, pipx, multiple Python versions
- **Node.js**: fnm, pnpm, Bun, latest LTS versions
- **Go**: gvm or mise, latest stable
- **Rust**: rustup, stable and nightly toolchains
- **Java**: SDKMAN!, Java 21 LTS, Maven, Gradle

#### Modern CLI Tools
- **Search**: ripgrep (rg), fd, fzf
- **File Management**: eza/exa, bat, zoxide
- **Git**: GitHub CLI (gh), lazygit, delta, gitleaks
- **Terminals**: tmux, zellij, Alacritty
- **System**: htop, btop, ncdu, duf

#### Container & Orchestration
- Docker & Docker Compose
- Podman (rootless containers)
- Kubernetes: kubectl, helm, k9s, minikube, kind
- Container tools: dive, lazydocker, ctop

#### Virtualization (Optional)
- VirtualBox with Extension Pack
- Vagrant with essential plugins
- Packer for image creation
- QEMU/KVM support

#### Cloud Providers
- **AWS**: CLI v2, aws-vault, eksctl, SAM, CDK
- **Azure**: az CLI, Functions Core Tools
- **GCP**: gcloud SDK, gsutil
- **Multi-cloud**: Terraform, Pulumi, Terragrunt
- **Linode**: linode-cli

#### Security & Secrets
- GPG suite
- age encryption
- Password managers (pass, 1Password CLI, Bitwarden CLI)
- SSH key management
- Secret scanning (gitleaks, trufflehog)
- chezmoi for dotfile management

#### Network & Remote
- Tailscale VPN for secure networking
- Fleet management tools
- Parallel SSH (pssh)
- Ansible for automation

## 📖 Documentation

### Command Reference

After installation, use the `armyknife` command or its alias `ak`:

```bash
# Show help
armyknife help

# Verify installation
armyknife verify

# Diagnose and fix issues
armyknife doctor
armyknife doctor --fix  # Auto-fix issues

# Update all components
armyknife update

# Install specific component
make languages       # Install language tools
make containers      # Install Docker & Kubernetes
make cloud          # Install cloud CLIs

# Clean up
armyknife clean
```

### Bash Library Functions

ArmyknifeLabs provides a comprehensive bash library with 100+ utility functions:

```bash
# OS Detection
ak_detect_os            # Detect OS type and version
ak_get_os_description   # Human-readable OS description

# Package Management
ak_install <package>    # Cross-platform package installation
ak_update_all          # Update all package managers

# Docker Utilities
ak_docker_cleanup      # Clean Docker resources
ak_docker_shell <container>  # Open shell in container

# Cloud Management
ak_aws_profile <profile>     # Switch AWS profile
ak_gcp_project <project>     # Switch GCP project

# Secret Management
ak_secret_get <key>         # Retrieve secret
ak_secret_rotate           # Rotate API keys
```

See [docs/USAGE.md](docs/USAGE.md) for complete function reference.

## 🏗️ Architecture

ArmyknifeLabs uses a modular makefile architecture for maintainability and selective installation:

```
armyknife-platform/
├── Makefile                  # Main orchestrator
├── makefiles/
│   ├── Makefile.Base.mk      # OS updates, build tools
│   ├── Makefile.Shell.mk     # Shell configuration
│   ├── Makefile.Languages.mk # Programming languages
│   └── ...                   # Other component makefiles
├── lib/
│   ├── core.sh               # Core bash functions
│   ├── ui.sh                 # Terminal UI library
│   └── ...                   # Component-specific libraries
├── scripts/
│   ├── install.sh            # One-liner installer
│   ├── interactive-install.sh # TUI installer
│   ├── verify-install.sh    # Verification script
│   └── doctor.sh             # Diagnostic tool
└── docs/                     # Documentation
```

## 🎨 Interactive Installation

ArmyknifeLabs features a beautiful terminal UI when [gum](https://github.com/charmbracelet/gum) is available:

- Interactive component selection
- Real-time progress tracking
- Syntax-highlighted output
- Automatic fallback to basic prompts

## 🔒 Security

### Secret Management

ArmyknifeLabs implements multi-layered secret management:

- **Never stores plaintext secrets** in shell RC files
- Integrates with 1Password CLI, HashiCorp Vault, AWS Secrets Manager
- Uses age encryption for local secrets
- Automatic secret rotation capabilities
- Git pre-commit hooks to prevent secret leaks

### Best Practices

- All operations are idempotent (safe to run multiple times)
- Automatic backups before system modifications
- Comprehensive error handling and rollback
- Detailed logging of all operations
- Non-root installation (uses sudo only when necessary)

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development

```bash
# Run tests
make test

# Run specific component
make -f makefiles/Makefile.Languages.mk all

# Enable debug logging
export AK_LOG_LEVEL=DEBUG
make standard

# Dry run (preview changes)
make --dry-run standard
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

ArmyknifeLabs Platform builds upon many excellent open-source projects:

- [Oh My Bash](https://github.com/ohmybash/oh-my-bash) / [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Charm](https://charm.sh) for beautiful TUI tools
- [Homebrew](https://brew.sh) for macOS package management
- All the amazing tool authors whose software we install

## 📞 Support

- 📖 [Documentation](https://github.com/armyknife-labs/platform-installer/wiki)
- 🐛 [Issue Tracker](https://github.com/armyknife-labs/platform-installer/issues)
- 💬 [Discussions](https://github.com/armyknife-labs/platform-installer/discussions)
- ⭐ [Star us on GitHub](https://github.com/armyknife-labs/platform-installer)

---

<div align="center">

**Built with ❤️ by ArmyknifeLabs**

*Transform your workstation into a development powerhouse*

</div># platform-installer
