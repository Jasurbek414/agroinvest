import React, { useState } from 'react';
import { createAdminAccount } from '../../api/superadmin.api';
import Card from '../ui/Card';
import { useToast } from '../ui/ToastProvider';

const CreateAdminForm = ({ onCreated }) => {
  const [phone, setPhone] = useState('+998');
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('ADMIN');
  const [submitting, setSubmitting] = useState(false);
  const { showToast } = useToast();

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (phone.length !== 13) {
      showToast("Telefon raqami noto'g'ri formatda", 'error');
      return;
    }

    setSubmitting(true);
    try {
      await createAdminAccount(phone, name, password, role);
      showToast("Ma'muriy hisob muvaffaqiyatli yaratildi");
      setPhone('+998');
      setName('');
      setPassword('');
      onCreated?.();
    } catch (err) {
      showToast(err.error?.message || 'Hisob yaratishda xatolik', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Card>
      <h2 className="text-lg font-bold text-gray-900 mb-4">Yangi xodim qo'shish</h2>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-xs font-semibold text-gray-600 mb-1.5">Ismi (F.I.SH)</label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Admin Ismi"
            className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
            required
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-gray-600 mb-1.5">Telefon</label>
          <input
            type="text"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="+998901234567"
            className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
            required
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-gray-600 mb-1.5">Parol</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••"
            className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
            required
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-gray-600 mb-1.5">Rol</label>
          <select
            value={role}
            onChange={(e) => setRole(e.target.value)}
            className="w-full px-3 py-2 border rounded-xl text-sm outline-none bg-white focus:ring-1 focus:ring-green-500"
          >
            <option value="ADMIN">Admin</option>
            <option value="MODERATOR">Moderator</option>
            <option value="VERIFIER">Verifikator</option>
          </select>
        </div>
        <button
          type="submit"
          disabled={submitting}
          className="w-full py-2.5 bg-green-600 hover:bg-green-700 disabled:bg-green-300 text-white text-sm font-bold rounded-xl shadow-sm transition"
        >
          {submitting ? 'Yuborilmoqda...' : 'Hisobni yaratish'}
        </button>
      </form>
    </Card>
  );
};

export default CreateAdminForm;
