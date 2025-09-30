#!/bin/bash
# Add completion banners to all makefiles

# Banner function to add to each makefile
BANNER_FUNCTION='# Banner function - will use figlet if available, fallback to echo
define show_completion_banner
	@if command -v figlet &> /dev/null; then \\
		echo ""; \\
		echo -e "${GREEN}"; \\
		figlet -f small "$(1)"; \\
		echo -e "${NC}"; \\
	else \\
		echo ""; \\
		echo -e "${GREEN}========================================${NC}"; \\
		echo -e "${GREEN}   $(1)${NC}"; \\
		echo -e "${GREEN}========================================${NC}"; \\
	fi
endef'

# List of makefiles and their completion messages
declare -A MAKEFILES=(
    ["TypeScript.mk"]="TYPESCRIPT READY"
    ["Golang.mk"]="GOLANG READY"
    ["Rust.mk"]="RUST READY"
    ["Database.mk"]="DATABASE READY"
    ["Git.mk"]="GIT READY"
    ["Security.mk"]="SECURITY READY"
    ["Containers.mk"]="CONTAINERS READY"
    ["Network.mk"]="NETWORK READY"
    ["Cloud.mk"]="CLOUD READY"
    ["AI-Assistants.mk"]="AI TOOLS READY"
    ["Shell.mk"]="SHELL READY"
    ["PackageMgrs.mk"]="PACKAGE MGRS READY"
    ["ShellTools.mk"]="SHELL TOOLS READY"
    ["Virtualization.mk"]="VMs READY"
    ["Bashlibs.mk"]="BASH LIBS READY"
)

MAKEFILE_DIR="/home/developer/localprojects/claude-workstation-setup/armyknife-platform/makefiles"

for MK_FILE in "${!MAKEFILES[@]}"; do
    FILE="$MAKEFILE_DIR/Makefile.$MK_FILE"
    MESSAGE="${MAKEFILES[$MK_FILE]}"

    if [ -f "$FILE" ]; then
        echo "Processing $MK_FILE..."

        # Check if banner function already exists
        if ! grep -q "show_completion_banner" "$FILE"; then
            # Add banner function after color definitions
            # Find the line with NC := and add the function after it
            sed -i "/^NC := /a\\
\\
$BANNER_FUNCTION" "$FILE"
        fi

        # Add banner call before the final verification complete message
        # Look for common patterns in verification/completion messages
        if grep -q "verification complete" "$FILE"; then
            sed -i "/verification complete/i\	\$(call show_completion_banner,$MESSAGE)" "$FILE"
        elif grep -q "setup complete" "$FILE"; then
            sed -i "/setup complete/i\	\$(call show_completion_banner,$MESSAGE)" "$FILE"
        elif grep -q "installation complete" "$FILE"; then
            sed -i "/installation complete/i\	\$(call show_completion_banner,$MESSAGE)" "$FILE"
        fi

        echo "  ✓ Added banner to $MK_FILE"
    else
        echo "  ✗ File not found: $FILE"
    fi
done

echo "Banner addition complete!"