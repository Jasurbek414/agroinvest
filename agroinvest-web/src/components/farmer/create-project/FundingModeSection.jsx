import React from 'react';

const FUNDING_MODES = [
  { value: 'INVESTOR_FUNDED', label: 'To\'liq investor puliga', hint: 'Barcha hayvonlar yig\'ilgan mablag\'ga sotib olinadi' },
  { value: 'FARMER_ASSETS', label: 'O\'z hayvonlarim bilan', hint: 'Mavjud hayvonlarni loyihaga qo\'shaman (admin tasdiqlaydi)' },
  { value: 'MIXED', label: 'Aralash', hint: 'Qisman o\'zim, qisman investor mablag\'i' },
];

const FundingModeSection = ({
  fundingMode,
  setFundingMode,
  hasContribution,
  farmerContributionValue,
  setFarmerContributionValue,
  farmerContributionNotes,
  setFarmerContributionNotes,
}) => {
  return (
    <div className="pt-2 border-t border-gray-100 dark:border-slate-700">
      <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-2 mt-4">Moliyalashtirish usuli</label>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-2">
        {FUNDING_MODES.map((m) => (
          <button
            key={m.value}
            type="button"
            onClick={() => setFundingMode(m.value)}
            className={`text-left p-3 rounded-xl border text-xs transition ${
              fundingMode === m.value ? 'border-primary-500 bg-primary-50 dark:bg-primary-950' : 'border-gray-200 dark:border-slate-600 hover:border-gray-300 dark:hover:border-slate-500'
            }`}
          >
            <p className="font-bold text-gray-800 dark:text-slate-200">{m.label}</p>
            <p className="text-gray-500 dark:text-slate-400 mt-0.5">{m.hint}</p>
          </button>
        ))}
      </div>

      {hasContribution && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-3">
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Mening hissam qiymati (so'm)</label>
            <input
              type="number"
              value={farmerContributionValue}
              onChange={(e) => setFarmerContributionValue(e.target.value)}
              placeholder="5000000"
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              required={hasContribution}
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Izoh (necha bosh, qanday holatda)</label>
            <input
              type="text"
              value={farmerContributionNotes}
              onChange={(e) => setFarmerContributionNotes(e.target.value)}
              placeholder="Masalan: 10 ta sog'lom qo'y, 8 oylik"
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
            />
          </div>
        </div>
      )}
    </div>
  );
};

export default FundingModeSection;
