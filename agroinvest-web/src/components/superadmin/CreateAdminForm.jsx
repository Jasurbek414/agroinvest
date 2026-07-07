import React, { useState } from 'react';
import { createAdminAccount } from '../../api/superadmin.api';
import Button from '../ui/Button';
import Card from '../ui/Card';
import Input from '../ui/Input';
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
    if (password.length < 8) {
      showToast('Parol kamida 8 belgidan iborat bo\'lishi kerak', 'error');
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
      <h2 className="text-lg font-bold text-gray-900 dark:text-slate-100 mb-4">Yangi xodim qo'shish</h2>
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input label="Ismi (F.I.SH)" type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="Admin Ismi" required />
        <Input label="Telefon" type="text" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+998901234567" required />
        <Input label="Parol" type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Kamida 8 belgi" required />
        <div>
          <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Rol</label>
          <select
            value={role}
            onChange={(e) => setRole(e.target.value)}
            className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
          >
            <option value="ADMIN">Admin</option>
            <option value="MODERATOR">Moderator</option>
            <option value="VERIFIER">Verifikator</option>
          </select>
        </div>
        <Button type="submit" disabled={submitting} className="w-full">
          {submitting ? 'Yuborilmoqda...' : 'Hisobni yaratish'}
        </Button>
      </form>
    </Card>
  );
};

export default CreateAdminForm;
