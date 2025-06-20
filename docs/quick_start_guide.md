# Quick Start Guide

## Option 1: Docker (Recommended - Fastest)

```bash
# 1. Make scripts executable
chmod +x scripts/*.sh

# 2. Deploy everything
./scripts/deploy.sh
```

**That's it!** The application will be running at:
- Frontend: http://localhost:3000
- Backend: http://localhost:3001

## Option 2: Local Development

```bash
# 1. Install dependencies
./scripts/install_admin_route.sh

# 2. Update environment variables
# Edit backend/.env with your database URL

# 3. Start services separately
# Terminal 1 (Backend):
cd backend
npm run dev

# Terminal 2 (Frontend):
cd frontend
npm start
```

## Default Login Credentials

- **Email:** admin@example.com
- **Password:** admin123

⚠️ **Change these in production!**

## Features Included

✅ **Authentication**
- JWT-based login/logout
- Protected routes
- Token verification

✅ **Dashboard**
- User statistics
- Login success rates
- Recent activity feed

✅ **Access Logs**
- Complete audit trail
- IP tracking
- Success/failure monitoring

✅ **User Management**
- View all users
- Activate/deactivate accounts
- Role management

✅ **Security**
- Password hashing (bcrypt)
- CORS protection
- Helmet security headers
- Request rate tracking

## Database Schema

The app creates these tables automatically:
- `users` - Admin user accounts
- `access_logs` - Audit trail of all actions

## Production Deployment

1. **Update Environment Variables:**
   ```bash
   # backend/.env
   DATABASE_URL="postgresql://user:pass@prod-host:5432/db"
   JWT_SECRET="super-secure-secret-key"
   NODE_ENV="production"
   ```

2. **Deploy to Cloud:**
   - Use the provided Docker setup
   - Configure reverse proxy (nginx)
   - Set up SSL certificates
   - Use managed PostgreSQL (Neon, AWS RDS, etc.)

## Troubleshooting

**Port already in use:**
```bash
docker-compose down
./scripts/deploy.sh
```

**Database connection issues:**
- Check DATABASE_URL in backend/.env
- Ensure PostgreSQL is running
- For Neon: Use ./scripts/push_prisma_to_neon.sh

**Frontend can't reach backend:**
- Verify REACT_APP_API_URL in frontend
- Check backend is running on port 3001
- Review CORS settings in backend/src/app.ts

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   React     │───▶│   Express   │───▶│ PostgreSQL  │
│  Frontend   │    │   Backend   │    │  Database   │
│  (Port 3000)│    │ (Port 3001) │    │ (Port 5432) │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Next Steps

1. **Customize the UI** - Modify React components
2. **Add Features** - Extend API endpoints
3. **Security Hardening** - Add rate limiting, 2FA
4. **Monitoring** - Add logging, metrics
5. **Backup Strategy** - Database backups