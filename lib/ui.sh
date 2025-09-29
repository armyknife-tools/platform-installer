#!/usr/bin/env bash
#
# ArmyknifeLabs Platform - UI Library
# lib/ui.sh
#
# Provides consistent, beautiful UI components for terminal interfaces
# Automatically detects and uses gum if available, falls back to basic prompts
#
# Usage:
#   source ~/.armyknife/lib/ui.sh
#   ui_banner "Welcome to ArmyknifeLabs"
#   choice=$(ui_choose "Select an option" "Option 1" "Option 2" "Option 3")
#

# Prevent multiple sourcing
if [ -n "${AK_UI_LOADED:-}" ]; then
    return 0
fi
export AK_UI_LOADED=1

# Source core library if not already loaded
if [ -z "${AK_CORE_LOADED:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/core.sh" 2>/dev/null || true
fi

# Detect available UI tools
export HAVE_GUM=false
export HAVE_DIALOG=false
export HAVE_WHIPTAIL=false
export HAVE_FZF=false
export HAVE_GLOW=false
export HAVE_RICH=false

# Check for gum (primary TUI tool)
if command -v gum &> /dev/null; then
    export HAVE_GUM=true
fi

# Check for dialog/whiptail (fallback TUI tools)
if command -v dialog &> /dev/null; then
    export HAVE_DIALOG=true
elif command -v whiptail &> /dev/null; then
    export HAVE_WHIPTAIL=true
fi

# Check for fzf (fuzzy finder)
if command -v fzf &> /dev/null; then
    export HAVE_FZF=true
fi

# Check for glow (markdown renderer)
if command -v glow &> /dev/null; then
    export HAVE_GLOW=true
fi

# Check for rich-cli (Python rich output)
if command -v rich &> /dev/null; then
    export HAVE_RICH=true
fi

# Terminal capabilities
export TERM_COLS=$(tput cols 2>/dev/null || echo 80)
export TERM_ROWS=$(tput lines 2>/dev/null || echo 24)

# Default UI configuration
export UI_WIDTH=${UI_WIDTH:-70}
export UI_MARGIN=${UI_MARGIN:-2}
export UI_PADDING=${UI_PADDING:-1}

# ==============================================================================
# Banner and Header Functions
# ==============================================================================

# Display a banner with border
# Usage: ui_banner "Title" "Subtitle"
ui_banner() {
    local title="${1:-ArmyknifeLabs Platform}"
    local subtitle="${2:-}"

    if [ "$HAVE_GUM" = true ]; then
        local banner_text="$title"
        [ -n "$subtitle" ] && banner_text="$banner_text\n\n$subtitle"

        gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width "$UI_WIDTH" --margin "$UI_MARGIN" --padding "$UI_PADDING" \
            "$banner_text"
    else
        local border_width=$((UI_WIDTH - 2))
        local border_line=$(printf '═%.0s' $(seq 1 $border_width))

        echo -e "${AK_PURPLE}╔${border_line}╗${AK_NC}"
        echo -e "${AK_PURPLE}║${AK_NC} $(printf "%-${border_width}s" "$title") ${AK_PURPLE}║${AK_NC}"
        [ -n "$subtitle" ] && echo -e "${AK_PURPLE}║${AK_NC} $(printf "%-${border_width}s" "$subtitle") ${AK_PURPLE}║${AK_NC}"
        echo -e "${AK_PURPLE}╚${border_line}╝${AK_NC}"
    fi
}

# Display a section header
# Usage: ui_header "Section Title"
ui_header() {
    local text="$1"

    if [ "$HAVE_GUM" = true ]; then
        gum style --bold --foreground 212 "$text"
    else
        echo -e "${AK_PURPLE}━━━ $text ━━━${AK_NC}"
    fi
}

# Display a subheader
# Usage: ui_subheader "Subsection Title"
ui_subheader() {
    local text="$1"

    if [ "$HAVE_GUM" = true ]; then
        gum style --foreground 214 "▸ $text"
    else
        echo -e "${AK_CYAN}▸ $text${AK_NC}"
    fi
}

# ==============================================================================
# Progress and Status Functions
# ==============================================================================

# Show progress spinner
# Usage: ui_progress "Installing packages" "apt install -y packages"
ui_progress() {
    local message="${1:-Working...}"
    local command="$2"

    if [ "$HAVE_GUM" = true ]; then
        if [ -n "$command" ]; then
            gum spin --spinner dot --title "$message" -- bash -c "$command"
        else
            gum spin --spinner dot --title "$message" -- sleep 2
        fi
    else
        echo -en "${AK_BLUE}⋯${AK_NC} $message..."
        if [ -n "$command" ]; then
            eval "$command" > /dev/null 2>&1
            local exit_code=$?
            if [ $exit_code -eq 0 ]; then
                echo -e " ${AK_GREEN}✓${AK_NC}"
            else
                echo -e " ${AK_RED}✗${AK_NC}"
            fi
            return $exit_code
        else
            sleep 2
            echo -e " ${AK_GREEN}✓${AK_NC}"
        fi
    fi
}

# Show progress bar
# Usage: ui_progress_bar 50 100 "Processing files"
ui_progress_bar() {
    local current=${1:-0}
    local total=${2:-100}
    local message="${3:-}"

    local percent=$((current * 100 / total))
    local bar_width=40
    local filled=$((percent * bar_width / 100))
    local empty=$((bar_width - filled))

    if [ "$HAVE_GUM" = true ]; then
        # Note: gum doesn't have a progress bar yet, simulate with style
        local bar=$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))
        gum style --foreground 212 "$message [$bar] $percent%"
    else
        printf "\r%s [" "$message"
        printf '=%.0s' $(seq 1 $filled)
        printf ' %.0s' $(seq 1 $empty)
        printf '] %d%%' $percent
    fi
}

