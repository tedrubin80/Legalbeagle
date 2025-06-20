#!/bin/bash

echo "🔧 Installing admin route dependencies and setting up..."

# Function to check if we're in the correct directory
check_directory() {
    if [ ! -f "docker-compose.yml" ]; then
        echo "❌ Error: Please run this script from the project root directory"
        exit 1
    fi
}

# Function to install backend dependencies
install_backend_deps() {
    echo "📦 Installing backend dependencies..."
    
    if [ -d "backend" ]; then
        cd backend
        
        if [ ! -f "package.json" ]; then
            echo "❌ Error: backend/package.json not found"
            exit 1
        fi
        
        npm install
        
        if [ $? -eq 0 ]; then
            echo "✅ Backend dependencies installed successfully"
        else
            echo "❌ Failed to install backend dependencies"
            exit 1
        fi
        
        cd ..
    else
        echo "❌ Error: backend directory not found"
        exit 1
    fi
}

# Function to install frontend dependencies
install_frontend_deps() {
    echo "📦 Installing frontend dependencies..."
    
    if [ -d "frontend" ]; then
        cd frontend
        
        if [ ! -f "package.json" ]; then
            echo "❌ Error: frontend/package.json not found"
            exit 1
        fi
        
        npm install
        
        if [ $? -eq 0 ]; then
            echo "✅ Frontend dependencies installed successfully"
        else
            echo "❌ Failed to install frontend dependencies"
            exit 1
        fi
        
        cd ..
    else
        echo "❌ Error: frontend directory not found"
        exit 1
    fi
}

# Function to setup environment files
setup_env_files() {
    echo "⚙️  Setting up environment files..."
    
    # Backend .env
    if [ ! -f "backend/.env" ] && [ -f "backend/.env.example" ]; then
        cp backend/.env.example backend/.env
        echo "✅ Created backend/.env from example"
        echo "⚠️  Please update backend/.env with your actual database credentials"
    fi
}

# Function to generate Prisma client
setup_prisma() {
    echo "🗄️  Setting up Prisma..."
    
    cd backend
    
    if [ -f "prisma/schema.prisma" ]; then
        echo "📋 Generating Prisma client..."
        npx prisma generate
        
        if [ $? -eq 0 ]; then
            echo "✅ Prisma client generated successfully"
        else
            echo "❌ Failed to generate Prisma client"
            cd ..
            exit 1
        fi
    else
        echo "❌ Error: Prisma schema not found"
        cd ..
        exit 1
    fi
    
    cd ..
}

# Main installation process
main() {
    echo "🚀 Starting admin route installation..."
    
    check_directory
    install_backend_deps
    install_frontend_deps
    setup_env_files
    setup_prisma
    
    echo ""
    echo "✅ Admin route installation completed successfully!"
    echo ""
    echo "🎯 Next steps:"
    echo "   1. Update backend/.env with your database URL"
    echo "   2. Run: ./scripts/deploy.sh"
    echo "   3. Access the admin panel at: http://localhost:3000/login"
    echo ""
    echo "👤 Default admin credentials:"
    echo "   Email: admin@example.com"
    echo "   Password: admin123"
    echo ""
    echo "📚 For more information, see README.md"
}

# Run main function
main