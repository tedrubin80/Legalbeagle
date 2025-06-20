export interface User {
  id: number;
  email: string;
  role: 'ADMIN' | 'SUPER_ADMIN';
  isActive?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface AuthResponse {
  message: string;
  token: string;
  user: User;
}

export interface AccessLog {
  id: number;
  action: string;
  resource?: string;
  email?: string;
  timestamp: string;
  success: boolean;
  ipAddress?: string;
  userAgent?: string;
  metadata?: any;
}

export interface DashboardStats {
  totalUsers: number;
  activeUsers: number;
  totalLogs: number;
  loginAttempts: number;
  successfulLogins: number;
}

export interface DashboardData {
  stats: DashboardStats;
  recentActivity: AccessLog[];
}

export interface LogsResponse {
  logs: AccessLog[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

export interface UsersResponse {
  users: User[];
}

export interface ApiError {
  message: string;
  status?: number;
}