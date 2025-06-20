import { Request, Response, NextFunction } from 'express';
import { prisma } from '../app';
import { getTokenFromHeader, verifyToken } from './jwt';

export interface AuditLogData {
  userId?: number;
  email?: string;
  action: string;
  resource?: string;
  ipAddress?: string;
  userAgent?: string;
  success?: boolean;
  metadata?: any;
}

export const createAuditLog = async (data: AuditLogData): Promise<void> => {
  try {
    await prisma.accessLog.create({
      data: {
        userId: data.userId,
        email: data.email,
        action: data.action,
        resource: data.resource,
        ipAddress: data.ipAddress,
        userAgent: data.userAgent,
        success: data.success ?? true,
        metadata: data.metadata
      }
    });
  } catch (error) {
    console.error('Failed to create audit log:', error);
  }
};

export const auditLog = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  // Skip health check and options requests
  if (req.path === '/health' || req.method === 'OPTIONS') {
    return next();
  }

  const originalSend = res.send;
  let responseBody: any;

  // Capture response
  res.send = function(body: any) {
    responseBody = body;
    return originalSend.call(this, body);
  };

  // Continue to next middleware
  next();

  // Log after response is sent
  res.on('finish', async () => {
    try {
      let userId: number | undefined;
      let email: string | undefined;

      // Try to extract user info from JWT
      const token = getTokenFromHeader(req.headers.authorization);
      if (token) {
        try {
          const payload = verifyToken(token);
          userId = payload.userId;
          email = payload.email;
        } catch (error) {
          // Token invalid, but still log the attempt
        }
      }

      const auditData: AuditLogData = {
        userId,
        email,
        action: `${req.method} ${req.path}`,
        resource: req.path,
        ipAddress: req.ip || req.connection.remoteAddress,
        userAgent: req.headers['user-agent'],
        success: res.statusCode < 400,
        metadata: {
          statusCode: res.statusCode,
          requestBody: req.method !== 'GET' ? req.body : undefined,
          queryParams: Object.keys(req.query).length > 0 ? req.query : undefined
        }
      };

      await createAuditLog(auditData);
    } catch (error) {
      console.error('Audit logging failed:', error);
    }
  });
};