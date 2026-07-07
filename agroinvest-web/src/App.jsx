import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/auth/LoginPage';
import RegisterPage from './pages/auth/RegisterPage';
import ProjectsPage from './pages/public/ProjectsPage';
import ProjectDetailPage from './pages/public/ProjectDetailPage';
import MyInvestments from './pages/investor/MyInvestments';
import WalletPage from './pages/investor/WalletPage';
import AdminDashboard from './pages/admin/AdminDashboard';
import SuperAdminDashboard from './pages/superadmin/SuperAdminDashboard';
import FarmerDashboard from './pages/farmer/FarmerDashboard';
import KycPage from './pages/profile/KycPage';
import DisputesPage from './pages/disputes/DisputesPage';
import { useAuthStore } from './store/auth.store';
import { useThemeStore } from './store/theme.store';
import { ToastProvider } from './components/ui/ToastProvider';
import AppShell from './components/layout/AppShell';

const Layout = AppShell;

// Helper component for protecting routes
const ProtectedRoute = ({ children, allowedRoles }) => {
  const { user } = useAuthStore();

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return <Navigate to="/unauthorized" replace />;
  }

  return children;
};

function App() {
  const { user } = useAuthStore();
  const initTheme = useThemeStore((s) => s.initTheme);

  // Runs once for every route (including /login, /register which don't render
  // AppShell) so the dark/light class on <html> is always correct on first paint.
  useEffect(() => {
    initTheme();
  }, [initTheme]);

  const getDashboardRedirect = () => {
    if (!user) return <Navigate to="/login" replace />;
    if (user.role === 'SUPERADMIN') return <Navigate to="/superadmin/dashboard" replace />;
    if (user.role === 'ADMIN' || user.role === 'MODERATOR') return <Navigate to="/admin/dashboard" replace />;
    if (user.role === 'FARMER') return <Navigate to="/farmer/dashboard" replace />;
    return <Navigate to="/projects" replace />;
  };

  return (
    <Router>
      <Routes>
        {/* Public auth pages */}
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />

        {/* Public project viewing (with navbar layout) */}
        <Route path="/projects" element={<Layout><ProjectsPage /></Layout>} />
        <Route path="/projects/:id" element={<Layout><ProjectDetailPage /></Layout>} />

        {/* Investor protected views */}
        <Route
          path="/investor/investments"
          element={
            <ProtectedRoute allowedRoles={['INVESTOR']}>
              <Layout><MyInvestments /></Layout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/investor/wallet"
          element={
            <ProtectedRoute allowedRoles={['INVESTOR']}>
              <Layout><WalletPage /></Layout>
            </ProtectedRoute>
          }
        />

        {/* Role-specific dashboards (Farmer/Admin/SuperAdmin) */}
        <Route
          path="/farmer/dashboard"
          element={
            <ProtectedRoute allowedRoles={['FARMER']}>
              <Layout><FarmerDashboard /></Layout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/dashboard"
          element={
            <ProtectedRoute allowedRoles={['ADMIN', 'MODERATOR']}>
              <Layout><AdminDashboard /></Layout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/superadmin/dashboard"
          element={
            <ProtectedRoute allowedRoles={['SUPERADMIN']}>
              <Layout><SuperAdminDashboard /></Layout>
            </ProtectedRoute>
          }
        />

        {/* Shared authenticated views (any role) */}
        <Route
          path="/profile/kyc"
          element={
            <ProtectedRoute>
              <Layout><KycPage /></Layout>
            </ProtectedRoute>
          }
        />
        <Route
          path="/disputes"
          element={
            <ProtectedRoute>
              <Layout><DisputesPage /></Layout>
            </ProtectedRoute>
          }
        />

        <Route path="/unauthorized" element={<Layout><div className="p-12 text-center text-red-600 font-bold">Ruxsat etilmagan sahifa!</div></Layout>} />
        <Route path="*" element={getDashboardRedirect()} />
      </Routes>
    </Router>
  );
}

const AppWithProviders = () => (
  <ToastProvider>
    <App />
  </ToastProvider>
);

export default AppWithProviders;
