#!/usr/bin/env bash
#
# ArmyknifeLabs Interactive Installation
# scripts/interactive-install.sh
#
# Provides beautiful TUI when gum is available,
# falls back to basic prompts otherwise
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source libraries
source "$PROJECT_DIR/lib/core.sh" 2>/dev/null || source "$HOME/.armyknife/lib/core.sh" 2>/dev/null || true
source "$PROJECT_DIR/lib/ui.sh" 2>/dev/null || source "$HOME/.armyknife/lib/ui.sh" 2>/dev/null || true

# Installation variables
PROFILE=""
COMPONENTS=""
INSTALL_DIR="$PROJECT_DIR"
GITHUB_USER=""
GITHUB_EMAIL=""
CLOUD_PROVIDERS=""
ENABLE_TAILSCALE=false
ENABLE_VIRTUALIZATION=false
INSTALL_OPTIONS=""

# Component descriptions
declare -A COMPONENT_DESC=(
    ["base"]="OS updates, build tools, compiler toolchain (REQUIRED)"
    ["shell"]="Oh-My-Bash/Zsh with modern themes (REQUIRED)"
    ["package-mgrs"]="Nix, enhanced package repositories"
    ["languages"]="Python, Node.js, Go, Rust, Java version managers"
    ["shell-tools"]="fzf, bat, ripgrep, starship, modern CLI tools"
    ["git"]="Git ecosystem, GitHub CLI, git helpers"
    ["security"]="GPG, age encryption, password managers"
    ["containers"]="Docker, Podman, Kubernetes tools"
    ["virtualization"]="VirtualBox, Vagrant, Packer, VM tools"
    ["network"]="Tailscale VPN, fleet management"
    ["cloud"]="AWS, Azure, GCP, Linode CLI tools"
)

# Component time estimates
declare -A COMPONENT_TIME=(
    ["base"]="5 min"
    ["shell"]="3 min"
    ["package-mgrs"]="5 min"
    ["languages"]="15 min"
    ["shell-tools"]="10 min"
    ["git"]="5 min"
    ["security"]="5 min"
    ["containers"]="10 min"
    ["virtualization"]="15 min"
    ["network"]="5 min"
    ["cloud"]="10 min"
)

