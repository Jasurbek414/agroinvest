import React, { useState, useEffect } from 'react';
import { createInvestment } from '../../api/investments.api';

const InvestmentModal = ({ project, onClose, onSuccess }) => {
  const [amount, setAmount] = useState('');
  const [shareEstimate, setShareEstimate] = useState(0);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  const {
    id: projectId,
    title,
    minInvestment,
    maxInvestment,
    targetAmount,
    raisedAmount,
    investorSharePct,
  } = project;

  const remaining = targetAmount - raisedAmount;

  useEffect(() => {
    const numAmt = parseFloat(amount);
    if (!isNaN(numAmt) && numAmt > 0 && targetAmount > 0) {
      const share = (numAmt / targetAmount) * investorSharePct;
      setShareEstimate(share.toFixed(4));
    } else {
      setShareEstimate(0);
    }
  }, [amount, targetAmount, investorSharePct]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(null);

    const numAmt = parseFloat(amount);
    if (isNaN(numAmt)) {
      setError("Investitsiya miqdori kiritilishi shart");
      return;
    }

    if (numAmt < minInvestment) {
      setError(`Minimal investitsiya summasi: ${new Intl.NumberFormat('uz-UZ').format(minInvestment)} UZS`);
      return;
    }

    if (maxInvestment && numAmt > maxInvestment) {
      setError(`Maksimal investitsiya summasi: ${new Intl.NumberFormat('uz-UZ').format(maxInvestment)} UZS`);
      return;
    }

    if (numAmt > remaining) {
      setError(`Loyiha uchun ko'pi bilan ${new Intl.NumberFormat('uz-UZ').format(remaining)} UZS investitsiya kiritish mumkin`);
      return;
    }

    setLoading(true);
    try {
      await createInvestment(projectId, numAmt);
      onSuccess();
    } catch (err) {
      setError(err.error?.message || 'Investitsiya kiritishda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  const formatAmount = (num) => {
    return new Intl.NumberFormat('uz-UZ').format(num) + ' UZS';
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-xl overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div className="p-6 border-b border-gray-100 flex justify-between items-center">
          <h2 className="text-xl font-bold text-gray-900">Ulush sotib olish</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-2xl font-semibold">
            &times;
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          <div>
            <h3 className="text-sm font-semibold text-gray-400 mb-1">Loyiha</h3>
            <p className="text-base font-bold text-gray-900">{title}</p>
          </div>

          <div className="grid grid-cols-2 gap-4 text-sm bg-gray-50 p-4 rounded-xl">
            <div>
              <p className="text-gray-400 text-xs">Min. Investitsiya</p>
              <p className="font-bold text-gray-800">{formatAmount(minInvestment)}</p>
            </div>
            <div>
              <p className="text-gray-400 text-xs">Qolgan mablag'</p>
              <p className="font-bold text-green-700">{formatAmount(remaining)}</p>
            </div>
          </div>

          {error && (
            <div className="p-3 bg-red-50 border-l-4 border-red-500 rounded text-red-700 text-xs font-semibold">
              {error}
            </div>
          )}

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Sarmoya summasi (UZS)
            </label>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="Masalan: 1000000"
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
              required
            />
          </div>

          {shareEstimate > 0 && (
            <div className="p-4 bg-green-50 border border-green-100 rounded-xl">
              <p className="text-xs text-green-800">Sizning taxminiy foydadagi ulushingiz:</p>
              <p className="text-lg font-extrabold text-green-700 mt-1">{shareEstimate}%</p>
            </div>
          )}

          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-3 border border-gray-200 hover:bg-gray-50 text-gray-600 font-semibold rounded-xl transition"
            >
              Bekor qilish
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 py-3 bg-green-600 hover:bg-green-700 disabled:bg-green-400 text-white font-semibold rounded-xl transition"
            >
              {loading ? 'Tasdiqlanmoqda...' : 'Sotib olish'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default InvestmentModal;
