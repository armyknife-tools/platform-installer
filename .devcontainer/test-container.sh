#!/bin/bash
# Test script for ArmyknifeLabs dev container

echo "========================================"
echo "ArmyknifeLabs Dev Container Test Script"
echo "========================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    echo "Please install Docker Desktop or Docker Engine first"
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose is not installed"
    echo "Please install Docker Compose"
    exit 1
fi

# Determine docker-compose command
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "Building dev container..."
cd .devcontainer
$COMPOSE_CMD build

echo ""
echo "Starting container for tests..."
$COMPOSE_CMD up -d

echo ""
echo "Running tests inside container..."
echo "========================================"

# Test 1: Verify base system
echo "Test 1: Verifying base system..."
$COMPOSE_CMD exec armyknife-dev bash -c "cd /workspace && make verify-base"

# Test 2: Check help system
echo ""
echo "Test 2: Checking help system..."
$COMPOSE_CMD exec armyknife-dev bash -c "cd /workspace && make help | head -20"

# Test 3: Test library functions
echo ""
echo "Test 3: Testing core library..."
$COMPOSE_CMD exec armyknife-dev bash -c "source /workspace/lib/core.sh && detect_os && echo 'OS: \$OS_TYPE'"

# Test 4: Test installation script
echo ""
echo "Test 4: Testing installation script (dry run)..."
$COMPOSE_CMD exec armyknife-dev bash -c "cd /workspace && ./install.sh --help"

# Test 5: Test individual module
echo ""
echo "Test 5: Testing individual module (ShellTools help)..."
$COMPOSE_CMD exec armyknife-dev bash -c "cd /workspace && make help-shelltools"

echo ""
echo "========================================"
echo "Test Results Summary"
echo "========================================"

# Clean up
echo ""
echo "Stopping container..."
$COMPOSE_CMD down

echo ""
echo "Test complete! To use the dev container interactively:"
echo "  cd .devcontainer"
echo "  $COMPOSE_CMD up -d"
echo "  $COMPOSE_CMD exec armyknife-dev bash"
echo ""
echo "Or open this folder in VSCode with the Dev Containers extension."