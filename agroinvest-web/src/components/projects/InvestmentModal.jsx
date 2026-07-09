import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { createInvestment } from '../../api/investments.api';

const InvestmentModal = ({ project, onClose, onSuccess }) => {
  const [amount, setAmount] = useState('');
  const [shareEstimate, setShareEstimate] = useState(0);
  const [disclaimerAccepted, setDisclaimerAccepted] = useState(false);
  const [error, setError] = useState(null);
  const [kycRequired, setKycRequired] = useState(false);
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
    setKycRequired(false);

    if (!disclaimerAccepted) {
      setError("Davom etish uchun daromad kafolatlanmaganligini tasdiqlang");
      return;
    }

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
      if (err.error?.code === 'KYC_REQUIRED') {
        setKycRequired(true);
      } else {
        setError(err.error?.message || 'Investitsiya kiritishda xatolik yuz berdi');
      }
    } finally {
      setLoading(false);
    }
  };

  const formatAmount = (num) => {
    return new Intl.NumberFormat('uz-UZ').format(num) + ' UZS';
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="w-full max-w-md bg-white dark:bg-slate-800 rounded-2xl shadow-xl overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div className="p-6 border-b border-gray-100 dark:border-slate-700 flex justify-between items-center">
          <h2 className="text-xl font-bold text-gray-900 dark:text-slate-100">Ulush sotib olish</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 dark:text-slate-500 dark:hover:text-slate-300 text-2xl font-semibold">
            &times;
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          <div>
            <h3 className="text-sm font-semibold text-gray-400 dark:text-slate-500 mb-1">Loyiha</h3>
            <p className="text-base font-bold text-gray-900 dark:text-slate-100">{title}</p>
          </div>

          <div className="grid grid-cols-2 gap-4 text-sm bg-gray-50 dark:bg-slate-900/60 p-4 rounded-xl">
            <div>
              <p className="text-gray-400 dark:text-slate-500 text-xs">Min. Investitsiya</p>
              <p className="font-bold text-gray-800 dark:text-slate-200">{formatAmount(minInvestment)}</p>
            </div>
            <div>
              <p className="text-gray-400 dark:text-slate-500 text-xs">Qolgan mablag'</p>
              <p className="font-bold text-primary-700 dark:text-primary-400">{formatAmount(remaining)}</p>
            </div>
          </div>

          {kycRequired && (
            <div className="p-3 bg-amber-50 dark:bg-amber-950/40 border-l-4 border-amber-500 rounded text-amber-800 dark:text-amber-300 text-xs font-semibold">
              Sarmoya kiritish uchun avval shaxsingizni tasdiqlang (KYC).{' '}
              <Link to="/profile/kyc" className="underline font-bold">KYC ga o'tish</Link>
            </div>
          )}

          {error && (
            <div className="p-3 bg-red-50 dark:bg-red-950 border-l-4 border-red-500 rounded text-red-700 dark:text-red-300 text-xs font-semibold">
              {error}
            </div>
          )}

          <div>
            <label className="block text-sm font-semibold text-gray-700 dark:text-slate-300 mb-2">
              Sarmoya summasi (UZS)
            </label>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="Masalan: 1000000"
              className="w-full px-4 py-3 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none transition"
              required
            />
          </div>

          {shareEstimate > 0 && (
            <div className="p-4 bg-primary-50 dark:bg-primary-950 border border-primary-100 dark:border-primary-900 rounded-xl">
              <p className="text-xs text-primary-800 dark:text-primary-300">Sizning taxminiy foydadagi ulushingiz:</p>
              <p className="text-lg font-extrabold text-primary-700 dark:text-primary-400 mt-1">{shareEstimate}%</p>
            </div>
          )}

          <label className="flex items-start gap-2.5 text-xs text-gray-600 dark:text-slate-400 leading-relaxed cursor-pointer">
            <input
              type="checkbox"
              checked={disclaimerAccepted}
              onChange={(e) => setDisclaimerAccepted(e.target.checked)}
              className="mt-0.5 rounded border-gray-300 dark:border-slate-600 accent-primary-600"
            />
            Ko'rsatilgan daromad kutilayotgan (taxminiy) ko'rsatkich bo'lib, KAFOLATLANMAGANLIGINI tushunaman va qabul qilaman.
          </label>

          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-3 border border-gray-200 dark:border-slate-600 hover:bg-gray-50 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-300 font-semibold rounded-xl transition"
            >
              Bekor qilish
            </button>
            <button
              type="submit"
              disabled={loading || !disclaimerAccepted}
              className="flex-1 py-3 bg-primary-600 hover:bg-primary-700 disabled:bg-primary-300 text-white font-semibold rounded-xl transition"
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