# ==============================================================================
# Input Functions
# ==============================================================================

# Choose from a list of options
# Usage: choice=$(ui_choose "Select option" "opt1" "opt2" "opt3")
ui_choose() {
    local prompt="${1:-Select an option}"
    shift
    local options=("$@")

    if [ "$HAVE_GUM" = true ]; then
        printf '%s\n' "${options[@]}" | gum choose --header "$prompt"
    elif [ "$HAVE_FZF" = true ]; then
        printf '%s\n' "${options[@]}" | fzf --prompt="$prompt > "
    elif [ "$HAVE_DIALOG" = true ]; then
        local dialog_opts=""
        local i=1
        for opt in "${options[@]}"; do
            dialog_opts="$dialog_opts $i \"$opt\""
            ((i++))
        done
        eval dialog --menu \"$prompt\" 15 50 5 $dialog_opts 2>&1 >/dev/tty
    else
        echo "$prompt:" >&2
        select opt in "${options[@]}"; do
            if [ -n "$opt" ]; then
                echo "$opt"
                break
            fi
        done
    fi
}

# Multi-select from options
# Usage: choices=$(ui_multiselect "Select components" "comp1" "comp2" "comp3")
ui_multiselect() {
    local prompt="${1:-Select options}"
    shift
    local options=("$@")

    if [ "$HAVE_GUM" = true ]; then
        printf '%s\n' "${options[@]}" | gum choose --no-limit --header "$prompt"
    elif [ "$HAVE_FZF" = true ]; then
        printf '%s\n' "${options[@]}" | fzf --multi --prompt="$prompt (TAB to select) > "
    else
        echo "$prompt (space-separated numbers):" >&2
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt" >&2
            ((i++))
        done
        read -p "Selection: " -r selection
        for num in $selection; do
            if [ $num -ge 1 ] && [ $num -le ${#options[@]} ]; then
                echo "${options[$((num-1))]}"
            fi
        done
    fi
}

# Get text input from user
# Usage: name=$(ui_input "Enter your name" "John Doe")
ui_input() {
    local prompt="${1:-Enter value}"
    local placeholder="${2:-}"

    if [ "$HAVE_GUM" = true ]; then
        gum input --placeholder "$placeholder" --prompt "$prompt: "
    else
        local full_prompt="$prompt"
        [ -n "$placeholder" ] && full_prompt="$full_prompt [$placeholder]"
        read -p "$full_prompt: " -r value
        echo "${value:-$placeholder}"
    fi
}

# Get password input (hidden)
# Usage: password=$(ui_password "Enter password")
ui_password() {
    local prompt="${1:-Enter password}"

    if [ "$HAVE_GUM" = true ]; then
        gum input --password --prompt "$prompt: "
    else
        read -s -p "$prompt: " -r password
        echo >&2  # New line after hidden input
        echo "$password"
    fi
}

# Get confirmation from user
# Usage: ui_confirm "Continue?" && echo "Proceeding..."
ui_confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"

    # In non-interactive mode, use default
    if [ "${ARMYKNIFE_NON_INTERACTIVE:-false}" = "true" ]; then
        [ "$default" = "y" ] && return 0 || return 1
    fi

    if [ "$HAVE_GUM" = true ]; then
        gum confirm "$prompt"
    else
        local full_prompt="$prompt"
        if [ "$default" = "y" ]; then
            full_prompt="$full_prompt [Y/n]: "
        else
            full_prompt="$full_prompt [y/N]: "
        fi

        read -p "$full_prompt" -n 1 -r response
        echo >&2  # New line

        case "$response" in
            [yY]) return 0 ;;
            [nN]) return 1 ;;
            "")
                [ "$default" = "y" ] && return 0 || return 1
                ;;
            *) return 1 ;;
        esac
    fi
}

