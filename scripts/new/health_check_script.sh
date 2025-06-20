#!/bin/bash

# Health Check and Status Script
# Monitors the status of the deployed application

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m'

# Symbols
CHECK="✓"
CROSS="✗"
WARNING="⚠"
INFO="ℹ"

print_header() {
    echo -e "${BLUE}$1${NC}"
    echo "$(printf '=%.0s' $(seq 1 ${#1}))"
}

print_success() { echo -e "${GREEN}${CHECK}${NC} $1"; }
print_error() { echo -e "${RED}${CROSS}${NC} $1"; }
print_warning() { echo -e "${YELLOW}${WARNING}${NC} $1"; }
print_info() { echo -e "${BLUE}${INFO}${NC} $1"; }
print_gray() { echo -e "${GRAY}$1${NC}"; }

# Function to check if a port is open
check_port() {
    local host="$1"
    local port="$2"
    nc -z "$host" "$port" 2>/dev/null
}

# Function to check HTTP endpoint
check_http() {
    local url="$1"
    local timeout="${2:-5}"
    curl -s -f --max-time "$timeout" "$url" >/dev/null 2>&1
}

# Function to get HTTP response code
get_http_code() {
    local url="$1"
    curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000"
}

# Function to check service health
check_service_health() {
    local service_name="$1"
    local url="$2"
    local expected_code="${3:-200}"
    
    printf "%-20s " "$service_name:"
    
    if ! command -v curl >/dev/null 2>&1; then
        print_warning "curl not available"
        return
    fi
    
    local response_code=$(get_http_code "$url")
    
    if [ "$response_code" = "$expected_code" ]; then
        print_success "Running (HTTP $response_code)"
    elif [ "$response_code" = "000" ]; then
        print_error "Not responding"
    else
        print_warning "Responding (HTTP $response_code)"
    fi
}

# Function to check Docker status
check_docker() {
    print_header "Docker Status"
    
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker not installed"
        return
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon not running"
        return
    fi
    
    print_success "Docker daemon running"
    
    # Check containers
    echo ""
    print_info "Running containers:"
    if [ "$(docker ps --format '{{.Names}}' | wc -l)" -gt 0 ]; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | while IFS= read -r line; do
            print_gray "  $line"
        done
    else
        print_warning "No containers running"
    fi
}

# Function to check application services
check_application() {
    print_header "Application Health"
    
    # Check backend
    check_service_health "Backend API" "http://localhost:3001/health"
    check_service_health "Backend Root" "http://localhost:3001/" "404"
    
    # Check frontend
    check_service_health "Frontend" "http://localhost:3000/"
    
    # Check specific API endpoints
    echo ""
    print_info "API Endpoints:"
    printf "%-20s " "Auth endpoint:"
    local auth_code=$(get_http_code "http://localhost:3001/api/auth/verify")
    if [ "$auth_code" = "401" ]; then
        print_success "Available (HTTP $auth_code - Expected)"
    elif [ "$auth_code" = "000" ]; then
        print_error "Not responding"
    else
        print_warning "Unexpected response (HTTP $auth_code)"
    fi
}

# Function to check database connectivity
check_database() {
    print_header "Database Status"
    
    if [ -f "backend/.env" ]; then
        print_success ".env file found"
        
        # Extract database URL
        local db_url=$(grep "DATABASE_URL" backend/.env | cut -d'=' -f2 | tr -d '"' 2>/dev/null || echo "")
        
        if [ -n "$db_url" ]; then
            if [[ "$db_url" == *"neon.tech"* ]]; then
                print_success "Neon database configured"
            elif [[ "$db_url" == *"localhost"* ]]; then
                print_info "Local database configured"
            else
                print_info "External database configured"
            fi
        else
            print_warning "DATABASE_URL not found in .env"
        fi
    else
        print_error "backend/.env file not found"
    fi
    
    # Check if backend can connect to database (if running)
    if check_http "http://localhost:3001/health"; then
        print_info "Backend health check passed (likely database connected)"
    fi
}

