import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, Link } from 'react-router-dom';
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
import { ToastProvider } from './components/ui/ToastProvider';
import NotificationBell from './components/notifications/NotificationBell';


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

// Role -> nav links shown between the logo and the account controls. Every role that
// has a dashboard route gets a visible way to reach it - previously only INVESTOR did,
// leaving farmers/admins/superadmins to rely on the post-login redirect alone.
const NAV_LINKS_BY_ROLE = {
  INVESTOR: [
    { to: '/investor/investments', label: 'Sarmoyalarim' },
    { to: '/investor/wallet', label: 'Hamyon' },
    { to: '/disputes', label: 'Shikoyatlar' },
  ],
  FARMER: [
    { to: '/farmer/dashboard', label: 'Fermer paneli' },
    { to: '/disputes', label: 'Shikoyatlar' },
  ],
  ADMIN: [{ to: '/admin/dashboard', label: 'Admin paneli' }],
  MODERATOR: [{ to: '/admin/dashboard', label: 'Admin paneli' }],
  SUPERADMIN: [{ to: '/superadmin/dashboard', label: 'SuperAdmin paneli' }],
};

// Sleek Layout with Navbar
const Layout = ({ children }) => {
  const { user, logout } = useAuthStore();
  const roleLinks = user ? (NAV_LINKS_BY_ROLE[user.role] || []) : [];

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      <nav className="bg-white border-b border-gray-100 sticky top-0 z-40">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-8">
            <Link to="/projects" className="text-xl font-black text-green-700 tracking-tight">
              AgroInvest
            </Link>
            <div className="hidden md:flex items-center gap-6 text-sm font-semibold text-gray-500">
              <Link to="/projects" className="hover:text-green-700 transition">Loyihalar</Link>
              {roleLinks.map((link) => (
                <Link key={link.to} to={link.to} className="hover:text-green-700 transition">{link.label}</Link>
              ))}
              {user && (
                <Link to="/profile/kyc" className="hover:text-green-700 transition">KYC</Link>
              )}
            </div>
          </div>

          <div className="flex items-center gap-4">
            {user ? (
              <div className="flex items-center gap-3">
                <NotificationBell />
                <span className="text-xs bg-gray-100 text-gray-600 px-3 py-1 rounded-full font-bold uppercase">
                  {user.role}
                </span>
                <span className="text-sm font-bold text-gray-700 hidden sm:inline">{user.fullName}</span>
                <button
                  onClick={logout}
                  className="px-4 py-2 bg-red-50 hover:bg-red-100 text-red-600 text-sm font-bold rounded-xl transition"
                >
                  Chiqish
                </button>
              </div>
            ) : (
              <Link
                to="/login"
                className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white text-sm font-bold rounded-xl transition"
              >
                Kirish
              </Link>
            )}
          </div>
        </div>
      </nav>
      <main className="flex-1">{children}</main>
    </div>
  );
};

function App() {
  const { user } = useAuthStore();

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
