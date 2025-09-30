#!/usr/bin/env bash
# Cleanup script for Python build artifacts and caches
# Run this if Python builds fail or to free up disk space

set -e

echo "🧹 Python Build Cleanup Script"
echo "=============================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Clean temporary Python build directories
echo -e "${BLUE}Cleaning temporary Python build directories...${NC}"
if ls /tmp/python-build* 1> /dev/null 2>&1; then
    rm -rf /tmp/python-build*
    echo -e "${GREEN}✓${NC} Removed Python build directories from /tmp"
else
    echo -e "${YELLOW}ℹ${NC} No Python build directories found"
fi

# Clean pyenv cache
echo -e "${BLUE}Cleaning pyenv cache...${NC}"
if [ -d ~/.pyenv/cache ]; then
    rm -rf ~/.pyenv/cache/*
    echo -e "${GREEN}✓${NC} Cleared pyenv cache"
else
    echo -e "${YELLOW}ℹ${NC} No pyenv cache found"
fi

# Clean uv cache (optional - it's useful to keep)
echo -e "${BLUE}Checking uv cache...${NC}"
if [ -d ~/.cache/uv ]; then
    size=$(du -sh ~/.cache/uv | cut -f1)
    echo -e "${YELLOW}ℹ${NC} uv cache size: $size"
    read -p "Do you want to clear uv cache? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.cache/uv/*
        echo -e "${GREEN}✓${NC} Cleared uv cache"
    else
        echo -e "${YELLOW}ℹ${NC} Keeping uv cache"
    fi
else
    echo -e "${YELLOW}ℹ${NC} No uv cache found"
fi

# Clean pip cache
echo -e "${BLUE}Checking pip cache...${NC}"
if [ -d ~/.cache/pip ]; then
    size=$(du -sh ~/.cache/pip 2>/dev/null | cut -f1)
    echo -e "${YELLOW}ℹ${NC} pip cache size: $size"
    read -p "Do you want to clear pip cache? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.cache/pip/*
        echo -e "${GREEN}✓${NC} Cleared pip cache"
    else
        echo -e "${YELLOW}ℹ${NC} Keeping pip cache"
    fi
fi

# Show disk space
echo ""
echo -e "${BLUE}Disk space summary:${NC}"
df -h /tmp | tail -1
df -h ~ | tail -1

echo ""
echo -e "${GREEN}✓${NC} Cleanup complete!"
echo ""
echo "You can now retry Python installation with:"
echo "  make -f makefiles/Makefile.Python.mk minimal"
echo "or"
echo "  make -f makefiles/Makefile.Python-Fast.mk all"