# Function to check project files
check_project_files() {
    print_header "Project Structure"
    
    local essential_files=(
        "docker-compose.yml:Docker Compose config"
        "backend/package.json:Backend package config"
        "frontend/package.json:Frontend package config"
        "backend/prisma/schema.prisma:Database schema"
        "backend/.env:Environment config"
    )
    
    for item in "${essential_files[@]}"; do
        local file=$(echo "$item" | cut -d':' -f1)
        local desc=$(echo "$item" | cut -d':' -f2)
        
        printf "%-30s " "$desc:"
        if [ -f "$file" ]; then
            print_success "Found"
        else
            print_error "Missing"
        fi
    done
    
    # Check scripts
    echo ""
    print_info "Available scripts:"
    if [ -d "scripts" ]; then
        for script in scripts/*.sh; do
            if [ -f "$script" ] && [ -x "$script" ]; then
                print_gray "  $(basename "$script") (executable)"
            elif [ -f "$script" ]; then
                print_gray "  $(basename "$script") (not executable)"
            fi
        done
    else
        print_warning "No scripts directory found"
    fi
}

# Function to show useful commands
show_commands() {
    print_header "Useful Commands"
    
    # Detect docker-compose command
    local compose_cmd="docker-compose"
    if ! command -v docker-compose >/dev/null 2>&1; then
        compose_cmd="docker compose"
    fi
    
    echo "Development:"
    print_gray "  $compose_cmd logs -f                 # View logs"
    print_gray "  $compose_cmd restart backend         # Restart backend"
    print_gray "  $compose_cmd restart frontend        # Restart frontend"
    print_gray "  $compose_cmd down                    # Stop all services"
    print_gray "  $compose_cmd up -d                   # Start all services"
    
    echo ""
    echo "Database:"
    print_gray "  cd backend && npx prisma studio     # Database GUI"
    print_gray "  cd backend && npx prisma db push    # Update database"
    print_gray "  cd backend && npx prisma generate   # Generate client"
    
    echo ""
    echo "Monitoring:"
    print_gray "  docker stats                        # Resource usage"
    print_gray "  $compose_cmd ps                     # Container status"
    print_gray "  ./health_check.sh                   # Run this script"
}

# Function to check for updates
check_for_updates() {
    print_header "Update Information"
    
    if [ -f "update_deploy.sh" ]; then
        print_success "Update script available: ./update_deploy.sh"
    else
        print_info "Download update script from your repository"
    fi
    
    if [ -d "backup_"* ] 2>/dev/null; then
        local backup_count=$(ls -d backup_* 2>/dev/null | wc -l)
        print_info "Available backups: $backup_count"
        print_gray "  Use ./restore_backup.sh to restore"
    else
        print_info "No backups found"
    fi
}

# Function to run all checks
run_all_checks() {
    echo "🏥 Application Health Check"
    echo "==========================="
    echo ""
    
    check_docker
    echo ""
    check_application
    echo ""
    check_database
    echo ""
    check_project_files
    echo ""
    show_commands
    echo ""
    check_for_updates
    
    echo ""
    print_info "Health check completed at $(date)"
}

# Function to run quick check
run_quick_check() {
    echo "⚡ Quick Health Check"
    echo "===================="
    echo ""
    
    # Quick service checks
    check_service_health "Frontend" "http://localhost:3000/"
    check_service_health "Backend" "http://localhost:3001/health"
    
    # Quick Docker check
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        local running_containers=$(docker ps --format '{{.Names}}' | wc -l)
        print_success "Docker: $running_containers containers running"
    else
        print_error "Docker: Not available"
    fi
    
    echo ""
    print_info "Quick check completed"
}

# Function to continuously monitor
monitor_services() {
    echo "📊 Continuous Monitoring (Press Ctrl+C to stop)"
    echo "==============================================="
    echo ""
    
    while true; do
        clear
        echo "🕐 $(date)"
        echo ""
        run_quick_check
        sleep 10
    done
}

# Main function
main() {
    case "${1:-full}" in
        "quick"|"q")
            run_quick_check
            ;;
        "monitor"|"m")
            monitor_services
            ;;
        "docker"|"d")
            check_docker
            ;;
        "app"|"a")
            check_application
            ;;
        "full"|"f"|*)
            run_all_checks
            ;;
    esac
}

# Show usage if help requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Health Check Script"
    echo "==================="
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  full, f     Full health check (default)"
    echo "  quick, q    Quick service check"
    echo "  monitor, m  Continuous monitoring"
    echo "  docker, d   Docker status only"
    echo "  app, a      Application health only"
    echo ""
    echo "Examples:"
    echo "  $0              # Full health check"
    echo "  $0 quick        # Quick check"
    echo "  $0 monitor      # Continuous monitoring"
    exit 0
fi

# Run main function
main "$@"