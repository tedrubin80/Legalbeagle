#!/bin/bash

# Project Manager - Main Control Script
# Central hub for all project management tasks

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Symbols
ARROW="▶"
BULLET="•"
CHECK="✓"
CROSS="✗"

print_header() {
    echo -e "${CYAN}$1${NC}"
    echo "$(printf '=%.0s' $(seq 1 ${#1}))"
}

print_option() {
    printf "${BLUE}%2s${NC} ${YELLOW}%-20s${NC} %s\n" "$1)" "$2" "$3"
}

print_success() { echo -e "${GREEN}${CHECK}${NC} $1"; }
print_error() { echo -e "${RED}${CROSS}${NC} $1"; }
print_info() { echo -e "${BLUE}${ARROW}${NC} $1"; }

# Function to check if script exists and is executable
check_script() {
    local script="$1"
    if [ -f "$script" ] && [ -x "$script" ]; then
        return 0
    else
        return 1
    fi
}

# Function to make script executable if it exists
ensure_executable() {
    local script="$1"
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        chmod +x "$script"
        print_info "Made $script executable"
    fi
}

# Function to create missing scripts
create_missing_scripts() {
    print_info "Checking for missing scripts..."
    
    local scripts_needed=(
        "update_deploy.sh:Full project update and deployment"
        "quick_update.sh:Quick update without prompts"
        "restore_backup.sh:Restore from backup"
        "health_check.sh:Health and status check"
    )
    
    local missing_count=0
    
    for script_info in "${scripts_needed[@]}"; do
        local script=$(echo "$script_info" | cut -d':' -f1)
        if [ ! -f "$script" ]; then
            ((missing_count++))
            print_error "Missing: $script"
        fi
    done
    
    if [ $missing_count -gt 0 ]; then
        echo ""
        print_info "To get the missing scripts, you can:"
        print_info "1. Download them from your repository"
        print_info "2. Use the project update function to get latest version"
        echo ""
    else
        print_success "All scripts are available"
    fi
    
    return $missing_count
}

# Function to show project status
show_status() {
    clear
    print_header "🏗️  Project Status"
    echo ""
    
    # Check if project appears to be set up
    if [ -f "docker-compose.yml" ]; then
        print_success "Project structure detected"
    else
        print_error "Project structure not found"
    fi
    
    # Check Docker
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        local running=$(docker ps --format '{{.Names}}' | wc -l)
        print_success "Docker: $running containers running"
    else
        print_error "Docker not available or not running"
    fi
    
    # Check services
    if command -v curl >/dev/null 2>&1; then
        if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
            print_success "Frontend: Running (http://localhost:3000)"
        else
            print_error "Frontend: Not running"
        fi
        
        if curl -s -f http://localhost:3001/health >/dev/null 2>&1; then
            print_success "Backend: Running (http://localhost:3001)"
        else
            print_error "Backend: Not running"
        fi
    fi
    
    echo ""
}

# Function to run deployment
run_deployment() {
    clear
    print_header "🚀 Deployment Options"
    echo ""
    
    print_option "1" "full-update" "Complete project update from remote"
    print_option "2" "quick-update" "Quick update (no prompts)"
    print_option "3" "docker-deploy" "Deploy with Docker Compose"
    print_option "4" "local-deploy" "Local development setup"
    print_option "0" "back" "Back to main menu"
    
    echo ""
    read -p "Select option: " choice
    
    case $choice in
        1)
            if check_script "update_deploy.sh"; then
                ./update_deploy.sh
            else
                print_error "update_deploy.sh not found"
            fi
            ;;
        2)
            if check_script "quick_update.sh"; then
                ./quick_update.sh
            else
                print_error "quick_update.sh not found"
            fi
            ;;
        3)
            deploy_docker
            ;;
        4)
            deploy_local
            ;;
        0)
            return
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to deploy with Docker
deploy_docker() {
    print_info "Deploying with Docker Compose..."
    
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found"
        return
    fi
    
    # Set docker-compose command
    COMPOSE_CMD="docker-compose"
    if ! command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    fi
    
    print_info "Stopping existing containers..."
    $COMPOSE_CMD down 2>/dev/null || true
    
    print_info "Building and starting services..."
    $COMPOSE_CMD up --build -d
    
    if [ $? -eq 0 ]; then
        print_success "Deployment successful!"
        echo ""
        print_info "Frontend: http://localhost:3000"
        print_info "Backend: http://localhost:3001"
        print_info "Logs: $COMPOSE_CMD logs -f"
    else
        print_error "Deployment failed"
    fi
}

