# ArmyknifeLabs Platform Installer - Comprehensive Project Documentation

## Project Overview
The ArmyknifeLabs Platform Installer is a comprehensive developer workstation setup system that automates the installation and configuration of development tools, programming languages, cloud CLIs, security tools, and productivity utilities across Ubuntu/Debian, Fedora/RHEL, and macOS systems.

## Repository Structure
```
armyknife-platform/
├── Makefile                    # Main orchestrator with menu system
├── makefiles/                  # Modular makefile components
│   ├── Makefile.Base.mk       # Core system tools, build dependencies
│   ├── Makefile.Shell.mk      # Shell enhancements (Oh-My-Bash, Starship)
│   ├── Makefile.PackageMgrs.mk # Package managers (Nix, Homebrew)
│   ├── Makefile.Languages.mk  # Programming languages (Python, Node, Go, Rust)
│   ├── Makefile.Database.mk   # Databases (PostgreSQL 18, MySQL, MongoDB, Redis)
│   ├── Makefile.ShellTools.mk # Terminal tools (fzf, bat, ripgrep, exa)
│   ├── Makefile.Git.mk        # Git ecosystem tools
│   ├── Makefile.Security.mk   # Security tools (GPG, age, password managers)
│   ├── Makefile.Containers.mk # Docker, Podman, Kubernetes
│   ├── Makefile.Virtualization.mk # VirtualBox, Vagrant, Packer
│   ├── Makefile.Network.mk    # Tailscale, monitoring tools
│   ├── Makefile.Cloud.mk      # AWS, Azure, GCP, Linode CLIs
│   ├── Makefile.AI-Assistants.mk # VS Code, Cursor, Zed
│   └── Makefile.Bashlibs.mk   # Bash function libraries
├── bashlib/                    # Bash function libraries
│   ├── 00_core.sh            # Core functions (logging, utilities)
│   ├── 10_git.sh             # Git helper functions
│   ├── 20_docker.sh          # Docker shortcuts
│   ├── 30_kubernetes.sh      # Kubernetes utilities
│   └── 70_security.sh        # Security & API key management
├── bin/                        # Executable scripts
│   └── ak-apikey              # API key manager CLI
├── scripts/                    # Support scripts
│   ├── interactive-menu.sh    # Interactive installation menu
│   ├── verify-install.sh      # Installation verification
│   └── doctor.sh              # Diagnostic tool
└── docs/                       # Documentation

Installation Directory: ~/.armyknife/
├── bashlib/                   # Installed bash libraries
├── bin/                        # User binaries (age, ak-apikey)
├── config/                     # Configuration files
├── encrypted-keys/             # Age-encrypted API keys
└── logs/                       # Installation logs
```

## Key Features Implemented

### 1. Modular Makefile Architecture
- **Main Orchestrator**: Root Makefile provides profiles (minimal, standard, full) and menu system
- **Component Makefiles**: Each makefile handles specific tool categories
- **Installation Profiles**:
  - `minimal`: Base system + shell (~15 min)
  - `standard`: Common developer tools (~45 min)
  - `full`: Everything including VMs and cloud tools (~90 min)
  - `menu`: Interactive component selection

### 2. Visual Feedback System
- **Figlet Banners**: Each component shows completion banner
- **Color-coded Output**: Success (green), warnings (yellow), errors (red), info (blue)
- **Progress Tracking**: Real-time feedback during installation
- **Fallback Display**: Text banners when figlet unavailable

### 3. API Key Management System
Three-tier security approach for API keys:

#### LastPass Integration
```bash
add-api-key 'OpenAI' 'sk-xxxxx'
get-api-key 'OpenAI'
list-api-keys
```

#### 1Password Integration with Environment Variables
```bash
add-1p-api-key 'OPENAI_API_KEY' 'sk-xxxxx' 'Development'
# Creates reference: op://Development/OPENAI_API_KEY/api_key
setup-1p-env .env 'Development'  # Generate .env with references
```

#### Age Encryption (Local, Offline-capable)
```bash
age-encrypt-key 'GITHUB_TOKEN' 'ghp_xxxxx'
age-decrypt-key 'GITHUB_TOKEN'
backup-api-keys ~/backup.tar.age  # Encrypted backup
```

#### Hybrid Security
```bash
secure-api-key 'CRITICAL_KEY' 'value' '1p'  # Both 1Password + age
```

### 4. Bash Function Library (bashlib)
Comprehensive collection of helper functions:
- **Git**: `gst`, `glg`, `gcm`, `gnb`, `gpush`, `gpull`
- **Docker**: `dps`, `dex`, `dlogs`, `dstop`, `dclean`
- **Kubernetes**: `kpods`, `kdesc`, `klogs`, `kexec`, `kpf`
- **Security**: `genpass`, `genssh`, `checkssl`, `gpgenc`
- **Core**: `ak_info`, `ak_success`, `ak_error`, `ak_warning`

### 5. Interactive Menu System
```bash
make menu  # Launches interactive component selector
```
- ASCII art banner with figlet
- Toggle selection for components
- Visual feedback for selected items
- Batch installation of selected components

