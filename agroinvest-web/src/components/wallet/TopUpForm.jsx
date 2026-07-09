import React, { useState } from 'react';
import { requestDeposit } from '../../api/wallet.api';
import ImageUploadPicker from '../ui/ImageUploadPicker';
import { useToast } from '../ui/ToastProvider';

// Real Payme/Click gateway integration is dormant (no merchant credentials
// configured) - for now, top-ups go through manual admin/superadmin approval:
// the user declares an amount (and optionally attaches a bank-transfer receipt),
// staff verifies it against the "Depozit so'rovlari" queue, and only then is the
// wallet credited. See DepositRequestsTab.jsx for the review side.
const TopUpForm = ({ onRequested }) => {
  const [amount, setAmount] = useState('');
  const [proofUrls, setProofUrls] = useState([]);
  const [submitting, setSubmitting] = useState(false);
  const { showToast } = useToast();

  const handleSubmit = async (e) => {
    e.preventDefault();
    const numAmount = parseFloat(amount);
    if (isNaN(numAmount) || numAmount < 1000) {
      showToast("Minimal to'ldirish summasi 1 000 UZS", 'error');
      return;
    }

    setSubmitting(true);
    try {
      await requestDeposit(numAmount, proofUrls[0] || null);
      showToast("So'rov yuborildi, admin tekshiruvidan so'ng hamyoningizga tushadi");
      setAmount('');
      setProofUrls([]);
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
        <label className="block text-sm text-gray-600 mb-2">To'ldirish summasi (UZS)</label>
        <input
          type="number"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="Masalan: 100000"
          className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
        />
      </div>
      <div>
        <label className="block text-sm text-gray-600 mb-2">To'lov cheki (ixtiyoriy)</label>
        <ImageUploadPicker category="deposit" urls={proofUrls} onChange={setProofUrls} maxImages={1} />
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

export default TopUpForm;
