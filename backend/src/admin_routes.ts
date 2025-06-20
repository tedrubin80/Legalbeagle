import { Router, Request, Response } from 'express';
import { prisma } from '../app';
import { authenticateToken, requireAdmin } from '../middleware/auth.middleware';

const router = Router();

// Apply authentication to all admin routes
router.use(authenticateToken);
router.use(requireAdmin);

// Dashboard data
router.get('/dashboard', async (req: Request, res: Response): Promise<void> => {
  try {
    // Get dashboard statistics
    const [
      totalUsers,
      activeUsers,
      totalLogs,
      recentLogs
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { isActive: true } }),
      prisma.accessLog.count(),
      prisma.accessLog.findMany({
        take: 10,
        orderBy: { timestamp: 'desc' },
        include: {
          user: {
            select: { email: true }
          }
        }
      })
    ]);

    // Get login attempts in the last 24 hours
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    const loginAttempts = await prisma.accessLog.count({
      where: {
        action: { contains: 'LOGIN' },
        timestamp: { gte: yesterday }
      }
    });

    const successfulLogins = await prisma.accessLog.count({
      where: {
        action: 'LOGIN_SUCCESS',
        timestamp: { gte: yesterday }
      }
    });

    res.json({
      stats: {
        totalUsers,
        activeUsers,
        totalLogs,
        loginAttempts,
        successfulLogins
      },
      recentActivity: recentLogs.map(log => ({
        id: log.id,
        action: log.action,
        email: log.user?.email || log.email,
        timestamp: log.timestamp,
        success: log.success,
        ipAddress: log.ipAddress
      }))
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ message: 'Failed to fetch dashboard data' });
  }
});

// Get access logs with pagination
router.get('/logs', async (req: Request, res: Response): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 50;
    const skip = (page - 1) * limit;

    const [logs, total] = await Promise.all([
      prisma.accessLog.findMany({
        skip,
        take: limit,
        orderBy: { timestamp: 'desc' },
        include: {
          user: {
            select: { email: true }
          }
        }
      }),
      prisma.accessLog.count()
    ]);

    res.json({
      logs: logs.map(log => ({
        id: log.id,
        action: log.action,
        resource: log.resource,
        email: log.user?.email || log.email,
        timestamp: log.timestamp,
        success: log.success,
        ipAddress: log.ipAddress,
        userAgent: log.userAgent,
        metadata: log.metadata
      })),
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Logs error:', error);
    res.status(500).json({ message: 'Failed to fetch access logs' });
  }
});

// Get all users
router.get('/users', async (req: Request, res: Response): Promise<void> => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        role: true,
        isActive: true,
        createdAt: true,
        updatedAt: true
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({ users });
  } catch (error) {
    console.error('Users error:', error);
    res.status(500).json({ message: 'Failed to fetch users' });
  }
});

// Toggle user active status
router.patch('/users/:id/toggle-status', async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = parseInt(req.params.id);
    
    if (isNaN(userId)) {
      res.status(400).json({ message: 'Invalid user ID' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { isActive: !user.isActive },
      select: {
        id: true,
        email: true,
        role: true,
        isActive: true
      }
    });

    res.json({
      message: `User ${updatedUser.isActive ? 'activated' : 'deactivated'} successfully`,
      user: updatedUser
    });
  } catch (error) {
    console.error('Toggle user status error:', error);
    res.status(500).json({ message: 'Failed to update user status' });
  }
});

export default router;