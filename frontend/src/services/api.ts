import axios, { AxiosResponse } from 'axios';
import { AuthResponse, DashboardData, LogsResponse, UsersResponse, ApiError } from '../types';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

// Create axios instance
const api = axios.create({
  baseURL: `${API_BASE_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Clear token and redirect to login
      localStorage.removeItem('authToken');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth API
export const authApi = {
  login: async (email: string, password: string): Promise<AuthResponse> => {
    const response: AxiosResponse<AuthResponse> = await api.post('/auth/login', {
      email,
      password,
    });
    return response.data;
  },

  verifyToken: async () => {
    const response = await api.get('/auth/verify');
    return response.data;
  },

  logout: async () => {
    const response = await api.post('/auth/logout');
    return response.data;
  },
};

// Admin API
export const adminApi = {
  getDashboard: async (): Promise<DashboardData> => {
    const response: AxiosResponse<DashboardData> = await api.get('/admin/dashboard');
    return response.data;
  },

  getLogs: async (page: number = 1, limit: number = 50): Promise<LogsResponse> => {
    const response: AxiosResponse<LogsResponse> = await api.get('/admin/logs', {
      params: { page, limit },
    });
    return response.data;
  },

  getUsers: async (): Promise<UsersResponse> => {
    const response: AxiosResponse<UsersResponse> = await api.get('/admin/users');
    return response.data;
  },

  toggleUserStatus: async (userId: number) => {
    const response = await api.patch(`/admin/users/${userId}/toggle-status`);
    return response.data;
  },
};

// Error handler utility
export const handleApiError = (error: any): ApiError => {
  if (error.response) {
    return {
      message: error.response.data?.message || 'An error occurred',
      status: error.response.status,
    };
  } else if (error.request) {
    return {
      message: 'Network error. Please check your connection.',
    };
  } else {
    return {
      message: error.message || 'An unexpected error occurred',
    };
  }
};

export default api;