#!/bin/bash

# Project Update and Deployment Script
# Downloads fresh copy from legalestate.tech/legal.zip and deploys

set -e  # Exit on any error

PROJECT_URL="https://legalestate.tech/legal.zip"
TEMP_DIR="/tmp/legal_project_$$"
BACKUP_DIR="./backup_$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to cleanup on exit
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        print_status "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check for required commands
    local missing_commands=()
    
    if ! command_exists "curl" && ! command_exists "wget"; then
        missing_commands+=("curl or wget")
    fi
    
    if ! command_exists "unzip"; then
        missing_commands+=("unzip")
    fi
    
    if ! command_exists "docker"; then
        missing_commands+=("docker")
    fi
    
    if ! command_exists "docker-compose" && ! command_exists "docker compose"; then
        missing_commands+=("docker-compose")
    fi
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        print_error "Missing required commands: ${missing_commands[*]}"
        print_error "Please install the missing dependencies and try again."
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
}

# Function to backup existing project
backup_existing() {
    if [ "$(ls -A . 2>/dev/null)" ]; then
        print_status "Backing up existing project to $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        
        # Copy all files except the backup directory itself
        for item in * .*; do
            if [ "$item" != "." ] && [ "$item" != ".." ] && [ "$item" != "$(basename "$BACKUP_DIR")" ]; then
                if [ -e "$item" ]; then
                    cp -r "$item" "$BACKUP_DIR/" 2>/dev/null || true
                fi
            fi
        done
        
        print_success "Backup created at $BACKUP_DIR"
    else
        print_status "No existing files to backup"
    fi
}

# Function to clean current directory
clean_directory() {
    print_status "Cleaning current directory..."
    
    # Remove all files and directories except backup
    for item in * .*; do
        if [ "$item" != "." ] && [ "$item" != ".." ] && [ "$item" != "$(basename "$BACKUP_DIR")" ]; then
            if [ -e "$item" ]; then
                rm -rf "$item"
            fi
        fi
    done
    
    print_success "Directory cleaned"
}

# Function to download project
download_project() {
    print_status "Creating temporary directory..."
    mkdir -p "$TEMP_DIR"
    
    print_status "Downloading project from $PROJECT_URL..."
    
    local download_success=false
    
    # Try curl first, then wget
    if command_exists "curl"; then
        if curl -L -f -o "$TEMP_DIR/legal.zip" "$PROJECT_URL"; then
            download_success=true
        fi
    elif command_exists "wget"; then
        if wget -O "$TEMP_DIR/legal.zip" "$PROJECT_URL"; then
            download_success=true
        fi
    fi
    
    if [ "$download_success" = false ]; then
        print_error "Failed to download project from $PROJECT_URL"
        print_error "Please check the URL and your internet connection"
        exit 1
    fi
    
    print_success "Project downloaded successfully"
}

