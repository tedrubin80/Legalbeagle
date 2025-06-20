#!/bin/bash

# Backup Restore Script
# Restores project from the most recent backup created by update_deploy.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to find backup directories
find_backups() {
    ls -dt backup_* 2>/dev/null || true
}

# Function to show available backups
show_backups() {
    local backups=($(find_backups))
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_error "No backup directories found"
        print_status "Backup directories should be named 'backup_YYYYMMDD_HHMMSS'"
        exit 1
    fi
    
    echo "Available backups:"
    echo "=================="
    for i in "${!backups[@]}"; do
        local backup_dir="${backups[$i]}"
        local backup_date=$(echo "$backup_dir" | sed 's/backup_//' | sed 's/_/ /')
        local backup_size=$(du -sh "$backup_dir" 2>/dev/null | cut -f1 || echo "unknown")
        printf "%2d) %s (Size: %s, Date: %s)\n" $((i+1)) "$backup_dir" "$backup_size" "$backup_date"
    done
    echo ""
}

# Function to validate backup directory
validate_backup() {
    local backup_dir="$1"
    
    if [ ! -d "$backup_dir" ]; then
        print_error "Backup directory '$backup_dir' does not exist"
        return 1
    fi
    
    if [ ! "$(ls -A "$backup_dir" 2>/dev/null)" ]; then
        print_error "Backup directory '$backup_dir' is empty"
        return 1
    fi
    
    # Check for essential files
    if [ -f "$backup_dir/docker-compose.yml" ] || [ -d "$backup_dir/backend" ] || [ -d "$backup_dir/frontend" ]; then
        return 0
    else
        print_warning "Backup directory may not contain a complete project"
        return 1
    fi
}

# Function to stop current services
stop_services() {
    if [ -f "docker-compose.yml" ]; then
        print_status "Stopping current services..."
        if command -v docker-compose >/dev/null 2>&1; then
            docker-compose down 2>/dev/null || true
        else
            docker compose down 2>/dev/null || true
        fi
        print_success "Services stopped"
    fi
}

# Function to backup current state before restore
backup_current() {
    if [ "$(ls -A . 2>/dev/null | grep -v backup_)" ]; then
        local current_backup="backup_before_restore_$(date +%Y%m%d_%H%M%S)"
        print_status "Creating backup of current state: $current_backup"
        mkdir -p "$current_backup"
        
        for item in *; do
            if [[ "$item" != backup_* ]]; then
                cp -r "$item" "$current_backup/" 2>/dev/null || true
            fi
        done
        
        print_success "Current state backed up to $current_backup"
    fi
}

# Function to restore from backup
restore_backup() {
    local backup_dir="$1"
    
    print_status "Restoring from backup: $backup_dir"
    
    # Remove current files (except backups)
    print_status "Removing current files..."
    for item in *; do
        if [[ "$item" != backup_* ]]; then
            rm -rf "$item"
        fi
    done
    
    # Restore files from backup
    print_status "Restoring files..."
    cp -r "$backup_dir"/* . 2>/dev/null || true
    cp -r "$backup_dir"/.[!.]* . 2>/dev/null || true
    
    # Make scripts executable
    if [ -d "scripts" ]; then
        chmod +x scripts/*.sh 2>/dev/null || true
    fi
    
    print_success "Files restored successfully"
}

# Function to start services after restore
start_services() {
    if [ -f "docker-compose.yml" ]; then
        print_status "Starting restored services..."
        
        # Set docker-compose command
        COMPOSE_CMD="docker-compose"
        if ! command -v docker-compose >/dev/null 2>&1; then
            COMPOSE_CMD="docker compose"
        fi
        
        $COMPOSE_CMD up --build -d
        
        if [ $? -eq 0 ]; then
            print_success "Services started successfully"
            echo ""
            echo "🌐 Application URLs:"
            echo "   Frontend: http://localhost:3000"
            echo "   Backend API: http://localhost:3001"
            echo ""
            echo "📊 View logs: $COMPOSE_CMD logs -f"
        else
            print_error "Failed to start services"
            print_status "You may need to check the logs and start manually"
        fi
    else
        print_warning "No docker-compose.yml found in backup"
        print_status "You may need to start services manually"
    fi
}

# Main function
main() {
    echo "🔄 Backup Restore Script"
    echo "========================="
    echo ""
    
    # Show available backups
    show_backups
    
    local backups=($(find_backups))
    
    # Get user selection
    if [ ${#backups[@]} -eq 1 ]; then
        local selected_backup="${backups[0]}"
        echo "Only one backup found. Using: $selected_backup"
        echo ""
        read -p "Continue with restore? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Restore cancelled"
            exit 0
        fi
    else
        echo "Enter the number of the backup to restore (1-${#backups[@]}):"
        read -p "Selection: " selection
        
        if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#backups[@]} ]; then
            print_error "Invalid selection"
            exit 1
        fi
        
        local selected_backup="${backups[$((selection-1))]}"
        echo ""
        echo "Selected backup: $selected_backup"
        read -p "Continue with restore? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Restore cancelled"
            exit 0
        fi
    fi
    
    # Validate selected backup
    if ! validate_backup "$selected_backup"; then
        read -p "Backup validation failed. Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Restore cancelled"
            exit 0
        fi
    fi
    
    # Perform restore
    stop_services
    backup_current
    restore_backup "$selected_backup"
    start_services
    
    echo ""
    print_success "🎉 Restore completed successfully!"
    echo ""
    print_status "Restored from: $selected_backup"
    print_status "If you have issues, check the logs: docker-compose logs -f"
}

# Check if running as script
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi