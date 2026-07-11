import React from 'react';
import { Link } from 'react-router-dom';
import { Wallet, TrendingUp, PiggyBank, CheckCircle2, ArrowUpRight } from 'lucide-react';
import StatCard from '../ui/StatCard';
import { formatAmount } from '../../utils/format';

// GET /dashboard/me for an INVESTOR: portfolio value, lifetime earnings,
// expected payout estimate and the free wallet balance (with a jump-off to
// the wallet page so top-up/withdraw is one click from the cabinet).
const InvestorStatsBar = ({ portfolio }) => {
  if (!portfolio) return null;

  // Same estimate the backend labels "kutilmoqda": capital + expected profit.
  const expectedGainPct = portfolio.portfolioValue > 0
    ? ((portfolio.expectedPayout - portfolio.portfolioValue) / portfolio.portfolioValue) * 100
    : 0;

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-5">
      <div className="relative overflow-hidden bg-gradient-to-br from-slate-900 via-slate-950 to-emerald-950 text-white p-5 rounded-[24px] border border-emerald-500/10 shadow-md">
        <div className="flex justify-between items-center mb-2">
          <span className="text-[10px] font-bold text-emerald-300 uppercase tracking-widest">Portfel qiymati</span>
          <Wallet className="text-emerald-400" size={16} />
        </div>
        <p className="text-2xl font-black">{formatAmount(portfolio.portfolioValue)}</p>
        <div className="mt-2 text-[10px] text-emerald-200/80 font-bold flex items-center gap-1">
          <CheckCircle2 size={12} className="text-emerald-400" />
          <span>{portfolio.activeInvestments ?? 0} ta faol sarmoya</span>
        </div>
      </div>

      <StatCard label="Jami daromad" value={formatAmount(portfolio.totalEarned)} icon={PiggyBank} />
      <StatCard
        label="Kutilayotgan qaytim"
        value={formatAmount(portfolio.expectedPayout)}
        icon={TrendingUp}
        trend={expectedGainPct > 0 ? 'up' : undefined}
        trendLabel={expectedGainPct > 0 ? `+${expectedGainPct.toFixed(1)}% kutilmoqda` : undefined}
      />

      <Link to="/wallet" className="group">
        <StatCard
          label="Hamyon balansi"
          value={formatAmount(portfolio.walletBalance)}
          icon={ArrowUpRight}
          className="h-full transition duration-200 group-hover:border-primary-300 dark:group-hover:border-primary-800 group-hover:shadow-md"
        />
      </Link>
    </div>
  );
};

export default InvestorStatsBar;