# Welcome screen
show_welcome() {
    ui_clear

    if [ "$HAVE_GUM" = true ]; then
        cat << 'EOF' | gum style --foreground 212 --align center
     _                           _  __      _  __
    / \   _ __ _ __ ___  _   _  | |/ /_ __ (_)/ _| ___
   / _ \ | '__| '_ ` _ \| | | | | ' /| '_ \| | |_ / _ \
  / ___ \| |  | | | | | | |_| | | . \| | | | |  _|  __/
 /_/   \_\_|  |_| |_| |_|\__, | |_|\_\_| |_|_|_|  \___|
                         |___/
              Platform Installer v1.0
EOF
        echo
        gum style --foreground 240 --italic --align center \
            "The Ultimate Software Development Workstation"
        echo
        ui_pause "Press any key to begin setup"
    else
        ui_banner "ArmyknifeLabs Platform Installer v1.0" \
                 "The Ultimate Software Development Workstation"
        echo
        ui_info "Welcome! Let's set up your development environment."
        echo
        ui_pause
    fi
}

# System detection with progress
detect_system() {
    ui_clear "ArmyknifeLabs Platform Installer"
    echo

    ui_header "System Detection"
    echo

    ui_progress "Detecting operating system" "sleep 1"

    # Use core library detection
    ak_detect_os

    local os_desc=$(ak_get_os_description)

    echo
    ui_info "System Information:"
    ui_list \
        "OS: $os_desc" \
        "Architecture: $AK_OS_ARCH" \
        "Package Manager: $AK_PACKAGE_MANAGER" \
        "CPU Cores: $(ak_get_cpu_cores)" \
        "Memory: $(ak_get_memory_mb) MB"

    echo
    ui_success "System detected successfully"
    echo

    if [ "$AK_OS_TYPE" = "unknown" ]; then
        ui_error "Unsupported operating system!"
        ui_info "Supported: Ubuntu, Debian, Linux Mint, Fedora, RHEL, macOS"
        exit 1
    fi

    # macOS shell preference
    if [ "$AK_OS_TYPE" = "macos" ]; then
        echo
        ui_header "Shell Configuration"
        echo

        local current_shell=$(basename "$SHELL")
        ui_info "Current shell: $current_shell"
        echo

        if [ "$current_shell" != "bash" ]; then
            ui_info "macOS uses zsh by default, but bash is also supported."
            ui_info "Zsh → Oh-My-Zsh will be installed"
            ui_info "Bash → Oh-My-Bash will be installed"
            echo

            if ui_confirm "Switch to /bin/bash for better compatibility?" "n"; then
                echo
                ui_info "Changing default shell to /bin/bash..."
                chsh -s /bin/bash
                export SHELL=/bin/bash
                ui_success "Default shell changed to bash"
                ui_warning "You'll need to restart your terminal after installation"
                echo
            else
                ui_info "Continuing with zsh"
                echo
            fi
        else
            ui_success "Using bash shell - Oh-My-Bash will be installed"
            echo
        fi
    fi

    ui_pause
}

# Profile selection
select_profile() {
    ui_clear "ArmyknifeLabs Platform Installer"
    echo

    ui_header "Installation Profile"
    echo
    ui_info "Choose a pre-configured installation profile or customize your selection."
    echo

    local profile_options=(
        "minimal:Base system + shell configuration (~15 min)"
        "standard:Common developer tools (~45 min) [RECOMMENDED]"
        "full:Everything including VMs and cloud tools (~90 min)"
        "custom:Select specific components"
    )

    if [ "$HAVE_GUM" = true ]; then
        local formatted_options=()
        for opt in "${profile_options[@]}"; do
            IFS=':' read -r value desc <<< "$opt"
            if [[ "$desc" == *"RECOMMENDED"* ]]; then
                formatted_options+=("$(gum style --foreground 212 "$value") - $desc")
            else
                formatted_options+=("$value - $desc")
            fi
        done

        local selection=$(printf '%s\n' "${formatted_options[@]}" | \
            gum choose --cursor-prefix "→ " --selected-prefix "✓ ")

        PROFILE=$(echo "$selection" | cut -d' ' -f1 | sed 's/\x1b\[[0-9;]*m//g')
    else
        ui_numbered_list \
            "minimal - Base system + shell (~15 min)" \
            "standard - Common dev tools (~45 min) [RECOMMENDED]" \
            "full - Everything (~90 min)" \
            "custom - Select specific components"

        local choice=$(ui_input "Select profile number" "2")
        case "$choice" in
            1) PROFILE="minimal" ;;
            2) PROFILE="standard" ;;
            3) PROFILE="full" ;;
            4) PROFILE="custom" ;;
            *) PROFILE="standard" ;;
        esac
    fi

    ui_success "Selected profile: $PROFILE"
    echo
}

# Custom component selection
select_custom_components() {
    if [ "$PROFILE" != "custom" ]; then
        # Set default components based on profile
        case "$PROFILE" in
            minimal)
                COMPONENTS="base shell"
                ;;
            standard)
                COMPONENTS="base shell package-mgrs languages shell-tools git security containers"
                ;;
            full)
                COMPONENTS="base shell package-mgrs languages shell-tools git security containers virtualization network cloud"
                ;;
        esac
        return
    fi

    ui_clear "ArmyknifeLabs Platform Installer"
    echo

    ui_header "Component Selection"
    echo
    ui_info "Select the components you want to install."
    ui_info "Base and Shell are required and will be selected automatically."
    echo

    if [ "$HAVE_GUM" = true ]; then
        local component_list=()
        for comp in base shell package-mgrs languages shell-tools git security containers virtualization network cloud; do
            local desc="${COMPONENT_DESC[$comp]}"
            local time="${COMPONENT_TIME[$comp]}"
            component_list+=("$comp - $desc [$time]")
        done

        local selected=$(printf '%s\n' "${component_list[@]}" | \
            gum choose --no-limit \
                --cursor-prefix "[ ] " \
                --selected-prefix "[✓] " \
                --header "Use SPACE to select, ENTER to confirm" \
                --selected "base - ${COMPONENT_DESC[base]} [${COMPONENT_TIME[base]}]" \
                --selected "shell - ${COMPONENT_DESC[shell]} [${COMPONENT_TIME[shell]}]")

        COMPONENTS=""
        while IFS= read -r line; do
            local comp=$(echo "$line" | cut -d' ' -f1)
            COMPONENTS="$COMPONENTS $comp"
        done <<< "$selected"
        COMPONENTS=$(echo "$COMPONENTS" | xargs)  # Trim whitespace
    else
        ui_info "Available components:"
        echo

        local i=1
        local comp_array=()
        for comp in base shell package-mgrs languages shell-tools git security containers virtualization network cloud; do
            echo "  $i) $comp - ${COMPONENT_DESC[$comp]} [${COMPONENT_TIME[$comp]}]"
            comp_array+=("$comp")
            ((i++))
        done

        echo
        local selection=$(ui_input "Enter component numbers (space-separated, 1 2 required)" "1 2 4 5 6 7 8")

        COMPONENTS=""
        for num in $selection; do
            if [ $num -ge 1 ] && [ $num -le ${#comp_array[@]} ]; then
                COMPONENTS="$COMPONENTS ${comp_array[$((num-1))]}"
            fi
        done
        COMPONENTS=$(echo "$COMPONENTS" | xargs)

        # Ensure base and shell are included
        if [[ ! "$COMPONENTS" =~ "base" ]]; then
            COMPONENTS="base $COMPONENTS"
        fi
        if [[ ! "$COMPONENTS" =~ "shell" ]]; then
            COMPONENTS="shell $COMPONENTS"
        fi
    fi

    echo
    ui_success "Selected components: $COMPONENTS"
    echo

    # Calculate estimated time
    local total_time=0
    for comp in $COMPONENTS; do
        local time="${COMPONENT_TIME[$comp]}"
        time=${time% min}
        total_time=$((total_time + time))
    done
    ui_info "Estimated installation time: $total_time minutes"
    echo

    ui_pause
}

# Configuration options
configure_options() {
    ui_clear "ArmyknifeLabs Platform Installer"
    echo

    ui_header "Additional Configuration"
    echo

    # GitHub configuration
    if [[ "$COMPONENTS" =~ "git" ]] || [ "$PROFILE" != "minimal" ]; then
        if ui_confirm "Configure GitHub integration?"; then
            echo
            GITHUB_USER=$(ui_input "GitHub username" "")
            GITHUB_EMAIL=$(ui_input "GitHub email" "")
            echo
        fi
    fi

    # Cloud provider configuration
    if [[ "$COMPONENTS" =~ "cloud" ]] || [ "$PROFILE" = "full" ]; then
        if ui_confirm "Configure cloud provider CLIs?"; then
            echo
            ui_info "Select cloud providers to configure:"

            if [ "$HAVE_GUM" = true ]; then
                CLOUD_PROVIDERS=$(printf '%s\n' "AWS" "Azure" "GCP" "Linode" "DigitalOcean" | \
                    gum choose --no-limit --header "Select providers (SPACE to select)")
            else
                ui_numbered_list "AWS" "Azure" "GCP" "Linode" "DigitalOcean"
                local selection=$(ui_input "Enter provider numbers (space-separated)" "1 3")
                local providers=("AWS" "Azure" "GCP" "Linode" "DigitalOcean")
                CLOUD_PROVIDERS=""
                for num in $selection; do
                    if [ $num -ge 1 ] && [ $num -le 5 ]; then
                        CLOUD_PROVIDERS="$CLOUD_PROVIDERS ${providers[$((num-1))]}"
                    fi
                done
            fi
            echo
        fi
    fi

    # Tailscale configuration
    if [[ "$COMPONENTS" =~ "network" ]] || [ "$PROFILE" = "full" ]; then
        if ui_confirm "Enable Tailscale VPN for fleet management?"; then
            ENABLE_TAILSCALE=true
            echo
        fi
    fi

    # Virtualization options
    if [[ "$COMPONENTS" =~ "virtualization" ]]; then
        if ui_confirm "Download Vagrant base boxes after installation?"; then
            ENABLE_VIRTUALIZATION=true
            echo
        fi
    fi

    # Installation directory confirmation
    ui_info "Installation directory: $INSTALL_DIR"
    if ui_confirm "Change installation directory?" "n"; then
        INSTALL_DIR=$(ui_input "Enter installation directory" "$INSTALL_DIR")
        echo
    fi
}

# Show installation summary
show_installation_summary() {
    ui_clear "ArmyknifeLabs Platform Installer"
    echo

    ui_header "Installation Summary"
    echo

    if [ "$HAVE_GUM" = true ]; then
        local summary_items=(
            "Profile: $(gum style --foreground 212 "$PROFILE")"
            "Components: $COMPONENTS"
            "Install Directory: $INSTALL_DIR"
        )

        [ -n "$GITHUB_USER" ] && summary_items+=("GitHub: $GITHUB_USER <$GITHUB_EMAIL>")
        [ -n "$CLOUD_PROVIDERS" ] && summary_items+=("Cloud Providers: $CLOUD_PROVIDERS")
        [ "$ENABLE_TAILSCALE" = true ] && summary_items+=("Tailscale: Enabled")
        [ "$ENABLE_VIRTUALIZATION" = true ] && summary_items+=("Vagrant Boxes: Will download")

        gum style \
            --border double --border-foreground 212 \
            --padding "1 2" --margin "1" \
            "$(printf '%s\n' "${summary_items[@]}")"
    else
        ui_box "Configuration" \
            "Profile: $PROFILE" \
            "Components: $COMPONENTS" \
            "Directory: $INSTALL_DIR" \
            "$([ -n "$GITHUB_USER" ] && echo "GitHub: $GITHUB_USER")" \
            "$([ -n "$CLOUD_PROVIDERS" ] && echo "Cloud: $CLOUD_PROVIDERS")" \
            "$([ "$ENABLE_TAILSCALE" = true ] && echo "Tailscale: Enabled")"
    fi

    echo
    ui_separator
    echo

    if ! ui_confirm "Proceed with installation?" "y"; then
        ui_warning "Installation cancelled"
        exit 0
    fi
}

# Run installation with progress tracking
run_installation() {
    ui_clear "ArmyknifeLabs Platform Installer"
    echo

    ui_header "Installing Components"
    echo

    # Export configuration for makefiles
    export ARMYKNIFE_INSTALL_DIR="$INSTALL_DIR"
    export ARMYKNIFE_PROFILE="$PROFILE"
    export ARMYKNIFE_COMPONENTS="$COMPONENTS"
    export GITHUB_USER="$GITHUB_USER"
    export GITHUB_EMAIL="$GITHUB_EMAIL"
    export CLOUD_PROVIDERS="$CLOUD_PROVIDERS"
    export ENABLE_TAILSCALE="$ENABLE_TAILSCALE"

    # Change to project directory
    cd "$PROJECT_DIR"

    # Create progress tracking
    local total_components=$(echo "$COMPONENTS" | wc -w)
    local current=0

    # Install each component
    for component in $COMPONENTS; do
        ((current++))
        ui_progress_bar $current $total_components "Installing"
        echo
        ui_subheader "Installing $component (${COMPONENT_TIME[$component]})"

        if make -f "makefiles/Makefile.$(echo "$component" | sed 's/-/_/g' | awk '{print toupper(substr($0,1,1))substr($0,2)}').mk" all 2>&1 | \
           tee -a "$ARMYKNIFE_LOG_FILE"; then
            ui_component_status "$component" "installed"
        else
            ui_component_status "$component" "failed"
            ui_error "Installation failed for $component"
            if ! ui_confirm "Continue with remaining components?" "y"; then
                exit 1
            fi
        fi
        echo
    done

    ui_success "All components installed!"
    echo
}

# Success message and next steps
show_success() {
    ui_clear

    if [ "$HAVE_GUM" = true ]; then
        cat << 'EOF' | gum style --foreground 212 --align center --bold
🎉 Installation Complete! 🎉
EOF
        echo
        gum style --foreground 240 --italic --align center \
            "Your ArmyknifeLabs Platform is ready!"
        echo
        ui_separator
        echo
        gum style --bold "Next Steps:"
        echo
        gum style --foreground 240 \
            "  1. Restart your shell: $(gum style --foreground 212 'exec $SHELL')" \
            "  2. Verify installation: $(gum style --foreground 212 'make -C $INSTALL_DIR verify')" \
            "  3. View commands: $(gum style --foreground 212 'armyknife help')"
        echo
        ui_separator
        echo

        if ui_confirm "View documentation now?"; then
            if [ "$HAVE_GLOW" = true ]; then
                glow "$PROJECT_DIR/docs/README.md" || glow "$PROJECT_DIR/README.md" || true
            else
                less "$PROJECT_DIR/docs/README.md" || less "$PROJECT_DIR/README.md" || true
            fi
        fi
    else
        ui_banner "🎉 Installation Complete! 🎉"
        echo
        ui_success "Your ArmyknifeLabs Platform is ready!"
        echo
        ui_header "Next Steps:"
        ui_numbered_list \
            "Restart your shell: exec \$SHELL" \
            "Verify installation: make -C $INSTALL_DIR verify" \
            "View commands: armyknife help"
        echo
        ui_info "Documentation: $PROJECT_DIR/docs/README.md"
        echo
    fi
}

# Error handler
handle_error() {
    local exit_code=$?
    ui_error "An error occurred during installation (exit code: $exit_code)"
    ui_info "Check logs at: $ARMYKNIFE_LOG_FILE"
    exit $exit_code
}

# Main installation flow
main() {
    # Set error handler
    trap handle_error ERR

    # Show welcome
    show_welcome

    # Detect system
    detect_system

    # Select profile
    select_profile

    # Select custom components if needed
    select_custom_components

    # Configure options
    configure_options

    # Show summary and confirm
    show_installation_summary

    # Run installation
    run_installation

    # Show success message
    show_success
}

# Run main function
main "$@"