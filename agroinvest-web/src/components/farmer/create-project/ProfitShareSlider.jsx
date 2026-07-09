import React from 'react';

const ProfitShareSlider = ({ investorSharePct, setInvestorSharePct, shareBounds }) => {
  return (
    <div className="pt-2 border-t border-gray-100 dark:border-slate-700">
      <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1 mt-4">
        Sof foyda taqsimoti ({shareBounds.min}%–{shareBounds.max}%)
      </label>
      <p className="text-[11px] text-gray-400 dark:text-slate-500 mb-2">Investorlar jamoasiga qancha ulush taklif qilasiz?</p>
      <div className="flex items-center gap-4">
        <span className="text-xs font-bold text-primary-700 dark:text-primary-400 w-24">Investor {investorSharePct}%</span>
        <input
          type="range"
          min={shareBounds.min}
          max={shareBounds.max}
          value={investorSharePct}
          onChange={(e) => setInvestorSharePct(parseInt(e.target.value))}
          className="flex-1 accent-primary-600"
        />
        <span className="text-xs font-bold text-amber-600 dark:text-amber-400 w-24 text-right">Fermer {100 - investorSharePct}%</span>
      </div>
    </div>
  );
};

export default ProfitShareSlider;