## Critical Implementation Details

### 1. Shell Compatibility
- **Use `[` not `[[`**: POSIX compliance for `/bin/sh`
- **Explicit bash**: Add `SHELL := /bin/bash` to makefiles
- **Function guards**: Prevent double-sourcing with guard variables

### 2. Error Handling Patterns
```makefile
@if command -v tool &> /dev/null; then \
    echo "Tool exists"; \
else \
    echo "Installing tool..."; \
    install_command || true; \
fi
```

### 3. Cross-Platform Support
```makefile
OS_TYPE := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo macos)
IS_MACOS := $(shell if [ "$$(uname -s)" = "Darwin" ]; then echo true; else echo false; fi)
PACKAGE_MANAGER := $(if $(filter ubuntu debian,$(OS_TYPE)),apt,$(if $(filter fedora rhel,$(OS_TYPE)),dnf,brew))
SUDO := $(if $(IS_MACOS),,sudo)
```

### 4. Function Export Pattern
```bash
# Guard to prevent double sourcing
if [ -z "${ARMYKNIFE_GIT_LOADED}" ]; then
export ARMYKNIFE_GIT_LOADED=1

# Define functions
gst() { git status --short --branch "${@}"; }

# Export functions
export -f gst

fi # End of guard
```

### 5. Age Encryption Setup
```bash
# Install age to user directory (no sudo required)
curl -L https://github.com/FiloSottile/age/releases/download/v1.2.0/age-v1.2.0-linux-amd64.tar.gz | \
    tar -xz -C /tmp && \
    mv /tmp/age/age* ~/.armyknife/bin/ && \
    chmod +x ~/.armyknife/bin/age*
```

## Common Issues & Solutions

### 1. GPG Key Conflicts
```makefile
# Handle both microsoft.gpg and packages.microsoft.gpg
@if [ -f /usr/share/keyrings/microsoft.gpg ] && \
    [ -f /usr/share/keyrings/packages.microsoft.gpg ]; then \
    $(SUDO) rm -f /usr/share/keyrings/microsoft.gpg; \
fi
```

### 2. npm Permission Issues
```makefile
# Use local npm prefix instead of global
@npm config set prefix ~/.npm-global 2>/dev/null || true
@export PATH="$$HOME/.npm-global/bin:$$PATH"
```

### 3. Bashlib Not Loading
```bash
# Add to end of .bashrc
source /home/developer/.armyknife/bashlib/lib/main.sh
export PATH="$HOME/.armyknife/bin:$PATH"
```

### 4. Oh-My-Bash Plugin Errors
```bash
# Remove problematic plugins from .bashrc
plugins=(git bashmarks kubectl aws)  # Remove 'docker' if causing issues
```

### 5. Function Redefinition Errors
Use guard variables to prevent double-sourcing (see Function Export Pattern above)

## Testing Commands

### Installation Test
```bash
make install-bashlibs
source ~/.bashrc
ak_help  # Should show available functions
```

### API Key Management Test
```bash
# Test age encryption
age-encrypt-key 'TEST_KEY' 'test-value'
age-decrypt-key 'TEST_KEY'  # Should return: test-value

# Test CLI wrapper
ak-apikey help
ak-apikey age add 'TEST' 'value'
ak-apikey age get 'TEST'
```

### Function Availability Test
```bash
source ~/.armyknife/bashlib/lib/main.sh
type gst  # Should show function definition
gst       # Should run git status
```

## Installation Profiles

### Minimal (~15 minutes)
- Base system updates
- Build tools & compilers
- Shell enhancements (Oh-My-Bash/Zsh)
- Core bash libraries

### Standard (~45 minutes) - RECOMMENDED
Includes Minimal plus:
- Package managers (Nix, Homebrew)
- Programming languages (Python, Node, Go, Rust)
- Basic databases (PostgreSQL, Redis)
- Shell tools (fzf, bat, ripgrep)
- Git ecosystem
- Security tools
- Docker & containers
- Basic network tools
- Core AI assistants

### Full (~90 minutes)
Includes Standard plus:
- All databases (MongoDB, MySQL, InfluxDB)
- Virtualization (VirtualBox, Vagrant)
- Complete cloud CLIs (AWS, Azure, GCP, Linode)
- All AI assistants (VS Code, Cursor, Zed)
- Extended monitoring tools

## Key Configuration Files

### Main Makefile
- Provides installation profiles
- Interactive menu system (`make menu`)
- Individual component targets (`make install-languages`)
- ASCII banner with figlet

### Bashlib Security Functions
- `add-api-key`: Store in LastPass
- `add-1p-api-key`: Store in 1Password with env references
- `age-encrypt-key`: Local encrypted storage
- `secure-api-key`: Hybrid approach (cloud + local)
- `backup-api-keys`: Create encrypted backup

### Environment Setup
```bash
# .bashrc additions
source /home/developer/.armyknife/bashlib/lib/main.sh
export PATH="$HOME/.armyknife/bin:$PATH"
export ARMYKNIFE_DIR="$HOME/.armyknife"
```

