# Issues to fix:

## 1. WRONG DOCKERFILE.FRONTEND (Document 19 is placeholder)
# Correct version is in document 39, should be:
FROM node:18-alpine
WORKDIR /app
COPY frontend/package*.json ./
RUN npm install
COPY frontend .
EXPOSE 3000
CMD ["npm", "start"]

## 2. MISSING TYPESCRIPT CONFIG FILES
# Need: backend/tsconfig.json
{
  "compilerOptions": {
    "target": "es2020",
    "module": "commonjs",
    "lib": ["es2020"],
    "outDir": "./dist",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}

## 3. WRONG FILE LOCATIONS
# These files are in wrong paths based on document names:
- Document 25: "backend/src/admin_routes.ts" should be "backend/src/routes/admin.routes.ts"
- Document 27: "backend/src/audit/audit_utils.ts" should be "backend/src/utils/audit.ts"
- Document 42: "frontend/services/api.ts" should be "frontend/src/services/api.ts"
- Document 47: "frontend/src/components/frontend_admin_dashboard.ts" should be "frontend/src/components/AdminDashboard.tsx"
- Document 49: "frontend/src/types/frontend_types.ts" should be "frontend/src/types/index.ts"

## 4. PLACEHOLDER FILES THAT NEED REAL CONTENT
# Document 44: AdminDashboard.tsx is just "// AdminDashboard component placeholder"
# Should use content from document 47 (frontend_admin_dashboard.ts)

## 5. MISSING BACKEND .ENV FILE WITH CORRECT NAME
# Document 20 has wrong filename: "backend_env.ev" should be "backend/.env"
# Document 21 has wrong filename: "neon_env_config.env" should be "backend/.env"

## 6. INCOMPLETE SCRIPT FILES
# Document 50: "scripts/deploy.sh" is just "echo 'Deploying with Docker Compose...'"
# Should use content from document 51 (deploy_script.sh)
# Document 52: "scripts/install_admin_route.sh" is just "echo 'Installing admin route...'"
# Should use content from document 53 (install_admin_script.sh)
# Document 56: "scripts/push_prisma_to_neon.sh" is just "echo 'Pushing Prisma schema to Neon...'"
# Should use content from document 55 (prisma_script.sh)

## 7. MISSING FRONTEND FILES
# Need frontend/src/types/index.ts (use content from document 49)
# Need frontend/src/services/api.ts (use content from document 42)