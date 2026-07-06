import React, { useState } from 'react';
import { requestWithdrawal } from '../../api/wallet.api';
import { useToast } from '../ui/ToastProvider';

const WithdrawalForm = ({ balance, onRequested }) => {
  const [amount, setAmount] = useState('');
  const [bankName, setBankName] = useState('');
  const [cardNumber, setCardNumber] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const { showToast } = useToast();

  const handleSubmit = async (e) => {
    e.preventDefault();
    const numAmount = parseFloat(amount);
    if (isNaN(numAmount) || numAmount < 5000) {
      showToast("Minimal yechish summasi 5 000 UZS", 'error');
      return;
    }
    if (numAmount > (balance || 0)) {
      showToast("Balansingizda yetarli mablag' yo'q", 'error');
      return;
    }
    if (!bankName.trim() || !cardNumber.trim()) {
      showToast("Bank nomi va karta raqamini kiriting", 'error');
      return;
    }

    setSubmitting(true);
    try {
      await requestWithdrawal(numAmount, bankName.trim(), cardNumber.trim());
      showToast("Pul yechish so'rovi yuborildi, admin tekshiruvidan so'ng balansingizdan yechiladi");
      setAmount('');
      setBankName('');
      setCardNumber('');
      onRequested?.();
    } catch (err) {
      showToast(err.error?.message || "So'rov yuborishda xatolik yuz berdi", 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4 max-w-md">
      <div>
        <label className="block text-sm text-gray-600 mb-2">Yechish summasi (UZS)</label>
        <input
          type="number"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="Masalan: 100000"
          className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
        />
      </div>
      <div>
        <label className="block text-sm text-gray-600 mb-2">Bank nomi</label>
        <input
          type="text"
          value={bankName}
          onChange={(e) => setBankName(e.target.value)}
          placeholder="Masalan: Xalq banki"
          className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
        />
      </div>
      <div>
        <label className="block text-sm text-gray-600 mb-2">Karta raqami</label>
        <input
          type="text"
          value={cardNumber}
          onChange={(e) => setCardNumber(e.target.value)}
          placeholder="8600 XXXX XXXX XXXX"
          className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
        />
      </div>
      <button
        type="submit"
        disabled={submitting}
        className="w-full py-3 bg-green-600 hover:bg-green-700 disabled:bg-green-300 text-white font-bold rounded-xl shadow-sm transition"
      >
        {submitting ? 'Yuborilmoqda...' : "So'rov yuborish"}
      </button>
    </form>
  );
};

export default WithdrawalForm;