## Success Criteria
1. ✅ `source ~/.bashrc` completes without errors
2. ✅ All bashlib functions available (`gst`, `dps`, `kpods`)
3. ✅ Age encryption working (`age-encrypt-key`, `age-decrypt-key`)
4. ✅ Interactive menu launches with `make menu`
5. ✅ Visual feedback with figlet banners
6. ✅ API key management functional with multiple providers
7. ✅ No shell compatibility errors
8. ✅ Cross-platform support (Ubuntu, Fedora, macOS)

## Repository
```
https://github.com/armyknife-tools/platform-installer
```

## Quick Start
```bash
git clone https://github.com/armyknife-tools/platform-installer.git
cd platform-installer
make menu        # Interactive installation
# OR
make standard    # Recommended preset
```

## Complete Implementation Checklist

### Core Infrastructure
- [x] Modular makefile architecture
- [x] Cross-platform OS detection
- [x] Package manager abstraction
- [x] Sudo/non-sudo handling
- [x] Installation logging system
- [x] Error handling with fallbacks

### Visual & UX
- [x] Figlet ASCII banners
- [x] Color-coded output
- [x] Interactive menu system
- [x] Progress indicators
- [x] Completion messages

### Tool Categories
- [x] Base system & build tools
- [x] Shell enhancements
- [x] Package managers
- [x] Programming languages
- [x] Databases
- [x] Shell tools
- [x] Git ecosystem
- [x] Security tools
- [x] Containers
- [x] Virtualization
- [x] Network tools
- [x] Cloud CLIs
- [x] AI assistants
- [x] Bash libraries

### API Key Management
- [x] LastPass integration
- [x] 1Password integration
- [x] Age encryption
- [x] Hybrid security approach
- [x] CLI wrapper (ak-apikey)
- [x] Backup functionality
- [x] Environment variable references

### Bash Function Library
- [x] Core functions (logging, utilities)
- [x] Git shortcuts
- [x] Docker helpers
- [x] Kubernetes utilities
- [x] Security functions
- [x] Guard variables for double-sourcing
- [x] Function exports

### Error Fixes Applied
- [x] Shell compatibility (POSIX)
- [x] GPG key conflicts
- [x] npm permissions
- [x] Heredoc syntax
- [x] Function redefinition
- [x] Oh-My-Bash plugin issues
- [x] Starship initialization
- [x] fnm command errors

## Advanced Features

### 1. Environment Variable Security (1Password)
```bash
# Store API key with 1Password reference
add-1p-api-key 'OPENAI_API_KEY' 'sk-xxxxx' 'Development'

# Use in .env file
export OPENAI_API_KEY='op://Development/OPENAI_API_KEY/api_key'

# Run application with secrets injected at runtime
op run --env-file=.env -- python app.py
```

### 2. Offline-Capable Encryption (Age)
```bash
# Generate age identity (one-time)
age-keygen -o ~/.config/age/keys.txt

# Encrypt API key
echo "sk-xxxxx" | age -r $(age-keygen -y < ~/.config/age/keys.txt) > key.age

# Decrypt when needed
age -d -i ~/.config/age/keys.txt key.age
```

### 3. Selective Component Installation
```bash
# Install specific components only
make install-languages install-databases
make install-vscode install-cursor

# Parallel installation
make -j4 install-shell-tools install-git-tools
```

### 4. Backup & Recovery
```bash
# Create encrypted backup of all API keys
backup-api-keys ~/api-backup-$(date +%Y%m%d).tar.age

# Includes exports from:
# - LastPass (CSV)
# - 1Password (JSON)
# - Age-encrypted keys (files)
```

## Pricing Comparison (API Key Managers)

### LastPass
- Personal: Free (limited)
- Premium: $3/month
- Families: $4/month

### 1Password
- Individual: $2.99/month
- Family: $4.99/month
- Business: $7.99/user/month
- **Key Feature**: Environment variable references without exposing secrets

### Age Encryption
- Cost: Free (open source)
- **Key Feature**: Works offline, Git-safe, CI/CD compatible

## Future Enhancements

1. **Auto-update mechanism** for installed tools
2. **Rollback capability** for failed installations
3. **Profile export/import** for team standardization
4. **Docker container** version for isolated testing
5. **CI/CD integration** for automated setup
6. **Cloud backup** for encrypted keys
7. **Team sharing** for development environments
8. **Version pinning** for reproducible builds

## Contributing

1. Fork the repository
2. Create feature branch
3. Add component makefile to `makefiles/`
4. Update main Makefile targets
5. Add bash functions to `bashlib/`
6. Test across platforms
7. Submit pull request

## License
MIT License - See LICENSE file in repository

## Support
- Issues: https://github.com/armyknife-tools/platform-installer/issues
- Documentation: /docs directory in repository
- Diagnostics: `make doctor`

This comprehensive system provides a production-ready developer workstation setup with robust API key management, extensive bash utilities, and a modular architecture that allows selective installation of components.