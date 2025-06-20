# Admin Dashboard Application

A full-stack web application with authentication and admin dashboard functionality.

## Tech Stack

- **Backend**: Node.js, Express, TypeScript, Prisma, PostgreSQL
- **Frontend**: React, TypeScript
- **Database**: PostgreSQL
- **Containerization**: Docker, Docker Compose

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Node.js 18+ (for local development)

### Using Docker (Recommended)

1. Clone the repository
2. Run the application:
   ```bash
   docker-compose up --build
   ```

3. The application will be available at:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:3001

### Local Development

#### Backend Setup
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your database configuration
npx prisma migrate dev
npm run dev
```

#### Frontend Setup
```bash
cd frontend
npm install
npm start
```

## Environment Variables

### Backend (.env)
```
DATABASE_URL="postgresql://postgres:password@localhost:5432/adminapp"
JWT_SECRET="your-super-secret-jwt-key"
NODE_ENV="development"
```

## API Endpoints

- `POST /api/auth/login` - Admin login
- `GET /api/auth/verify` - Verify JWT token
- `GET /api/admin/dashboard` - Get dashboard data (protected)
- `GET /api/admin/logs` - Get access logs (protected)

## Default Admin Credentials

- Email: admin@example.com
- Password: admin123

**⚠️ Important: Change these credentials in production!**

## Scripts

- `scripts/deploy.sh` - Deploy with Docker Compose
- `scripts/push_prisma_to_neon.sh` - Push Prisma schema to Neon DB
- `scripts/install_admin_route.sh` - Install admin routes

## Production Deployment

1. Update environment variables
2. Change default admin credentials
3. Use a proper PostgreSQL instance (not Docker for production)
4. Set up proper SSL/TLS certificates
5. Configure reverse proxy (nginx/Apache)

## Security Notes

- JWT tokens expire in 24 hours
- All admin routes are protected with JWT middleware
- Passwords are hashed with bcrypt
- Access logs are maintained for audit trails
