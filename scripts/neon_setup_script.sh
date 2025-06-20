#!/bin/bash

echo "🔗 Setting up application with Neon Database..."

# Neon database URL
NEON_DB_URL="postgresql://neondb_owner:npg_VWySqE6HnUm9@ep-fancy-tooth-a5z610oe-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require"

# Function to check if we're in the correct directory
check_directory() {
    if [ ! -f "docker-compose.yml" ]; then
        echo "❌ Error: Please run this script from the project root directory"
        exit 1
    fi
}

# Function to create backend .env file
setup_backend_env() {
    echo "⚙️  Creating backend environment file..."
    
    cat > backend/.env << EOF
# Neon Database Configuration
DATABASE_URL="$NEON_DB_URL"

# JWT Configuration
JWT_SECRET="neon-admin-app-$(openssl rand -hex 32 2>/dev/null || echo 'fallback-secret-key')"
JWT_EXPIRES_IN="24h"

# Server Configuration
PORT=3000
NODE_ENV="development"

# Frontend URL (for CORS)
FRONTEND_URL="http://localhost:3000"
EOF

    echo "✅ Backend .env file created successfully"
}

# Function to install dependencies
install_dependencies() {
    echo "📦 Installing dependencies..."
    
    # Backend dependencies
    if [ -d "backend" ]; then
        echo "Installing backend dependencies..."
        cd backend
        npm install
        cd ..
        echo "✅ Backend dependencies installed"
    fi
    
    # Frontend dependencies
    if [ -d "frontend" ]; then
        echo "Installing frontend dependencies..."
        cd frontend
        npm install
        cd ..
        echo "✅ Frontend dependencies installed"
    fi
}

# Function to setup Prisma with Neon
setup_prisma_neon() {
    echo "🗄️  Setting up Prisma with Neon database..."
    
    cd backend
    
    # Generate Prisma client
    echo "📋 Generating Prisma client..."
    npx prisma generate
    
    # Push schema to Neon database
    echo "🚀 Pushing schema to Neon database..."
    npx prisma db push
    
    if [ $? -eq 0 ]; then
        echo "✅ Database schema deployed to Neon successfully!"
        
        # Try to create default admin user via Prisma
        echo "👤 Creating default admin user..."
        npx prisma db seed 2>/dev/null || echo "⚠️  Seed script not found, admin user will be created on first server start"
    else
        echo "❌ Failed to deploy schema to Neon database"
        echo "Please check your database connection and try again"
        cd ..
        exit 1
    fi
    
    cd ..
}

# Function to test database connection
test_connection() {
    echo "🔍 Testing Neon database connection..."
    
    cd backend
    
    # Test connection using Prisma
    npx prisma db pull --force > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully connected to Neon database!"
    else
        echo "❌ Failed to connect to Neon database"
        echo "Please verify your database URL and network connection"
        cd ..
        exit 1
    fi
    
    cd ..
}

# Main setup function
main() {
    echo "🚀 Starting Neon database setup..."
    echo "📍 Database: ep-fancy-tooth-a5z610oe-pooler.us-east-2.aws.neon.tech"
    echo ""
    
    check_directory
    setup_backend_env
    install_dependencies
    test_connection
    setup_prisma_neon
    
    echo ""
    echo "🎉 Neon database setup completed successfully!"
    echo ""
    echo "🎯 Next steps:"
    echo "   1. Run: ./scripts/deploy.sh"
    echo "   2. Access your app at: http://localhost:3000"
    echo "   3. Login with: admin@example.com / admin123"
    echo ""
    echo "🗄️  Database info:"
    echo "   • Host: ep-fancy-tooth-a5z610oe-pooler.us-east-2.aws.neon.tech"
    echo "   • Database: neondb"
    echo "   • SSL: Required (automatically configured)"
    echo ""
    echo "🔧 Useful commands:"
    echo "   • View database: npx prisma studio (from backend/)"
    echo "   • Check logs: docker-compose logs -f"
    echo "   • Stop app: docker-compose down"
}

# Run main function
main