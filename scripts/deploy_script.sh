#!/bin/bash

echo "🚀 Starting deployment with Docker Compose..."

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
    echo "❌ Docker Compose not found. Please install Docker Compose."
    exit 1
fi

# Set docker-compose command (handle both v1 and v2)
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

echo "📦 Building and starting containers..."

# Build and start services
$COMPOSE_CMD up --build -d

# Check if services are running
if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
    echo ""
    echo "🌐 Application URLs:"
    echo "   Frontend: http://localhost:3000"
    echo "   Backend API: http://localhost:3001"
    echo "   Database: localhost:5432"
    echo ""
    echo "👤 Default admin credentials:"
    echo "   Email: admin@example.com"
    echo "   Password: admin123"
    echo ""
    echo "📊 View logs with: $COMPOSE_CMD logs -f"
    echo "🛑 Stop services with: $COMPOSE_CMD down"
else
    echo "❌ Deployment failed!"
    exit 1
fi