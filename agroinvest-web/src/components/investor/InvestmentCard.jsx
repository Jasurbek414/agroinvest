import React from 'react';
import { TrendingUp, Calendar, Star, User } from 'lucide-react';
import Badge from '../ui/Badge';
import { formatAmount, formatDate } from '../../utils/format';

// TZ rule: a CONFIRMED investment can be self-cancelled within 24 hours.
const isCancellable = (createdAtStr) => {
  const hours = (new Date() - new Date(createdAtStr)) / (1000 * 60 * 60);
  return hours < 24;
};

// One row of the investor's holdings list with its status-dependent actions
// (farmer profile/contract, 24h cancel window, post-payout review).
const InvestmentCard = ({ investment: inv, reviewed, onFarmerProfile, onCancel, onReview }) => (
  <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl border border-gray-150/60 dark:border-slate-800/80 shadow-sm flex flex-col md:flex-row md:items-center md:justify-between gap-4 hover:shadow-md hover:border-gray-200 dark:hover:border-slate-750 transition duration-200">
    <div className="flex items-center gap-4">
      <div className="w-10 h-10 rounded-xl bg-primary-50 dark:bg-primary-950/40 text-primary-600 dark:text-primary-400 flex items-center justify-center shrink-0 shadow-sm border border-primary-100/10">
        <TrendingUp size={18} />
      </div>
      <div>
        <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-sm md:text-base leading-tight">
          {inv.projectTitle}
        </h3>
        <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] text-gray-400 dark:text-slate-555 mt-1 font-bold">
          <span className="flex items-center gap-1"><Calendar size={11} />{formatDate(inv.createdAt)}</span>
          <span className="text-gray-200 dark:text-slate-800">•</span>
          <span>Ulush: <strong className="text-primary-600 dark:text-primary-400 font-black">{inv.sharePct.toFixed(2)}%</strong></span>
        </div>
      </div>
    </div>

    <div className="flex items-center justify-between md:justify-end gap-6 border-t md:border-t-0 pt-3 md:pt-0 border-gray-100 dark:border-slate-800/60">
      <div className="text-left md:text-right">
        <span className="text-[10px] text-gray-400 dark:text-slate-555 font-bold uppercase tracking-wider block">Kiritilgan sarmoya</span>
        <p className="font-black text-sm md:text-base text-gray-950 dark:text-slate-100 mt-0.5">{formatAmount(inv.amount)}</p>
      </div>

      <div className="flex items-center gap-3">
        <Badge status={inv.status} />

        {(inv.status === 'CONFIRMED' || inv.status === 'PAID_OUT') && (
          <button
            onClick={() => onFarmerProfile(inv)}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-primary-50 dark:bg-primary-950/20 hover:bg-primary-100 dark:hover:bg-primary-950/40 border border-primary-250/20 dark:border-primary-900/30 text-primary-700 dark:text-primary-400 text-xs font-bold rounded-xl transition duration-200"
          >
            <User size={13} />
            <span>Fermer & Shartnoma</span>
          </button>
        )}

        {inv.status === 'CONFIRMED' && isCancellable(inv.createdAt) && (
          <button
            onClick={() => onCancel(inv.id)}
            className="px-3.5 py-2 bg-rose-50 dark:bg-rose-950/20 hover:bg-rose-100 dark:hover:bg-rose-950/40 border border-rose-250/20 dark:border-rose-900/30 text-rose-700 dark:text-rose-400 text-xs font-bold rounded-xl transition duration-200"
          >
            Bekor qilish
          </button>
        )}

        {inv.status === 'PAID_OUT' && !reviewed && (
          <button
            onClick={() => onReview(inv)}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 bg-amber-50 dark:bg-amber-950/20 hover:bg-amber-100 dark:hover:bg-amber-950/40 border border-amber-250/20 dark:border-amber-900/30 text-amber-800 dark:text-amber-400 text-xs font-bold rounded-xl transition duration-200"
          >
            <Star size={13} className="fill-current" />
            <span>Fikr qoldirish</span>
          </button>
        )}
      </div>
    </div>
  </div>
);

export default InvestmentCard;
