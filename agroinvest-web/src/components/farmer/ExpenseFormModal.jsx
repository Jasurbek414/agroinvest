import React, { useState } from 'react';
import { submitExpense } from '../../api/expenses.api';
import ImageUploadPicker from '../ui/ImageUploadPicker';
import { useToast } from '../ui/ToastProvider';

const CATEGORIES = [
  { value: 'FEED', label: 'Yem-xashak' },
  { value: 'MEDICINE', label: 'Dori-darmon' },
  { value: 'VET_SERVICE', label: 'Veterinar xizmati' },
  { value: 'TRANSPORT', label: 'Transport' },
  { value: 'LABOR', label: 'Ish haqi' },
  { value: 'EQUIPMENT', label: 'Jihozlar' },
  { value: 'OTHER', label: 'Boshqa' },
];

// expensePolicy: INVESTOR_BUDGET | FARMER_REIMBURSED | MIXED - only MIXED shows
// the payer chooser; otherwise the server derives payerSource from the policy.
const ExpenseFormModal = ({ projectId, expensePolicy, onClose, onSubmitted }) => {
  const [category, setCategory] = useState('FEED');
  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');
  const [expenseDate, setExpenseDate] = useState(new Date().toISOString().slice(0, 10));
  const [payerSource, setPayerSource] = useState('FARMER');
  const [receiptUrls, setReceiptUrls] = useState([]);
  const [submitting, setSubmitting] = useState(false);
  const { showToast } = useToast();
  const isMixed = expensePolicy === 'MIXED';

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!amount || parseFloat(amount) <= 0) {
      showToast("Summani kiriting", 'error');
      return;
    }

    setSubmitting(true);
    try {
      await submitExpense(projectId, {
        category,
        amount: parseFloat(amount),
        description,
        receiptUrls,
        expenseDate,
        payerSource: isMixed ? payerSource : undefined,
      });
      showToast('Harajat yuborildi - admin tasdiqlashini kuting');
      onSubmitted?.();
    } catch (err) {
      showToast(err.error?.message || 'Harajat yuborishda xatolik yuz berdi', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-6">
      <div className="bg-white rounded-2xl border border-gray-100 shadow-xl max-w-md w-full p-6 space-y-4">
        <div className="flex justify-between items-center">
          <h3 className="font-bold text-gray-900 text-lg">Harajat kiritish</h3>
          <button onClick={onClose} aria-label="Yopish" className="text-gray-400 hover:text-gray-600 text-lg">&times;</button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Toifa</label>
            <select
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none bg-white focus:ring-1 focus:ring-green-500"
            >
              {CATEGORIES.map((c) => <option key={c.value} value={c.value}>{c.label}</option>)}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5">Summa (so'm)</label>
              <input
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="500000"
                className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5">Sana</label>
              <input
                type="date"
                value={expenseDate}
                onChange={(e) => setExpenseDate(e.target.value)}
                max={new Date().toISOString().slice(0, 10)}
                className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
                required
              />
            </div>
          </div>

          {isMixed && (
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5">Kim to'ladi?</label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setPayerSource('INVESTOR_BUDGET')}
                  className={`p-2.5 rounded-xl border text-xs font-bold transition ${payerSource === 'INVESTOR_BUDGET' ? 'border-green-500 bg-green-50 text-green-700' : 'border-gray-200 text-gray-600'}`}
                >
                  Loyiha byudjeti
                </button>
                <button
                  type="button"
                  onClick={() => setPayerSource('FARMER')}
                  className={`p-2.5 rounded-xl border text-xs font-bold transition ${payerSource === 'FARMER' ? 'border-green-500 bg-green-50 text-green-700' : 'border-gray-200 text-gray-600'}`}
                >
                  O'zim to'ladim
                </button>
              </div>
            </div>
          )}

          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Izoh (ixtiyoriy)</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Masalan: 2 tonna beda sotib olindi"
              rows="2"
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Chek / hujjat fotosi</label>
            <ImageUploadPicker
              category="expense"
              urls={receiptUrls}
              onChange={setReceiptUrls}
              accept="image/jpeg,image/png,image/webp,application/pdf"
            />
          </div>

          <button
            type="submit"
            disabled={submitting}
            className="w-full py-2.5 bg-green-600 hover:bg-green-700 disabled:bg-green-300 text-white font-bold rounded-xl shadow-sm transition"
          >
            {submitting ? 'Yuborilmoqda...' : 'Yuborish'}
          </button>
        </form>
      </div>
    </div>
  );
};

export default ExpenseFormModal;