# Function to extract project
extract_project() {
    print_status "Extracting project files..."
    
    # Check if zip file exists and is valid
    if [ ! -f "$TEMP_DIR/legal.zip" ]; then
        print_error "Downloaded zip file not found"
        exit 1
    fi
    
    # Test zip file integrity
    if ! unzip -t "$TEMP_DIR/legal.zip" >/dev/null 2>&1; then
        print_error "Downloaded zip file is corrupted"
        exit 1
    fi
    
    # Extract to current directory
    if unzip -q "$TEMP_DIR/legal.zip" -d "$TEMP_DIR/extracted"; then
        print_success "Project extracted successfully"
    else
        print_error "Failed to extract project files"
        exit 1
    fi
    
    # Move extracted contents to current directory
    # Handle case where zip contains a single root directory
    local extracted_dir="$TEMP_DIR/extracted"
    local content_count=$(ls -1 "$extracted_dir" | wc -l)
    
    if [ "$content_count" -eq 1 ] && [ -d "$extracted_dir"/* ]; then
        # Single directory - move its contents
        local single_dir=$(ls -1 "$extracted_dir")
        mv "$extracted_dir/$single_dir"/* . 2>/dev/null || true
        mv "$extracted_dir/$single_dir"/.[!.]* . 2>/dev/null || true
    else
        # Multiple items - move all
        mv "$extracted_dir"/* . 2>/dev/null || true
        mv "$extracted_dir"/.[!.]* . 2>/dev/null || true
    fi
}

# Function to make scripts executable
make_scripts_executable() {
    if [ -d "scripts" ]; then
        print_status "Making scripts executable..."
        chmod +x scripts/*.sh 2>/dev/null || true
        print_success "Scripts made executable"
    fi
}

# Function to setup environment
setup_environment() {
    print_status "Setting up environment..."
    
    # Check if setup script exists and run it
    if [ -f "scripts/neon_setup_script.sh" ]; then
        print_status "Running Neon database setup..."
        ./scripts/neon_setup_script.sh
    elif [ -f "scripts/setup_neon.sh" ]; then
        print_status "Running Neon database setup..."
        ./scripts/setup_neon.sh
    elif [ -f "scripts/install_admin_route.sh" ]; then
        print_status "Running admin route setup..."
        ./scripts/install_admin_route.sh
    else
        print_warning "No setup script found, proceeding with manual setup..."
        
        # Manual setup
        if [ -d "backend" ] && [ -f "backend/package.json" ]; then
            print_status "Installing backend dependencies..."
            cd backend
            npm install
            cd ..
        fi
        
        if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
            print_status "Installing frontend dependencies..."
            cd frontend
            npm install
            cd ..
        fi
        
        # Setup Prisma if available
        if [ -d "backend" ] && [ -f "backend/prisma/schema.prisma" ]; then
            print_status "Setting up Prisma..."
            cd backend
            npx prisma generate
            npx prisma db push 2>/dev/null || print_warning "Prisma DB push failed - you may need to configure your database URL"
            cd ..
        fi
    fi
}

# Function to deploy project
deploy_project() {
    print_status "Deploying project..."
    
    # Check if deployment script exists and run it
    if [ -f "scripts/deploy_script.sh" ]; then
        print_status "Running deployment script..."
        ./scripts/deploy_script.sh
    elif [ -f "scripts/deploy.sh" ]; then
        print_status "Running deployment script..."
        ./scripts/deploy.sh
    elif [ -f "docker-compose.yml" ]; then
        print_status "Deploying with Docker Compose..."
        
        # Set docker-compose command (handle both v1 and v2)
        if command_exists "docker-compose"; then
            COMPOSE_CMD="docker-compose"
        else
            COMPOSE_CMD="docker compose"
        fi
        
        # Stop any existing containers
        $COMPOSE_CMD down 2>/dev/null || true
        
        # Build and start services
        $COMPOSE_CMD up --build -d
        
        if [ $? -eq 0 ]; then
            print_success "Deployment successful!"
            echo ""
            echo "🌐 Application URLs:"
            echo "   Frontend: http://localhost:3000"
            echo "   Backend API: http://localhost:3001"
            echo ""
            echo "👤 Default admin credentials:"
            echo "   Email: admin@example.com"
            echo "   Password: admin123"
            echo ""
            echo "📊 View logs with: $COMPOSE_CMD logs -f"
            echo "🛑 Stop services with: $COMPOSE_CMD down"
        else
            print_error "Deployment failed!"
            exit 1
        fi
    else
        print_warning "No deployment script or docker-compose.yml found"
        print_status "You may need to deploy manually"
    fi
}

# Function to show status
show_status() {
    print_status "Checking deployment status..."
    
    if command_exists "docker"; then
        echo ""
        echo "📊 Docker containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
    fi
    
    # Check if services are responding
    print_status "Checking service health..."
    
    # Check backend
    if curl -s -f http://localhost:3001/health >/dev/null 2>&1; then
        print_success "Backend is running (http://localhost:3001)"
    else
        print_warning "Backend may not be running (http://localhost:3001)"
    fi
    
    # Check frontend (simple check for port 3000)
    if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
        print_success "Frontend is running (http://localhost:3000)"
    else
        print_warning "Frontend may not be running (http://localhost:3000)"
    fi
}

# Main execution
main() {
    echo "🚀 Project Update and Deployment Script"
    echo "==============================================="
    echo "This script will:"
    echo "1. Backup existing project"
    echo "2. Download fresh copy from legalestate.tech/legal.zip"
    echo "3. Extract and deploy the project"
    echo ""
    
    # Ask for confirmation
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled by user"
        exit 0
    fi
    
    # Execute steps
    check_prerequisites
    backup_existing
    clean_directory
    download_project
    extract_project
    make_scripts_executable
    setup_environment
    deploy_project
    show_status
    
    echo ""
    print_success "🎉 Project update and deployment completed successfully!"
    echo ""
    print_status "If you encounter any issues:"
    print_status "1. Check the logs: docker-compose logs -f"
    print_status "2. Restore from backup: cp -r $BACKUP_DIR/* ."
    print_status "3. Check the README.md for additional setup instructions"
}

# Run main function
main "$@"