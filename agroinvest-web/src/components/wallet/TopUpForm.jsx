import React, { useState } from 'react';
import { useToast } from '../ui/ToastProvider';

const PAYME_MERCHANT_ID = import.meta.env.VITE_PAYME_MERCHANT_ID;
const CLICK_SERVICE_ID = import.meta.env.VITE_CLICK_SERVICE_ID;
const CLICK_MERCHANT_ID = import.meta.env.VITE_CLICK_MERCHANT_ID;

const TopUpForm = ({ userId }) => {
  const [topUpAmount, setTopUpAmount] = useState('');
  const { showToast } = useToast();

  const handleTopUpSubmit = (e, provider) => {
    e.preventDefault();
    const numAmt = parseFloat(topUpAmount);
    if (isNaN(numAmt) || numAmt <= 0) {
      showToast("To'g'ri to'lov summasini kiriting", 'error');
      return;
    }

    if (provider === 'payme') {
      if (!PAYME_MERCHANT_ID) {
        showToast('Payme integratsiyasi hali sozlanmagan (VITE_PAYME_MERCHANT_ID)', 'error');
        return;
      }
      const amountInTiyin = numAmt * 100;
      const params = `m=${PAYME_MERCHANT_ID};ac.userId=${userId};a=${amountInTiyin}`;
      window.open(`https://checkout.paycom.uz/${btoa(params)}`, '_blank');
    } else if (provider === 'click') {
      if (!CLICK_SERVICE_ID || !CLICK_MERCHANT_ID) {
        showToast('Click integratsiyasi hali sozlanmagan (VITE_CLICK_SERVICE_ID / VITE_CLICK_MERCHANT_ID)', 'error');
        return;
      }
      const url = `https://my.click.uz/services/pay?service_id=${CLICK_SERVICE_ID}&merchant_id=${CLICK_MERCHANT_ID}&amount=${numAmt}&transaction_param=${userId}`;
      window.open(url, '_blank');
    }
  };

  return (
    <form className="space-y-4 max-w-md">
      <div>
        <label className="block text-sm text-gray-600 mb-2">To'ldirish summasi (UZS)</label>
        <input
          type="number"
          value={topUpAmount}
          onChange={(e) => setTopUpAmount(e.target.value)}
          placeholder="Masalan: 100000"
          className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
        />
      </div>
      <div className="flex gap-4">
        <button
          type="button"
          onClick={(e) => handleTopUpSubmit(e, 'payme')}
          className="flex-1 py-3 bg-gradient-to-r from-blue-500 to-cyan-500 hover:from-blue-600 hover:to-cyan-600 text-white font-bold rounded-xl shadow-sm transition"
        >
          Payme orqali
        </button>
        <button
          type="button"
          onClick={(e) => handleTopUpSubmit(e, 'click')}
          className="flex-1 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold rounded-xl shadow-sm transition"
        >
          Click orqali
        </button>
      </div>
    </form>
  );
};

export default TopUpForm;
