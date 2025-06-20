#!/bin/bash

echo "📤 Pushing Prisma schema to Neon database..."
echo "🔗 Target: ep-fancy-tooth-a5z610oe-pooler.us-east-2.aws.neon.tech"

# Check if we're in the backend directory or project root
if [ -f "backend/package.json" ]; then
    cd backend
elif [ ! -f "package.json" ]; then
    echo "❌ Error: Not in a valid Node.js project directory"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found. Creating one with Neon database URL..."
    cat > .env << EOF
DATABASE_URL="postgresql://neondb_owner:npg_VWySqE6HnUm9@ep-fancy-tooth-a5z610oe-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require"
JWT_SECRET="neon-admin-app-secret-key"
NODE_ENV="development"
EOF
    echo "✅ Created .env file with Neon database configuration"
fi

# Validate Neon connection
DATABASE_URL=$(grep "DATABASE_URL" .env | cut -d '=' -f2 | tr -d '"')
if [[ $DATABASE_URL == *"ep-fancy-tooth-a5z610oe"* ]]; then
    echo "✅ Using configured Neon database"
else
    echo "⚠️  DATABASE_URL doesn't match expected Neon database"
    echo "Expected: ep-fancy-tooth-a5z610oe-pooler.us-east-2.aws.neon.tech"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "🔍 Checking database connection..."

# Test database connection
npx prisma db pull --force > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Error: Could not connect to database. Please check your DATABASE_URL"
    exit 1
fi

echo "✅ Database connection successful"

echo "📋 Generating Prisma client..."
npx prisma generate

echo "🚀 Pushing schema to database..."
npx prisma db push

if [ $? -eq 0 ]; then
    echo "✅ Schema pushed successfully to Neon database!"
    echo ""
    echo "🎯 Next steps:"
    echo "   1. Check your Neon dashboard to verify the schema"
    echo "   2. Run 'npx prisma studio' to view your data"
    echo "   3. Deploy your application"
else
    echo "❌ Failed to push schema to database"
    exit 1
fi