# Function to deploy locally
deploy_local() {
    print_info "Setting up local development environment..."
    
    # Backend setup
    if [ -d "backend" ] && [ -f "backend/package.json" ]; then
        print_info "Installing backend dependencies..."
        cd backend
        npm install
        
        if [ -f "prisma/schema.prisma" ]; then
            print_info "Setting up Prisma..."
            npx prisma generate
            npx prisma db push 2>/dev/null || print_info "Database push failed - may need configuration"
        fi
        cd ..
    fi
    
    # Frontend setup
    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        print_info "Installing frontend dependencies..."
        cd frontend
        npm install
        cd ..
    fi
    
    print_success "Local setup complete!"
    print_info "Start backend: cd backend && npm run dev"
    print_info "Start frontend: cd frontend && npm start"
}

# Function to manage services
manage_services() {
    clear
    print_header "⚙️  Service Management"
    echo ""
    
    print_option "1" "start" "Start all services"
    print_option "2" "stop" "Stop all services"
    print_option "3" "restart" "Restart all services"
    print_option "4" "logs" "View logs"
    print_option "5" "status" "Service status"
    print_option "0" "back" "Back to main menu"
    
    echo ""
    read -p "Select option: " choice
    
    # Set docker-compose command
    COMPOSE_CMD="docker-compose"
    if ! command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    fi
    
    case $choice in
        1)
            print_info "Starting services..."
            $COMPOSE_CMD up -d
            ;;
        2)
            print_info "Stopping services..."
            $COMPOSE_CMD down
            ;;
        3)
            print_info "Restarting services..."
            $COMPOSE_CMD restart
            ;;
        4)
            print_info "Showing logs (Ctrl+C to exit)..."
            $COMPOSE_CMD logs -f
            ;;
        5)
            if check_script "health_check.sh"; then
                ./health_check.sh quick
            else
                $COMPOSE_CMD ps
            fi
            ;;
        0)
            return
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to backup and restore
backup_restore() {
    clear
    print_header "💾 Backup & Restore"
    echo ""
    
    print_option "1" "create-backup" "Create manual backup"
    print_option "2" "restore" "Restore from backup"
    print_option "3" "list-backups" "List available backups"
    print_option "4" "clean-backups" "Clean old backups"
    print_option "0" "back" "Back to main menu"
    
    echo ""
    read -p "Select option: " choice
    
    case $choice in
        1)
            create_manual_backup
            ;;
        2)
            if check_script "restore_backup.sh"; then
                ./restore_backup.sh
            else
                print_error "restore_backup.sh not found"
            fi
            ;;
        3)
            list_backups
            ;;
        4)
            clean_backups
            ;;
        0)
            return
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to create manual backup
create_manual_backup() {
    local backup_dir="manual_backup_$(date +%Y%m%d_%H%M%S)"
    print_info "Creating backup: $backup_dir"
    
    mkdir -p "$backup_dir"
    
    for item in *; do
        if [[ "$item" != *backup* ]] && [[ "$item" != "$backup_dir" ]]; then
            cp -r "$item" "$backup_dir/" 2>/dev/null || true
        fi
    done
    
    print_success "Backup created: $backup_dir"
}

# Function to list backups
list_backups() {
    print_info "Available backups:"
    echo ""
    
    local backup_count=0
    for dir in *backup*; do
        if [ -d "$dir" ]; then
            local size=$(du -sh "$dir" 2>/dev/null | cut -f1 || echo "unknown")
            printf "${GRAY}  %-40s %s${NC}\n" "$dir" "$size"
            ((backup_count++))
        fi
    done
    
    if [ $backup_count -eq 0 ]; then
        print_info "No backups found"
    else
        print_info "Total backups: $backup_count"
    fi
}

