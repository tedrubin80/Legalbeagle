import { Request, Response, NextFunction } from 'express';
import { getTokenFromHeader, verifyToken, JwtPayload } from '../utils/jwt';
import { prisma } from '../app';

// Extend Request interface to include user
declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload & { isActive: boolean };
    }
  }
}

export const authenticateToken = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const token = getTokenFromHeader(req.headers.authorization);
    
    if (!token) {
      res.status(401).json({ message: 'Access token required' });
      return;
    }

    // Verify token
    const payload = verifyToken(token);
    
    // Check if user still exists and is active
    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
      select: { id: true, email: true, role: true, isActive: true }
    });

    if (!user) {
      res.status(401).json({ message: 'User not found' });
      return;
    }

    if (!user.isActive) {
      res.status(401).json({ message: 'User account is deactivated' });
      return;
    }

    // Add user to request object
    req.user = { ...payload, isActive: user.isActive };
    next();
  } catch (error: any) {
    res.status(401).json({ message: error.message || 'Invalid token' });
  }
};

export const requireRole = (roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    if (!roles.includes(req.user.role)) {
      res.status(403).json({ message: 'Insufficient permissions' });
      return;
    }

    next();
  };
};

export const requireAdmin = requireRole(['ADMIN', 'SUPER_ADMIN']);
export const requireSuperAdmin = requireRole(['SUPER_ADMIN']);