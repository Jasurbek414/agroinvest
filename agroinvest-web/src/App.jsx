import React, { useEffect, Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from './store/auth.store';
import { useThemeStore } from './store/theme.store';
import { ToastProvider } from './components/ui/ToastProvider';
import AppShell from './components/layout/AppShell';

// Lazy-loaded so each role's dashboard (admin/superadmin/farmer/investor) ships
// as its own chunk instead of one ~800KB bundle every visitor downloads up
// front regardless of which role (or none, for a guest) they are.
const LoginPage = lazy(() => import('./pages/auth/LoginPage'));
const RegisterPage = lazy(() => import('./pages/auth/RegisterPage'));
const LandingPage = lazy(() => import('./pages/public/LandingPage'));
const ProjectsPage = lazy(() => import('./pages/public/ProjectsPage'));
const ProjectDetailPage = lazy(() => import('./pages/public/ProjectDetailPage'));
const MyInvestments = lazy(() => import('./pages/investor/MyInvestments'));
const WalletPage = lazy(() => import('./pages/investor/WalletPage'));
const AdminDashboard = lazy(() => import('./pages/admin/AdminDashboard'));
const SuperAdminDashboard = lazy(() => import('./pages/superadmin/SuperAdminDashboard'));
const FarmerDashboard = lazy(() => import('./pages/farmer/FarmerDashboard'));
const VerifierDashboard = lazy(() => import('./pages/verifier/VerifierDashboard'));
const KycPage = lazy(() => import('./pages/profile/KycPage'));
const DisputesPage = lazy(() => import('./pages/disputes/DisputesPage'));

const RouteFallback = () => (
  <div className="flex items-center justify-center min-h-screen bg-gray-50 dark:bg-slate-900">
    <div className="w-8 h-8 border-2 border-primary-600 border-t-transparent rounded-full animate-spin" />
  </div>
);

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

  // guestFallback lets "/" show the public landing page instead of the generic
  // "bounce anonymous visitors to /login" behavior every other unknown path gets.
  const getDashboardRedirect = (guestFallback = <Navigate to="/login" replace />) => {
    if (!user) return guestFallback;
    if (user.role === 'SUPERADMIN') return <Navigate to="/superadmin/dashboard" replace />;
    if (user.role === 'ADMIN' || user.role === 'MODERATOR') return <Navigate to="/admin/dashboard" replace />;
    if (user.role === 'FARMER') return <Navigate to="/farmer/dashboard" replace />;
    if (user.role === 'VERIFIER') return <Navigate to="/verifier/dashboard" replace />;
    return <Navigate to="/projects" replace />;
  };

  return (
    <Router>
      <Suspense fallback={<RouteFallback />}>
      <Routes>
        {/* Public landing page - anonymous visitors see this; logged-in users
            get redirected straight to their own dashboard */}
        <Route path="/" element={getDashboardRedirect(<Layout><LandingPage /></Layout>)} />

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
            <ProtectedRoute allowedRoles={['ADMIN', 'MODERATOR', 'SUPERADMIN']}>
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
        <Route
          path="/verifier/dashboard"
          element={
            <ProtectedRoute allowedRoles={['VERIFIER']}>
              <Layout><VerifierDashboard /></Layout>
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
      </Suspense>
    </Router>
  );
}

const AppWithProviders = () => (
  <ToastProvider>
    <App />
  </ToastProvider>
);

export default AppWithProviders;