# Function to clean old backups
clean_backups() {
    print_info "Finding old backups..."
    
    local old_backups=($(ls -dt *backup* 2>/dev/null | tail -n +6))
    
    if [ ${#old_backups[@]} -eq 0 ]; then
        print_info "No old backups to clean"
        return
    fi
    
    print_info "Old backups found: ${#old_backups[@]}"
    for backup in "${old_backups[@]}"; do
        echo "  $backup"
    done
    
    echo ""
    read -p "Delete these backups? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for backup in "${old_backups[@]}"; do
            rm -rf "$backup"
            print_info "Deleted: $backup"
        done
        print_success "Cleanup complete"
    else
        print_info "Cleanup cancelled"
    fi
}

# Function to show tools menu
tools_menu() {
    clear
    print_header "🔧 Development Tools"
    echo ""
    
    print_option "1" "health-check" "Full health check"
    print_option "2" "monitor" "Continuous monitoring"
    print_option "3" "database" "Database tools"
    print_option "4" "scripts" "Manage scripts"
    print_option "5" "cleanup" "Clean temporary files"
    print_option "0" "back" "Back to main menu"
    
    echo ""
    read -p "Select option: " choice
    
    case $choice in
        1)
            if check_script "health_check.sh"; then
                ./health_check.sh full
            else
                print_error "health_check.sh not found"
            fi
            ;;
        2)
            if check_script "health_check.sh"; then
                ./health_check.sh monitor
            else
                print_error "health_check.sh not found"
            fi
            ;;
        3)
            database_tools
            ;;
        4)
            script_manager
            ;;
        5)
            cleanup_temp_files
            ;;
        0)
            return
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function for database tools
database_tools() {
    print_info "Database Tools"
    echo ""
    
    if [ -d "backend" ] && [ -f "backend/prisma/schema.prisma" ]; then
        print_option "1" "studio" "Open Prisma Studio"
        print_option "2" "push" "Push schema to database"
        print_option "3" "generate" "Generate Prisma client"
        print_option "4" "migrate" "Create migration"
        
        echo ""
        read -p "Select option: " db_choice
        
        cd backend
        case $db_choice in
            1) npx prisma studio ;;
            2) npx prisma db push ;;
            3) npx prisma generate ;;
            4) npx prisma migrate dev ;;
        esac
        cd ..
    else
        print_error "Prisma not found in backend directory"
    fi
}

# Function to manage scripts
script_manager() {
    print_info "Script Manager"
    echo ""
    
    # Check and make scripts executable
    for script in *.sh; do
        if [ -f "$script" ]; then
            ensure_executable "$script"
        fi
    done
    
    # List available scripts
    print_info "Available scripts:"
    for script in *.sh; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                print_success "$script (executable)"
            else
                print_error "$script (not executable)"
            fi
        fi
    done
}

# Function to cleanup temporary files
cleanup_temp_files() {
    print_info "Cleaning temporary files..."
    
    # Clean npm cache
    if [ -d "backend/node_modules" ]; then
        print_info "Found backend node_modules"
    fi
    
    if [ -d "frontend/node_modules" ]; then
        print_info "Found frontend node_modules"
    fi
    
    # Clean Docker
    if command -v docker >/dev/null 2>&1; then
        print_info "Cleaning Docker images..."
        docker system prune -f 2>/dev/null || true
    fi
    
    print_success "Cleanup complete"
}

# Main menu function
show_main_menu() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║           🏗️  PROJECT MANAGER 🏗️             ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # Show quick status
    if [ -f "docker-compose.yml" ]; then
        print_success "Project detected"
    else
        print_error "Project not detected"
    fi
    
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        local running=$(docker ps --format '{{.Names}}' | wc -l)
        if [ $running -gt 0 ]; then
            print_success "$running containers running"
        else
            print_info "No containers running"
        fi
    fi
    
    echo ""
    print_header "Main Menu"
    echo ""
    
    print_option "1" "status" "Show project status"
    print_option "2" "deploy" "Deployment options"
    print_option "3" "services" "Manage services"
    print_option "4" "backup" "Backup & restore"
    print_option "5" "tools" "Development tools"
    print_option "6" "update" "Update project"
    print_option "0" "exit" "Exit"
    
    echo ""
}

# Main loop
main() {
    # Initial setup
    create_missing_scripts >/dev/null 2>&1
    
    while true; do
        show_main_menu
        read -p "Select option: " choice
        
        case $choice in
            1)
                show_status
                read -p "Press Enter to continue..."
                ;;
            2)
                run_deployment
                ;;
            3)
                manage_services
                ;;
            4)
                backup_restore
                ;;
            5)
                tools_menu
                ;;
            6)
                if check_script "update_deploy.sh"; then
                    ./update_deploy.sh
                else
                    print_error "update_deploy.sh not found"
                    read -p "Press Enter to continue..."
                fi
                ;;
            0)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# Run main function
main "$@"