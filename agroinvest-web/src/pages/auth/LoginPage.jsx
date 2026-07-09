import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuthStore } from '../../store/auth.store';
import { useToast } from '../../components/ui/ToastProvider';

const LoginPage = () => {
  const [phoneNumber, setPhoneNumber] = useState('+998');
  const [password, setPassword] = useState('');
  const { login, loading, error, clearError } = useAuthStore();
  const { showToast } = useToast();
  const navigate = useNavigate();

  const handlePhoneChange = (e) => {
    let value = e.target.value;
    if (!value.startsWith('+998')) {
      value = '+998';
    }
    // Limit length to +998 + 9 digits = 13 characters
    if (value.length <= 13) {
      setPhoneNumber(value);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    clearError();

    if (phoneNumber.length !== 13) {
      showToast("Telefon raqami noto'g'ri formatda (+998XXXXXXXXX)", 'error');
      return;
    }

    try {
      const user = await login(phoneNumber, password);
      // Redirect based on user role
      if (user.role === 'SUPERADMIN') {
        navigate('/superadmin/dashboard');
      } else if (user.role === 'ADMIN' || user.role === 'MODERATOR') {
        navigate('/admin/dashboard');
      } else if (user.role === 'FARMER') {
        navigate('/farmer/dashboard');
      } else {
        navigate('/projects');
      }
    } catch (err) {
      // Handled by store
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 to-primary-100 dark:from-slate-900 dark:to-slate-800 p-4">
      <div className="w-full max-w-md bg-white dark:bg-slate-800 rounded-2xl shadow-xl border border-gray-100 dark:border-slate-700 p-8">
        <div className="text-center mb-8">
          <Link to="/" className="text-3xl font-extrabold text-primary-700 dark:text-primary-400 tracking-tight">AgroInvest</Link>
          <p className="text-gray-500 dark:text-slate-400 mt-2">Tizimga kirish uchun ma'lumotlarni kiriting</p>
        </div>

        {error && (
          <div className="mb-6 p-4 bg-red-50 dark:bg-red-950 border-l-4 border-red-500 rounded-lg text-red-700 dark:text-red-300 text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-semibold text-gray-700 dark:text-slate-300 mb-2">
              Telefon raqam
            </label>
            <input
              type="text"
              value={phoneNumber}
              onChange={handlePhoneChange}
              placeholder="+998901234567"
              className="w-full px-4 py-3 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-700 dark:text-slate-300 mb-2">
              Parol
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full px-4 py-3 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-primary-600 hover:bg-primary-700 disabled:bg-primary-400 text-white font-semibold rounded-xl shadow-lg shadow-primary-600/20 hover:shadow-primary-700/30 transition duration-200"
          >
            {loading ? 'Kirilmoqda...' : 'Kirish'}
          </button>
        </form>

        <div className="mt-8 text-center text-sm text-gray-600 dark:text-slate-400">
          Hisobingiz yo'qmi?{' '}
          <Link to="/register" className="font-bold text-primary-600 dark:text-primary-400 hover:text-primary-700 hover:underline">
            Ro'yxatdan o'tish
          </Link>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
