import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from 'react-query';
import { adminApi, authApi, handleApiError } from '../services/api';
import { DashboardData, AccessLog, User } from '../types';

const AdminDashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'overview' | 'logs' | 'users'>('overview');
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const navigate = useNavigate();

  // Queries
  const { data: dashboardData, isLoading: dashboardLoading } = useQuery<DashboardData>(
    'dashboard',
    adminApi.getDashboard,
    { refetchInterval: 30000 }
  );

  const { data: logsData, isLoading: logsLoading } = useQuery(
    'logs',
    () => adminApi.getLogs(1, 100),
    { enabled: activeTab === 'logs' }
  );

  const { data: usersData, isLoading: usersLoading } = useQuery(
    'users',
    adminApi.getUsers,
    { enabled: activeTab === 'users' }
  );

  useEffect(() => {
    // Get current user from localStorage
    const userData = localStorage.getItem('user');
    if (userData) {
      setCurrentUser(JSON.parse(userData));
    }
  }, []);

  const handleLogout = async () => {
    try {
      await authApi.logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      localStorage.removeItem('authToken');
      localStorage.removeItem('user');
      navigate('/login');
    }
  };

  const handleToggleUserStatus = async (userId: number) => {
    try {
      await adminApi.toggleUserStatus(userId);
      // Refresh users data
      window.location.reload();
    } catch (error) {
      const apiError = handleApiError(error);
      alert(`Error: ${apiError.message}`);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  const cardStyle: React.CSSProperties = {
    backgroundColor: 'white',
    padding: '24px',
    borderRadius: '8px',
    boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
    marginBottom: '20px'
  };

  const tabStyle: React.CSSProperties = {
    padding: '12px 24px',
    border: 'none',
    backgroundColor: 'transparent',
    cursor: 'pointer',
    fontSize: '16px',
    fontWeight: '500',
    borderBottom: '2px solid transparent',
    transition: 'all 0.2s'
  };

  const activeTabStyle: React.CSSProperties = {
    ...tabStyle,
    borderBottomColor: '#007bff',
    color: '#007bff'
  };

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f5f5f5' }}>
      {/* Header */}
      <header style={{
        backgroundColor: 'white',
        padding: '16px 24px',
        boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center'
      }}>
        <h1 style={{ fontSize: '24px', fontWeight: 'bold', color: '#333' }}>
          Admin Dashboard
        </h1>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <span style={{ color: '#666' }}>
            Welcome, {currentUser?.email}
          </span>
          <button
            onClick={handleLogout}
            style={{
              padding: '8px 16px',
              backgroundColor: '#dc3545',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer'
            }}
          >
            Logout
          </button>
        </div>
      </header>

      {/* Navigation Tabs */}
      <nav style={{
        backgroundColor: 'white',
        borderBottom: '1px solid #eee',
        display: 'flex'
      }}>
        <button
          style={activeTab === 'overview' ? activeTabStyle : tabStyle}
          onClick={() => setActiveTab('overview')}
        >
          Overview
        </button>
        <button
          style={activeTab === 'logs' ? activeTabStyle : tabStyle}
          onClick={() => setActiveTab('logs')}
        >
          Access Logs
        </button>
        <button
          style={activeTab === 'users' ? activeTabStyle : tabStyle}
          onClick={() => setActiveTab('users')}
        >
          Users
        </button>
      </nav>

      {/* Content */}
      <main style={{ padding: '24px' }}>
        {activeTab === 'overview' && (
          <div>
            {dashboardLoading ? (
              <div>Loading dashboard data...</div>
            ) : dashboardData ? (
              <>
                {/* Stats Cards */}
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
                  gap: '20px',
                  marginBottom: '30px'
                }}>
                  <div style={cardStyle}>
                    <h3 style={{ color: '#666', fontSize: '14px', marginBottom: '8px' }}>
                      Total Users
                    </h3>
                    <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#333' }}>
                      {dashboardData.stats.totalUsers}
                    </p>
                  </div>
                  <div style={cardStyle}>
                    <h3 style={{ color: '#666', fontSize: '14px', marginBottom: '8px' }}>
                      Active Users
                    </h3>
                    <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#28a745' }}>
                      {dashboardData.stats.activeUsers}
                    </p>
                  </div>
                  <div style={cardStyle}>
                    <h3 style={{ color: '#666', fontSize: '14px', marginBottom: '8px' }}>
                      Total Logs
                    </h3>
                    <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#17a2b8' }}>
                      {dashboardData.stats.totalLogs}
                    </p>
                  </div>
                  <div style={cardStyle}>
                    <h3 style={{ color: '#666', fontSize: '14px', marginBottom: '8px' }}>
                      Login Success Rate (24h)
                    </h3>
                    <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#ffc107' }}>
                      {dashboardData.stats.loginAttempts > 0
                        ? Math.round((dashboardData.stats.successfulLogins / dashboardData.stats.loginAttempts) * 100)
                        : 0}%
                    </p>
                  </div>
                </div>

                {/* Recent Activity */}
                <div style={cardStyle}>
                  <h3 style={{ marginBottom: '20px', fontSize: '18px', fontWeight: 'bold' }}>
                    Recent Activity
                  </h3>
                  <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                      <thead>
                        <tr style={{ borderBottom: '1px solid #eee' }}>
                          <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>Action</th>
                          <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>User</th>
                          <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>Time</th>
                          <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {dashboardData.recentActivity.map((log) => (
                          <tr key={log.id} style={{ borderBottom: '1px solid #f5f5f5' }}>
                            <td style={{ padding: '12px' }}>{log.action}</td>
                            <td style={{ padding: '12px' }}>{log.email || 'Unknown'}</td>
                            <td style={{ padding: '12px', fontSize: '14px', color: '#666' }}>
                              {formatDate(log.timestamp)}
                            </td>
                            <td style={{ padding: '12px' }}>
                              <span style={{
                                padding: '4px 8px',
                                borderRadius: '4px',
                                fontSize: '12px',
                                fontWeight: 'bold',
                                backgroundColor: log.success ? '#d4edda' : '#f8d7da',
                                color: log.success ? '#155724' : '#721c24'
                              }}>
                                {log.success ? 'SUCCESS' : 'FAILED'}
                              </span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </>
            ) : (
              <div>Failed to load dashboard data</div>
            )}
          </div>
        )}

        {activeTab === 'logs' && (
          <div style={cardStyle}>
            <h3 style={{ marginBottom: '20px', fontSize: '18px', fontWeight: 'bold' }}>
              Access Logs
            </h3>
            {logsLoading ? (
              <div>Loading logs...</div>
            ) : logsData ? (
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ borderBottom: '1px solid #eee' }}>
                      <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>Action</th>
                      <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>User</th>
                      <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>IP Address</th>
                      <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>Time</th>
                      <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {logsData.logs.map((log) => (
                      <tr key={log.id} style={{ borderBottom: '1px solid #f5f5f5' }}>
                        <td style={{ padding: '12px' }}>{log.action}</td>
                        <td style={{ padding: '12px' }}>{log.email || 'Unknown'}</td>
                        <td style={{ padding: '12px', fontSize: '14px', color: '#666' }}>
                          {log.ipAddress || 'N/A'}
                        </td>
                        <td style={{ padding: '12px', fontSize: '14px', color: '#666' }}>
                          {formatDate(log.timestamp)}
                        </td>
                        <td style={{ padding: '12px' }}>
                          <span style={{
                            padding: '4px 8px',
                            borderRadius: '4px',
                            fontSize: '12px',
                            fontWeight: 'bold',
                            backgroundColor: log.success ? '#d4edda' : '#f8d7da',
                            color: log.success ? '#155724' : '#721c24'
                          }}>
                            {log.success ? 'SUCCESS' : 'FAILED'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div>Failed to load logs</div>
            )}
          </div>
        )}

        {activeTab === 'users' && (
          <div style={cardStyle}>
            <h3 style={{ marginBottom: '20px', fontSize: '18px', fontWeight: 'bold' }}>
              User Management
            </h3>
            {usersLoading ? (
              <div>Loading users...</div>
            ) : usersData ? (
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ borderBottom: '1px solid #eee' }}>
                      <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>Email</th>
                      <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>Role</th>
                      <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>Status</th>
                      <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>Created</th>
                      <th style={{ textAlign: 'left', padding: '12px', color: '#666' }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {usersData.users.map((user) => (
                      <tr key={user.id} style={{ borderBottom: '1px solid #f5f5f5' }}>
                        <td style={{ padding: '12px', fontWeight: '500' }}>{user.email}</td>
                        <td style={{ padding: '12px' }}>
                          <span style={{
                            padding: '4px 8px',
                            borderRadius: '4px',
                            fontSize: '12px',
                            fontWeight: 'bold',
                            backgroundColor: user.role === 'SUPER_ADMIN' ? '#ffc107' : '#007bff',
                            color: 'white'
                          }}>
                            {user.role}
                          </span>
                        </td>
                        <td style={{ padding: '12px' }}>
                          <span style={{
                            padding: '4px 8px',
                            borderRadius: '4px',
                            fontSize: '12px',
                            fontWeight: 'bold',
                            backgroundColor: user.isActive ? '#28a745' : '#dc3545',
                            color: 'white'
                          }}>
                            {user.isActive ? 'ACTIVE' : 'INACTIVE'}
                          </span>
                        </td>
                        <td style={{ padding: '12px', fontSize: '14px', color: '#666' }}>
                          {user.createdAt ? formatDate(user.createdAt) : 'N/A'}
                        </td>
                        <td style={{ padding: '12px' }}>
                          <button
                            onClick={() => handleToggleUserStatus(user.id)}
                            style={{
                              padding: '6px 12px',
                              border: 'none',
                              borderRadius: '4px',
                              fontSize: '12px',
                              fontWeight: '500',
                              cursor: 'pointer',
                              backgroundColor: user.isActive ? '#dc3545' : '#28a745',
                              color: 'white'
                            }}
                          >
                            {user.isActive ? 'Deactivate' : 'Activate'}
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div>Failed to load users</div>
            )}
          </div>
        )}
      </main>
    </div>
  );
};

export default AdminDashboard;