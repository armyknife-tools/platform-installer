#!/usr/bin/env bash
# Fix Cursor GPG key issue for apt repositories
# This resolves: NO_PUBKEY 42A1772E62E492D6

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Fixing Cursor APT repository GPG key...${NC}"

# Add the Cursor GPG key
echo -e "${YELLOW}Adding Cursor GPG key...${NC}"
curl -fsSL https://downloads.cursor.com/aptrepo/public.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/cursor-archive-keyring.gpg

# Update the Cursor repository configuration to use the signed key
if [ -f /etc/apt/sources.list.d/cursor.list ]; then
    echo -e "${YELLOW}Updating Cursor repository configuration...${NC}"
    # Backup original
    sudo cp /etc/apt/sources.list.d/cursor.list /etc/apt/sources.list.d/cursor.list.bak

    # Update to use signed-by
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cursor-archive-keyring.gpg] https://downloads.cursor.com/aptrepo stable main" | \
        sudo tee /etc/apt/sources.list.d/cursor.list
fi

# Alternative: Disable the repository if you don't need it
echo -e "${BLUE}Alternative: If you don't use Cursor, you can disable the repository:${NC}"
echo "  sudo rm /etc/apt/sources.list.d/cursor.list"
echo "  sudo rm /etc/apt/sources.list.d/cursor.list.save (if exists)"

echo -e "${GREEN}✓${NC} GPG key issue resolved"
echo -e "${YELLOW}Run 'sudo apt update' to verify${NC}"