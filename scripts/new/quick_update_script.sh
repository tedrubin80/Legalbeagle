#!/bin/bash

# Quick Update Script - No prompts, fast execution
# For automated deployments or when you're confident

set -e

PROJECT_URL="https://legalestate.tech/legal.zip"
TEMP_DIR="/tmp/legal_quick_$$"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${BLUE}▶${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; exit 1; }

# Cleanup function
cleanup() {
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print_status "Quick project update starting..."

# Check prerequisites
command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || print_error "curl or wget required"
command -v unzip >/dev/null 2>&1 || print_error "unzip required"
command -v docker >/dev/null 2>&1 || print_error "docker required"

# Stop existing containers
if [ -f "docker-compose.yml" ]; then
    print_status "Stopping existing containers..."
    docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true
fi

# Quick backup of critical files
if [ -f "backend/.env" ]; then
    print_status "Backing up environment file..."
    cp backend/.env .env.backup
fi

# Clean directory (keep backups)
print_status "Cleaning directory..."
find . -maxdepth 1 -not -name "*.backup" -not -name "." -not -name ".." -exec rm -rf {} + 2>/dev/null || true

# Download and extract
print_status "Downloading and extracting..."
mkdir -p "$TEMP_DIR"

if command -v curl >/dev/null 2>&1; then
    curl -L -f -o "$TEMP_DIR/legal.zip" "$PROJECT_URL" || print_error "Download failed"
else
    wget -O "$TEMP_DIR/legal.zip" "$PROJECT_URL" || print_error "Download failed"
fi

unzip -q "$TEMP_DIR/legal.zip" -d "$TEMP_DIR/extracted" || print_error "Extract failed"

# Move files
if [ $(ls -1 "$TEMP_DIR/extracted" | wc -l) -eq 1 ] && [ -d "$TEMP_DIR/extracted"/* ]; then
    mv "$TEMP_DIR/extracted"/*/* . 2>/dev/null || true
    mv "$TEMP_DIR/extracted"/*/.[!.]* . 2>/dev/null || true
else
    mv "$TEMP_DIR/extracted"/* . 2>/dev/null || true
    mv "$TEMP_DIR/extracted"/.[!.]* . 2>/dev/null || true
fi

# Restore environment file
if [ -f ".env.backup" ]; then
    print_status "Restoring environment file..."
    mkdir -p backend
    mv .env.backup backend/.env
fi

# Make scripts executable
[ -d "scripts" ] && chmod +x scripts/*.sh

# Quick deploy
print_status "Deploying..."
if [ -f "scripts/deploy.sh" ]; then
    ./scripts/deploy.sh
elif [ -f "docker-compose.yml" ]; then
    # Set docker-compose command
    COMPOSE_CMD="docker-compose"
    command -v docker-compose >/dev/null 2>&1 || COMPOSE_CMD="docker compose"
    
    $COMPOSE_CMD up --build -d || print_error "Deployment failed"
else
    print_error "No deployment method found"
fi

print_success "Quick update completed!"
echo ""
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend: http://localhost:3001"
echo "📊 Logs: docker-compose logs -f"