# ==============================================================================
# Output Functions
# ==============================================================================

# Display an info message
# Usage: ui_info "Information message"
ui_info() {
    local message="$1"

    if [ "$HAVE_GUM" = true ]; then
        gum style --foreground 240 "ℹ $message"
    else
        echo -e "${AK_BLUE}ℹ${AK_NC} $message"
    fi
}

# Display a success message
# Usage: ui_success "Operation completed"
ui_success() {
    local message="$1"

    if [ "$HAVE_GUM" = true ]; then
        gum style --foreground 212 "✓ $message"
    else
        echo -e "${AK_GREEN}✓${AK_NC} $message"
    fi
}

# Display an error message
# Usage: ui_error "Something went wrong"
ui_error() {
    local message="$1"

    if [ "$HAVE_GUM" = true ]; then
        gum style --foreground 196 "✗ $message" >&2
    else
        echo -e "${AK_RED}✗${AK_NC} $message" >&2
    fi
}

# Display a warning message
# Usage: ui_warning "Be careful"
ui_warning() {
    local message="$1"

    if [ "$HAVE_GUM" = true ]; then
        gum style --foreground 214 "⚠ $message"
    else
        echo -e "${AK_YELLOW}⚠${AK_NC} $message"
    fi
}

# ==============================================================================
# Table and List Functions
# ==============================================================================

# Display a table
# Usage: ui_table "Name,Version,Status" "Docker,20.10,Installed" "Git,2.34,Installed"
ui_table() {
    local header="$1"
    shift
    local rows=("$@")

    if [ "$HAVE_GUM" = true ]; then
        (echo "$header"; printf '%s\n' "${rows[@]}") | gum table
    elif [ "$HAVE_RICH" = true ]; then
        (echo "$header"; printf '%s\n' "${rows[@]}") | rich --print-table
    else
        (echo "$header"; printf '%s\n' "${rows[@]}") | column -t -s ','
    fi
}

# Display a list with bullets
# Usage: ui_list "Item 1" "Item 2" "Item 3"
ui_list() {
    local items=("$@")

    for item in "${items[@]}"; do
        if [ "$HAVE_GUM" = true ]; then
            gum style --foreground 240 "  • $item"
        else
            echo "  • $item"
        fi
    done
}

# Display a numbered list
# Usage: ui_numbered_list "First" "Second" "Third"
ui_numbered_list() {
    local items=("$@")
    local i=1

    for item in "${items[@]}"; do
        if [ "$HAVE_GUM" = true ]; then
            gum style --foreground 240 "  $i. $item"
        else
            echo "  $i. $item"
        fi
        ((i++))
    done
}

# ==============================================================================
# Box and Panel Functions
# ==============================================================================

