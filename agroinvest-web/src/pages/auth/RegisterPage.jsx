import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuthStore } from '../../store/auth.store';
import { sendOtp, verifyOtp } from '../../api/auth.api';
import OTPInput from '../../components/auth/OTPInput';

const RegisterPage = () => {
  const [step, setStep] = useState(1); // 1: Phone, 2: OTP, 3: Profile Details
  const [phoneNumber, setPhoneNumber] = useState('+998');
  const [otpCode, setOtpCode] = useState('');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('INVESTOR'); // default

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const { register } = useAuthStore();
  const navigate = useNavigate();

  const handlePhoneChange = (e) => {
    let value = e.target.value;
    if (!value.startsWith('+998')) {
      value = '+998';
    }
    if (value.length <= 13) {
      setPhoneNumber(value);
    }
  };

  const handleSendOtp = async (e) => {
    e.preventDefault();
    setError(null);
    if (phoneNumber.length !== 13) {
      setError("Telefon raqami noto'g'ri formatda (+998XXXXXXXXX)");
      return;
    }

    setLoading(true);
    try {
      await sendOtp(phoneNumber, 'REGISTER');
      setStep(2);
    } catch (err) {
      setError(err.error?.message || 'OTP yuborishda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async (code) => {
    setError(null);
    setLoading(true);
    try {
      await verifyOtp(phoneNumber, 'REGISTER', code);
      setStep(3);
    } catch (err) {
      setError(err.error?.message || 'OTP kod xato yoki muddati tugagan');
    } finally {
      setLoading(false);
    }
  };

  const handleRegisterSubmit = async (e) => {
    e.preventDefault();
    setError(null);

    if (!fullName || !password) {
      setError("Ism va parol maydonlari to'ldirilishi shart");
      return;
    }

    setLoading(true);
    try {
      const user = await register(fullName, phoneNumber, email, password, role);
      if (user.role === 'FARMER') {
        navigate('/farmer/dashboard');
      } else {
        navigate('/projects');
      }
    } catch (err) {
      setError(err.error?.message || 'Ro\'yxatdan o\'tishda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-green-100 dark:from-slate-900 dark:to-slate-800 p-4">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-xl border border-gray-100 p-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-extrabold text-green-700 tracking-tight">Ro'yxatdan o'tish</h1>
          <p className="text-gray-500 mt-2">
            {step === 1 && "Telefon raqamingizni kiriting"}
            {step === 2 && "Telefoningizga kelgan OTP kodini kiriting"}
            {step === 3 && "Shaxsiy profilingiz tafsilotlarini kiriting"}
          </p>
        </div>

        {error && (
          <div className="mb-6 p-4 bg-red-50 border-l-4 border-red-500 rounded-lg text-red-700 text-sm">
            {error}
          </div>
        )}

        {step === 1 && (
          <form onSubmit={handleSendOtp} className="space-y-6">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Telefon raqam
              </label>
              <input
                type="text"
                value={phoneNumber}
                onChange={handlePhoneChange}
                placeholder="+998901234567"
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
                required
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 bg-green-600 hover:bg-green-700 disabled:bg-green-400 text-white font-semibold rounded-xl shadow-lg shadow-green-600/20 transition duration-200"
            >
              {loading ? 'Yuborilmoqda...' : "Kodni yuborish"}
            </button>
          </form>
        )}

        {step === 2 && (
          <div className="space-y-6">
            <OTPInput onComplete={handleVerifyOtp} />
            <div className="text-center">
              <button
                onClick={() => setStep(1)}
                className="text-sm text-green-600 hover:text-green-700 font-semibold"
              >
                Telefon raqamni tahrirlash
              </button>
            </div>
            {loading && <p className="text-center text-sm text-gray-500">Tekshirilmoqda...</p>}
          </div>
        )}

        {step === 3 && (
          <form onSubmit={handleRegisterSubmit} className="space-y-6">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                To'liq ism (F.I.SH)
              </label>
              <input
                type="text"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                placeholder="Jasurbek Eshmatov"
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Email manzil (ixtiyoriy)
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="example@mail.com"
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
              />
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Parol
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Kamida 6 ta belgi"
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Tizimdagi rolingiz
              </label>
              <div className="grid grid-cols-2 gap-4">
                <button
                  type="button"
                  onClick={() => setRole('INVESTOR')}
                  className={`py-3 border-2 rounded-xl font-semibold transition ${
                    role === 'INVESTOR'
                      ? 'border-green-600 bg-green-50 text-green-700'
                      : 'border-gray-200 text-gray-500 hover:border-gray-300'
                  }`}
                >
                  Investor
                </button>
                <button
                  type="button"
                  onClick={() => setRole('FARMER')}
                  className={`py-3 border-2 rounded-xl font-semibold transition ${
                    role === 'FARMER'
                      ? 'border-green-600 bg-green-50 text-green-700'
                      : 'border-gray-200 text-gray-500 hover:border-gray-300'
                  }`}
                >
                  Fermer
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 bg-green-600 hover:bg-green-700 disabled:bg-green-400 text-white font-semibold rounded-xl shadow-lg shadow-green-600/20 transition duration-200"
            >
              {loading ? 'Yuklanmoqda...' : "Ro'yxatdan o'tish"}
            </button>
          </form>
        )}

        <div className="mt-8 text-center text-sm text-gray-600">
          Hisobingiz bormi?{' '}
          <Link to="/login" className="font-bold text-green-600 hover:text-green-700 hover:underline">
            Kirish
          </Link>
        </div>
      </div>
    </div>
  );
};

export default RegisterPage;
