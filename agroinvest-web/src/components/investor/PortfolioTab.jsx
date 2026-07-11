import React, { useMemo } from 'react';
import { formatAmount } from '../../utils/format';
import AssetTypeBarChart from '../admin/charts/AssetTypeBarChart';
import MonthlyInvestmentChart from './charts/MonthlyInvestmentChart';

// Portfolio analytics: allocation per project (magnitude - single hue bars,
// never a cycled categorical palette), asset-type breakdown (identity - the
// fixed ASSET_TYPE_META hues via AssetTypeBarChart) and monthly activity.
// Every number here is computed from real API data - no mock placeholders.
const PortfolioTab = ({ investments, portfolio }) => {
  const allocation = useMemo(() => {
    const active = investments.filter((inv) => inv.status !== 'CANCELLED');
    const byProject = new Map();
    active.forEach((inv) => {
      byProject.set(inv.projectTitle, (byProject.get(inv.projectTitle) || 0) + (Number(inv.amount) || 0));
    });
    const total = [...byProject.values()].reduce((a, b) => a + b, 0);
    return {
      total,
      rows: [...byProject.entries()]
        .map(([title, amount]) => ({ title, amount, pct: total > 0 ? (amount / total) * 100 : 0 }))
        .sort((a, b) => b.amount - a.amount),
    };
  }, [investments]);

  const expectedGainPct = portfolio && portfolio.portfolioValue > 0
    ? ((portfolio.expectedPayout - portfolio.portfolioValue) / portfolio.portfolioValue) * 100
    : null;

  const activeCount = investments.filter((i) => i.status === 'CONFIRMED').length;
  const paidOutCount = investments.filter((i) => i.status === 'PAID_OUT').length;

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6 animate-in fade-in duration-300">

      {/* Allocation per project */}
      <div className="md:col-span-2 bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/50 dark:border-slate-800/80 shadow-sm space-y-6">
        <div>
          <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base">Portfel tarkibi (Aktivlar taqsimoti)</h3>
          <p className="text-xs text-gray-450 dark:text-slate-500 mt-0.5">Turli loyihalarga kiritilgan mablag'lar nisbati</p>
        </div>

        {allocation.rows.length === 0 ? (
          <p className="text-xs text-gray-400 py-10 text-center">Ma'lumotlar mavjud emas</p>
        ) : (
          <div className="space-y-3">
            {allocation.rows.map((row) => (
              <div key={row.title} className="space-y-1.5">
                <div className="flex justify-between items-center gap-3 text-xs">
                  <span className="font-bold text-gray-800 dark:text-slate-200 truncate">{row.title}</span>
                  <span className="font-black text-gray-500 dark:text-slate-400 shrink-0">
                    {formatAmount(row.amount)} <span className="text-primary-600 dark:text-primary-400">({row.pct.toFixed(1)}%)</span>
                  </span>
                </div>
                <div className="h-2 w-full rounded-full bg-gray-100 dark:bg-slate-800 overflow-hidden">
                  <div className="bg-primary-600 h-full rounded-full transition-all" style={{ width: `${row.pct}%` }} />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Computed portfolio parameters */}
      <div className="bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/50 dark:border-slate-800/80 shadow-sm space-y-4">
        <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base">Hisob-kitob parametrlari</h3>

        <div className="space-y-3 pt-2 text-xs">
          <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-slate-800/60">
            <span className="text-gray-400 font-bold">Faol sarmoyalar</span>
            <span className="font-black text-gray-900 dark:text-slate-100">{activeCount} ta</span>
          </div>
          <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-slate-800/60">
            <span className="text-gray-400 font-bold">Yakunlangan sarmoyalar</span>
            <span className="font-black text-gray-900 dark:text-slate-100">{paidOutCount} ta</span>
          </div>
          <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-slate-800/60">
            <span className="text-gray-400 font-bold">Kutilayotgan rentabellik</span>
            <span className="font-black text-emerald-600 dark:text-emerald-400">
              {expectedGainPct !== null ? `+${expectedGainPct.toFixed(1)}%` : '—'}
            </span>
          </div>
          <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-slate-800/60">
            <span className="text-gray-400 font-bold">Jami olingan daromad</span>
            <span className="font-black text-gray-900 dark:text-slate-100">{portfolio ? formatAmount(portfolio.totalEarned) : '—'}</span>
          </div>
          <div className="flex justify-between items-center py-2">
            <span className="text-gray-400 font-bold">Hamyondagi erkin mablag'</span>
            <span className="font-black text-primary-600 dark:text-primary-400">{portfolio ? formatAmount(portfolio.walletBalance) : '—'}</span>
          </div>
        </div>
      </div>

      {/* Asset-type identity breakdown (fixed category hues) */}
      <div className="md:col-span-1 bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/50 dark:border-slate-800/80 shadow-sm space-y-4">
        <div>
          <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base">Aktiv turlari bo'yicha</h3>
          <p className="text-xs text-gray-450 dark:text-slate-500 mt-0.5">Faol sarmoyalaringiz soni yo'nalishlar kesimida</p>
        </div>
        <AssetTypeBarChart
          data={portfolio?.assetTypeBreakdown}
          unitLabel="ta sarmoya"
          emptyTitle="Hali faol sarmoyalar yo'q"
        />
      </div>

      {/* Monthly contribution activity */}
      <div className="md:col-span-2 bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/50 dark:border-slate-800/80 shadow-sm space-y-4">
        <div>
          <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base">Oylik sarmoya faolligi</h3>
          <p className="text-xs text-gray-450 dark:text-slate-500 mt-0.5">Oxirgi 6 oyda kiritilgan mablag'lar dinamikasi</p>
        </div>
        <MonthlyInvestmentChart investments={investments} />
      </div>

    </div>
  );
};

export default PortfolioTab;