# Display text in a box
# Usage: ui_box "Title" "Content line 1" "Content line 2"
ui_box() {
    local title="$1"
    shift
    local content=("$@")

    if [ "$HAVE_GUM" = true ]; then
        local text="$title"
        for line in "${content[@]}"; do
            text="$text\n$line"
        done
        gum style --border normal --border-foreground 212 --padding "1 2" "$text"
    else
        local max_width=0
        for line in "$title" "${content[@]}"; do
            [ ${#line} -gt $max_width ] && max_width=${#line}
        done
        max_width=$((max_width + 4))

        echo "┌$(printf '─%.0s' $(seq 1 $max_width))┐"
        echo "│ $(printf "%-${max_width}s" " $title") │"
        echo "├$(printf '─%.0s' $(seq 1 $max_width))┤"
        for line in "${content[@]}"; do
            echo "│ $(printf "%-${max_width}s" " $line") │"
        done
        echo "└$(printf '─%.0s' $(seq 1 $max_width))┘"
    fi
}

# Display a code block with syntax highlighting
# Usage: ui_code "bash" "echo 'Hello World'"
ui_code() {
    local language="${1:-bash}"
    local code="$2"

    if [ "$HAVE_GUM" = true ]; then
        echo "$code" | gum style --foreground 212 --margin 1
    elif [ "$HAVE_RICH" = true ]; then
        echo "$code" | rich --syntax "$language"
    else
        echo -e "${AK_CYAN}$code${AK_NC}"
    fi
}

# ==============================================================================
# Markdown Functions
# ==============================================================================

# Render markdown
# Usage: ui_markdown "# Title\n\nSome **bold** text"
ui_markdown() {
    local content="$1"

    if [ "$HAVE_GLOW" = true ]; then
        echo "$content" | glow -
    elif [ "$HAVE_RICH" = true ]; then
        echo "$content" | rich --markdown
    elif [ "$HAVE_GUM" = true ]; then
        echo "$content" | gum format
    else
        echo "$content"
    fi
}

# Display a file with markdown rendering
# Usage: ui_render_file "README.md"
ui_render_file() {
    local file="$1"

    if [ ! -f "$file" ]; then
        ui_error "File not found: $file"
        return 1
    fi

    if [ "$HAVE_GLOW" = true ]; then
        glow "$file"
    elif [ "$HAVE_RICH" = true ]; then
        rich --markdown "$file"
    elif [ "$HAVE_GUM" = true ]; then
        gum format < "$file"
    else
        cat "$file"
    fi
}

# ==============================================================================
# Interactive Menu System
# ==============================================================================

# Create an interactive menu
# Usage: selection=$(ui_menu "Main Menu" "Install:install_func" "Configure:config_func" "Exit:exit")
ui_menu() {
    local title="$1"
    shift
    local menu_items=("$@")

    ui_banner "$title"
    echo

    local options=()
    local actions=()

    for item in "${menu_items[@]}"; do
        IFS=':' read -r label action <<< "$item"
        options+=("$label")
        actions+=("$action")
    done

    local choice=$(ui_choose "Select an option" "${options[@]}")

    for i in "${!options[@]}"; do
        if [ "${options[$i]}" = "$choice" ]; then
            echo "${actions[$i]}"
            return 0
        fi
    done
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# Clear screen with optional header
# Usage: ui_clear "ArmyknifeLabs Platform"
ui_clear() {
    local header="$1"

    clear
    [ -n "$header" ] && ui_banner "$header"
}

# Pause execution with message
# Usage: ui_pause "Press any key to continue"
ui_pause() {
    local message="${1:-Press any key to continue...}"

    if [ "$HAVE_GUM" = true ]; then
        gum style --foreground 240 --italic "$message"
    else
        echo -e "${AK_CYAN}$message${AK_NC}"
    fi
    read -n 1 -s -r
}

# Show a separator line
# Usage: ui_separator
ui_separator() {
    local char="${1:-─}"
    local width="${2:-$UI_WIDTH}"

    if [ "$HAVE_GUM" = true ]; then
        gum style --foreground 240 "$(printf "$char%.0s" $(seq 1 $width))"
    else
        printf "$char%.0s" $(seq 1 $width)
        echo
    fi
}

# ==============================================================================
# Installation UI Helpers
# ==============================================================================

# Show installation summary
# Usage: ui_install_summary "Profile" "Components" "Directory"
ui_install_summary() {
    local profile="$1"
    local components="$2"
    local directory="$3"

    if [ "$HAVE_GUM" = true ]; then
        gum style \
            --border double --border-foreground 212 \
            --padding "1 2" --margin "1" --width "$UI_WIDTH" \
            "$(gum style --bold 'Installation Summary')" \
            "" \
            "Profile: $(gum style --foreground 212 "$profile")" \
            "Components: $components" \
            "Directory: $directory"
    else
        ui_box "Installation Summary" \
            "Profile: $profile" \
            "Components: $components" \
            "Directory: $directory"
    fi
}

# Show component status
# Usage: ui_component_status "Docker" "installed"
ui_component_status() {
    local component="$1"
    local status="$2"

    case "$status" in
        installed|success|complete)
            ui_success "$component: $status"
            ;;
        failed|error)
            ui_error "$component: $status"
            ;;
        pending|processing)
            ui_info "$component: $status"
            ;;
        skipped|warning)
            ui_warning "$component: $status"
            ;;
        *)
            echo "$component: $status"
            ;;
    esac
}

# ==============================================================================
# Export Functions
# ==============================================================================

export -f ui_banner ui_header ui_subheader
export -f ui_progress ui_progress_bar
export -f ui_choose ui_multiselect ui_input ui_password ui_confirm
export -f ui_info ui_success ui_error ui_warning
export -f ui_table ui_list ui_numbered_list
export -f ui_box ui_code
export -f ui_markdown ui_render_file
export -f ui_menu
export -f ui_clear ui_pause ui_separator
export -f ui_install_summary ui_component_status

# Log UI capabilities
ak_debug "UI Library loaded - gum:$HAVE_GUM dialog:$HAVE_DIALOG fzf:$HAVE_FZF"