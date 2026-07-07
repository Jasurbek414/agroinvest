import React from 'react';

const TREND_CLASSES = {
  up: 'text-green-600 dark:text-green-400',
  down: 'text-red-600 dark:text-red-400',
};

// Generalizes the inline "white card + label + big number" block that AdminStatsBar
// and WalletPage each hand-rolled separately.
const StatCard = ({ label, value, icon: Icon, trend, trendLabel, className = '' }) => (
  <div className={`bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm p-5 ${className}`}>
    <div className="flex items-center justify-between mb-2">
      <span className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase tracking-wide">{label}</span>
      {Icon && (
        <span className="w-9 h-9 rounded-xl bg-primary-50 dark:bg-primary-950 text-primary-600 dark:text-primary-400 flex items-center justify-center shrink-0">
          <Icon size={18} />
        </span>
      )}
    </div>
    <p className="text-2xl font-black text-gray-900 dark:text-slate-100 truncate">{value}</p>
    {trend && trendLabel && (
      <p className={`mt-1 text-xs font-semibold ${TREND_CLASSES[trend] || 'text-gray-400 dark:text-slate-500'}`}>
        {trend === 'up' ? '↑' : trend === 'down' ? '↓' : ''} {trendLabel}
      </p>
    )}
  </div>
);

export default StatCard;
