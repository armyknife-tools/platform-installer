#!/bin/bash

# Interactive menu for ArmyknifeLabs Platform Installer

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Array to track selected components
declare -a selected_components

# Function to display banner
show_banner() {
    clear
    if command -v figlet &> /dev/null; then
        echo -e "${PURPLE}"
        figlet -f slant "ArmyknifeLabs" 2>/dev/null || figlet "ArmyknifeLabs"
        echo -e "${NC}"
        echo -e "${CYAN}         Platform Installer - Component Selection${NC}"
    else
        echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║                    ArmyknifeLabs                          ║${NC}"
        echo -e "${PURPLE}║             Platform Installer Menu                       ║${NC}"
        echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
    fi
    echo ""
}

# Function to display menu
show_menu() {
    show_banner

    # Show selected components
    if [ ${#selected_components[@]} -gt 0 ]; then
        echo -e "${GREEN}Selected components:${NC}"
        printf '%s ' "${selected_components[@]}"
        echo -e "\n"
    else
        echo -e "${YELLOW}No components selected yet${NC}\n"
    fi

    echo -e "${CYAN}Available Components:${NC}"
    echo "  1) Base System       - OS updates, build tools"
    echo "  2) Shell             - Oh-My-Bash/Zsh, Starship"
    echo "  3) Package Managers  - Nix, Homebrew, etc."
    echo "  4) Languages         - Python, Node, Go, Rust"
    echo "  5) Databases         - PostgreSQL, MySQL, MongoDB"
    echo "  6) Shell Tools       - fzf, bat, ripgrep, exa"
    echo "  7) Git Tools         - Git, GitHub CLI, delta"
    echo "  8) Security          - GPG, password managers"
    echo "  9) Containers        - Docker, Kubernetes"
    echo " 10) Virtualization    - VirtualBox, Vagrant"
    echo " 11) Network           - Tailscale, monitoring"
    echo " 12) Cloud             - AWS, Azure, GCP CLIs"
    echo " 13) AI & Editors      - VS Code, Cursor, Zed"
    echo " 14) Bash Libraries    - ArmyknifeLabs bashlib"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  A) Select All Components"
    echo "  C) Clear Selection"
    echo "  I) Install Selected Components"
    echo "  Q) Quit"
    echo ""
}

# Function to toggle component selection
toggle_component() {
    local component=$1
    local found=0

    # Check if component is already selected
    for i in "${!selected_components[@]}"; do
        if [[ "${selected_components[$i]}" == "$component" ]]; then
            # Remove component
            unset 'selected_components[$i]'
            selected_components=("${selected_components[@]}")
            found=1
            break
        fi
    done

    # If not found, add it
    if [ $found -eq 0 ]; then
        selected_components+=("$component")
    fi
}

# Main menu loop
while true; do
    show_menu
    read -p "Enter choice (1-14, A/C/I/Q): " choice

    case $choice in
        1) toggle_component "base" ;;
        2) toggle_component "shell" ;;
        3) toggle_component "package-mgrs" ;;
        4) toggle_component "languages" ;;
        5) toggle_component "databases" ;;
        6) toggle_component "shell-tools" ;;
        7) toggle_component "git" ;;
        8) toggle_component "security" ;;
        9) toggle_component "containers" ;;
        10) toggle_component "virtualization" ;;
        11) toggle_component "network" ;;
        12) toggle_component "cloud" ;;
        13) toggle_component "ai-assistants" ;;
        14) toggle_component "bashlibs" ;;
        A|a)
            selected_components=(
                "base" "shell" "package-mgrs" "languages"
                "databases" "shell-tools" "git" "security"
                "containers" "virtualization" "network"
                "cloud" "ai-assistants" "bashlibs"
            )
            ;;
        C|c)
            selected_components=()
            ;;
        I|i)
            if [ ${#selected_components[@]} -eq 0 ]; then
                echo -e "\n${RED}No components selected!${NC}"
                echo "Press Enter to continue..."
                read
            else
                clear
                echo -e "${GREEN}Installing selected components:${NC}"
                printf '%s ' "${selected_components[@]}"
                echo -e "\n"

                # Install each component
                for component in "${selected_components[@]}"; do
                    echo -e "\n${CYAN}Installing $component...${NC}"
                    make -C "$(dirname "$0")/.." "$component"
                    if [ $? -ne 0 ]; then
                        echo -e "${RED}Failed to install $component${NC}"
                        echo "Press Enter to continue..."
                        read
                    fi
                done

                echo -e "\n${GREEN}Installation complete!${NC}"
                echo "Press Enter to return to menu..."
                read
            fi
            ;;
        Q|q)
            echo -e "\n${BLUE}Thank you for using ArmyknifeLabs Platform Installer!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid choice. Please try again.${NC}"
            sleep 1
            ;;
    esac
done