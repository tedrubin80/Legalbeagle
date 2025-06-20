import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { prisma } from '../app';
import { generateToken } from '../utils/jwt';
import { createAuditLog } from '../utils/audit';

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      await createAuditLog({
        email,
        action: 'LOGIN_ATTEMPT',
        success: false,
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
        metadata: { error: 'Missing credentials' }
      });
      res.status(400).json({ message: 'Email and password are required' });
      return;
    }

    // Find user
    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() }
    });

    if (!user) {
      await createAuditLog({
        email,
        action: 'LOGIN_ATTEMPT',
        success: false,
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
        metadata: { error: 'User not found' }
      });
      res.status(401).json({ message: 'Invalid credentials' });
      return;
    }

    // Check if user is active
    if (!user.isActive) {
      await createAuditLog({
        userId: user.id,
        email,
        action: 'LOGIN_ATTEMPT',
        success: false,
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
        metadata: { error: 'Account deactivated' }
      });
      res.status(401).json({ message: 'Account is deactivated' });
      return;
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      await createAuditLog({
        userId: user.id,
        email,
        action: 'LOGIN_ATTEMPT',
        success: false,
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
        metadata: { error: 'Invalid password' }
      });
      res.status(401).json({ message: 'Invalid credentials' });
      return;
    }

    // Generate JWT token
    const token = generateToken({
      userId: user.id,
      email: user.email,
      role: user.role
    });

    // Log successful login
    await createAuditLog({
      userId: user.id,
      email,
      action: 'LOGIN_SUCCESS',
      success: true,
      ipAddress: req.ip,
      userAgent: req.headers['user-agent']
    });

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const verifyToken = async (req: Request, res: Response): Promise<void> => {
  try {
    // If we reach here, the token is valid (middleware validates it)
    if (!req.user) {
      res.status(401).json({ message: 'Invalid token' });
      return;
    }

    res.json({
      valid: true,
      user: {
        id: req.user.userId,
        email: req.user.email,
        role: req.user.role
      }
    });
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const logout = async (req: Request, res: Response): Promise<void> => {
  try {
    // Log logout
    if (req.user) {
      await createAuditLog({
        userId: req.user.userId,
        email: req.user.email,
        action: 'LOGOUT',
        success: true,
        ipAddress: req.ip,
        userAgent: req.headers['user-agent']
      });
    }

    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};