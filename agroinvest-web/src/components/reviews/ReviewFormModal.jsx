import React, { useState } from 'react';
import { Star } from 'lucide-react';
import { createReview } from '../../api/reviews.api';
import { useToast } from '../ui/ToastProvider';

// Investor rates the farmer after a PAID_OUT investment (TZ F-9.2). Backend
// enforces: own investment only, PAID_OUT status only, one review per investment.
const ReviewFormModal = ({ investment, onClose, onSubmitted }) => {
  const [rating, setRating] = useState(5);
  const [hoverRating, setHoverRating] = useState(0);
  const [comment, setComment] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const { showToast } = useToast();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await createReview(investment.id, rating, comment.trim() || null);
      showToast('Sharhingiz uchun rahmat!');
      onSubmitted?.();
    } catch (err) {
      showToast(err.error?.message || 'Sharh yuborishda xatolik yuz berdi', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-6">
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-xl max-w-sm w-full p-6 space-y-4">
        <div className="flex justify-between items-center">
          <h3 className="font-bold text-gray-900 dark:text-slate-100 text-lg">Fermerga sharh qoldirish</h3>
          <button onClick={onClose} aria-label="Yopish" className="text-gray-400 hover:text-gray-600 dark:text-slate-500 dark:hover:text-slate-300 text-lg">&times;</button>
        </div>
        <p className="text-xs text-gray-500 dark:text-slate-400">{investment.projectTitle}</p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-2">Baho</label>
            <div className="flex gap-1" onMouseLeave={() => setHoverRating(0)}>
              {[1, 2, 3, 4, 5].map((n) => (
                <button
                  key={n}
                  type="button"
                  onClick={() => setRating(n)}
                  onMouseEnter={() => setHoverRating(n)}
                  aria-label={`${n} yulduz`}
                >
                  <Star
                    size={28}
                    className={n <= (hoverRating || rating) ? 'text-amber-500 fill-amber-500' : 'text-gray-200 dark:text-slate-600 fill-gray-200 dark:fill-slate-600'}
                  />
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Izoh (ixtiyoriy)</label>
            <textarea
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              rows="3"
              placeholder="Fermer bilan hamkorlik tajribangiz haqida"
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
            />
          </div>

          <button
            type="submit"
            disabled={submitting}
            className="w-full py-2.5 bg-primary-600 hover:bg-primary-700 disabled:opacity-40 text-white font-bold rounded-xl shadow-sm transition"
          >
            {submitting ? 'Yuborilmoqda...' : 'Sharhni yuborish'}
          </button>
        </form>
      </div>
    </div>
  );
};

export default ReviewFormModal;
