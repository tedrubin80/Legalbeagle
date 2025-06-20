# 🚀 Neon Database Setup Guide

Your Neon database is ready to use! Here's how to get your application running with your specific Neon database.

## 📊 Your Database Details

- **Host**: `ep-fancy-tooth-a5z610oe-pooler.us-east-2.aws.neon.tech`
- **Database**: `neondb`
- **User**: `neondb_owner`
- **Region**: `us-east-2` (AWS Ohio)
- **SSL**: Required ✅

## 🎯 Quick Setup (Recommended)

### Option 1: Automated Setup Script

```bash
# 1. Make scripts executable
chmod +x scripts/*.sh

# 2. Run the Neon-specific setup
./scripts/setup_neon.sh

# 3. Deploy the application
./scripts/deploy.sh
```

**That's it!** Your app will be running at http://localhost:3000

### Option 2: Manual Setup

```bash
# 1. Create backend environment file
cat > backend/.env << 'EOF'
DATABASE_URL="postgresql://neondb_owner:npg_VWySqE6HnUm9@ep-fancy-tooth-a5z610oe-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require"
JWT_SECRET="your-secure-secret-key"
NODE_ENV="development"
FRONTEND_URL="http://localhost:3000"
EOF

# 2. Install dependencies
cd backend && npm install && cd ..
cd frontend && npm install && cd ..

# 3. Setup database schema
cd backend
npx prisma generate
npx prisma db push
cd ..

# 4. Deploy with Docker
docker-compose up --build
```

## 🔐 Access Your Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:3001/api
- **Login Credentials**:
  - Email: `admin@example.com`
  - Password: `admin123`

## 🗄️ Database Management

### View Your Data
```bash
cd backend
npx prisma studio
```
This opens a web interface to view/edit your Neon database at http://localhost:5555

### Database Schema
Your Neon database will have these tables:
- `users` - Admin user accounts
- `access_logs` - Audit trail of all actions

### Backup Your Database
```bash
# Export data
cd backend
npx prisma db seed --preview-feature

# Or use Neon's built-in backup features in their dashboard
```

## 🔧 Environment Configuration

### Production Settings
For production deployment, update these values in `backend/.env`:

```bash
# Use a strong, unique JWT secret
JWT_SECRET="$(openssl rand -base64 32)"

# Set production mode
NODE_ENV="production"

# Update CORS origin for your domain
FRONTEND_URL="https://yourdomain.com"
```

### Development vs Production

**Development** (current setup):
- Uses your Neon database
- Local Docker containers for app
- Hot reloading enabled

**Production** (when you deploy):
- Same Neon database
- Optimized build
- Environment variables from your hosting provider

## 🚨 Security Notes

### ✅ What's Already Secure:
- SSL/TLS connection to Neon (required)
- Password hashing with bcrypt
- JWT token authentication
- CORS protection
- Audit logging

### 🔒 Additional Security for Production:
1. **Change default admin password** immediately
2. **Use environment variables** for secrets (never commit `.env`)
3. **Enable Neon's IP allowlist** if needed
4. **Set up monitoring** for suspicious activity
5. **Regular database backups**

## 🐛 Troubleshooting

### Connection Issues
```bash
# Test connection manually
cd backend
npx prisma db pull
```

### Database Schema Issues
```bash
# Reset and redeploy schema
cd backend
npx prisma db push --force-reset
```

### Port Conflicts
```bash
# Stop existing containers
docker-compose down

# Check what's using ports
lsof -i :3000
lsof -i :3001
```

### View Logs
```bash
# Application logs
docker-compose logs -f

# Specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
```

## 📈 Monitoring Your Neon Database

1. **Neon Dashboard**: Check your database metrics at https://console.neon.tech
2. **Application Logs**: Monitor the access_logs table for activity
3. **Performance**: Use `npx prisma studio` to inspect data

## 🎯 Next Steps

1. **Customize the UI** - Edit React components in `frontend/src/components/`
2. **Add Features** - Extend API endpoints in `backend/src/routes/`
3. **Deploy to Production** - Use platforms like Vercel, Railway, or DigitalOcean
4. **Scale Database** - Upgrade your Neon plan as needed

## 📞 Support

- **Neon Documentation**: https://neon.tech/docs
- **Application Issues**: Check the logs with `docker-compose logs -f`
- **Database Issues**: Use Neon's console for monitoring and support

---

🎉 **You're all set!** Your admin application is now configured to use your Neon database and ready for development or production deployment.