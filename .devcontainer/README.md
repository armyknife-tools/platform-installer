# ArmyknifeLabs Dev Container

This VSCode development container provides a complete environment for developing and testing the ArmyknifeLabs Platform Installer.

## Quick Start

### Option 1: Using VSCode (Recommended)

1. Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open this project folder in VSCode
3. Click "Reopen in Container" when prompted (or use Command Palette: `Dev Containers: Reopen in Container`)
4. Wait for the container to build and initialize
5. The terminal will show available commands when ready

### Option 2: Using Docker Compose

```bash
# Build and start the container
cd .devcontainer
docker compose up -d

# Enter the container
docker compose exec armyknife-dev bash

# Run tests
make verify-base
make help

# Stop the container
docker compose down
```

### Option 3: Using the Test Script

```bash
# Run automated tests
.devcontainer/test-container.sh
```

## Available Commands

Once inside the container:

```bash
# Show all available targets
make help

# Installation profiles
make minimal        # Base system + shell only
make standard       # Common developer tools (recommended)
make full          # Everything including VMs and cloud tools
make custom        # Interactive component selection

# Verify installations
make verify-base   # Check base system
./scripts/verify-install.sh     # Full verification
./scripts/doctor.sh             # Diagnostic with auto-repair

# Individual modules
make install-shell       # Oh-My-Bash/Zsh
make install-shell-tools # fzf, bat, ripgrep, etc.
make install-languages   # Python, Node, Go, Rust, Java
make install-git        # Git ecosystem tools
```

## Container Features

- **Base OS**: Ubuntu 22.04 LTS
- **Pre-installed Tools**:
  - Build essentials (gcc, make, cmake)
  - Git and Git LFS
  - Network tools (curl, wget, jq)
  - Python 3 and pip
  - Node.js and npm
  - Terminal UI tool (gum)

- **VSCode Extensions** (auto-installed):
  - Makefile Tools
  - ShellCheck
  - Bash IDE
  - GitLens
  - Docker support

- **Persistent Storage**:
  - Bash history
  - ArmyknifeLabs installation directory

## Development Workflow

1. **Make changes** to any makefile or script
2. **Test immediately** - no rebuild needed (files are mounted)
3. **Run specific targets** to test individual components
4. **Use the doctor script** to diagnose issues

## Testing Examples

```bash
# Test base installation
make install-base
make verify-base

# Test shell configuration
make install-shell
source ~/.bashrc  # or ~/.zshrc

# Test a specific tool installation
make install-fzf
fzf --version

# Run interactive installer
./scripts/interactive-install.sh

# Test one-liner installer
./install.sh --profile minimal
```

## Troubleshooting

### Container won't build
- Ensure Docker is installed and running
- Check Docker has sufficient resources allocated
- Try: `docker system prune` to clean up space

### Tools not working
- Run `./scripts/doctor.sh` for diagnostics
- Check logs: `tail -f ~/.armyknife/logs/*.log`
- Verify environment: `echo $ARMYKNIFE_DIR`

### Permission issues
- The container runs as user `developer` (UID 1000)
- Sudo is available without password
- Files are mounted with proper permissions

## Notes

- This is a containerized environment - some system operations may be limited
- Docker-in-Docker is enabled for container-related testing
- Network mode is set to `host` for full network access
- The container includes all dependencies needed for Phase 1 installation

## Contributing

When testing changes:

1. Always test in the container first
2. Run `make verify-base` after changes
3. Test both interactive and non-interactive modes
4. Check logs for any errors or warnings
5. Ensure idempotency - run commands multiple times