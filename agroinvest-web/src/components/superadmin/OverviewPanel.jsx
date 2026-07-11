import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Users, Sprout, Briefcase, Ban, TrendingUp, Wallet, Landmark, ArrowLeftRight,
  ShieldCheck, FolderKanban, ClipboardList, Receipt, HeartPulse, Scale, ChevronRight,
} from 'lucide-react';
import { getPlatformOverview } from '../../api/superadmin.api';
import StatCard from '../ui/StatCard';
import ErrorState from '../ui/ErrorState';
import { SkeletonCard } from '../ui/Skeleton';
import { formatAmount } from '../../utils/format';

// Every pending review queue, with a deep link straight into its tab so the
// SuperAdmin can jump from "5 ta kutilmoqda" to the actual work in one click.
const QUEUE_LINKS = [
  { key: 'withdrawals', label: "Yechish so'rovlari", icon: Wallet, tab: 'withdrawals' },
  { key: 'deposits', label: "To'lov so'rovlari", icon: Landmark, tab: 'deposits' },
  { key: 'kyc', label: 'KYC arizalari', icon: ShieldCheck, tab: 'kyc' },
  { key: 'projects', label: 'Loyihalar', icon: FolderKanban, tab: 'projects' },
  { key: 'reports', label: 'Hisobotlar', icon: ClipboardList, tab: 'reports' },
  { key: 'expenses', label: 'Harajatlar', icon: Receipt, tab: 'expenses' },
  { key: 'vetInspections', label: 'Veterinar hujjatlari', icon: HeartPulse, tab: 'vetInspections' },
  { key: 'disputes', label: 'Ochiq nizolar', icon: Scale, tab: 'disputes' },
];

const SectionTitle = ({ children }) => (
  <h2 className="text-sm font-extrabold text-gray-500 dark:text-slate-400 uppercase tracking-wider">{children}</h2>
);

const OverviewPanel = () => {
  const [overview, setOverview] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchOverview = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await getPlatformOverview();
      setOverview(res.data);
    } catch (err) {
      setError("Platforma statistikasini yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchOverview(); }, []);

  if (error) return <ErrorState message={error} onRetry={fetchOverview} />;

  if (loading || !overview) {
    return (
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {Array.from({ length: 8 }).map((_, i) => <SkeletonCard key={i} />)}
      </div>
    );
  }

  const { users = {}, finance = {}, queues = {} } = overview;
  const totalPending = QUEUE_LINKS.reduce((sum, q) => sum + (queues[q.key] || 0), 0);

  return (
    <div className="space-y-8">
      {/* Pending work queues - the first thing a SuperAdmin needs to see */}
      <section className="space-y-3">
        <div className="flex items-center justify-between">
          <SectionTitle>Kutilayotgan ishlar</SectionTitle>
          <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${
            totalPending > 0
              ? 'bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-300'
              : 'bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-300'
          }`}>
            {totalPending > 0 ? `Jami ${totalPending} ta kutilmoqda` : 'Hammasi ko\'rib chiqilgan'}
          </span>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {QUEUE_LINKS.map(({ key, label, icon: Icon, tab }) => {
            const count = queues[key] || 0;
            return (
              <Link
                key={key}
                to={`/superadmin/dashboard?tab=${tab}`}
                className={`group flex items-center gap-3 p-4 rounded-2xl border shadow-sm transition hover:shadow-md hover:-translate-y-0.5 ${
                  count > 0
                    ? 'bg-white dark:bg-slate-800 border-amber-200 dark:border-amber-900/60'
                    : 'bg-white dark:bg-slate-800 border-gray-100 dark:border-slate-700'
                }`}
              >
                <span className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                  count > 0
                    ? 'bg-amber-50 text-amber-600 dark:bg-amber-950 dark:text-amber-400'
                    : 'bg-gray-50 text-gray-400 dark:bg-slate-900 dark:text-slate-500'
                }`}>
                  <Icon size={18} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-xl font-black text-gray-900 dark:text-slate-100 leading-none">{count}</span>
                  <span className="block text-[11px] font-semibold text-gray-500 dark:text-slate-400 truncate mt-1">{label}</span>
                </span>
                <ChevronRight size={16} className="text-gray-300 dark:text-slate-600 group-hover:text-primary-500 transition shrink-0" />
              </Link>
            );
          })}
        </div>
      </section>

      {/* Money flow */}
      <section className="space-y-3">
        <SectionTitle>Moliya</SectionTitle>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard label="Jami yig'ilgan sarmoya" value={formatAmount(finance.totalRaised)} icon={TrendingUp} />
          <StatCard label="Hamyonlardagi mablag'" value={formatAmount(finance.walletBalance)} icon={Wallet} />
          <StatCard label="Muvaffaqiyatli aylanma" value={formatAmount(finance.completedVolume)} icon={ArrowLeftRight} />
          <StatCard label="Kutilayotgan tranzaksiyalar" value={finance.pendingTransactions ?? 0} icon={Landmark} />
        </div>
      </section>

      {/* User base */}
      <section className="space-y-3">
        <SectionTitle>Foydalanuvchilar</SectionTitle>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
          <StatCard label="Jami" value={users.total ?? 0} icon={Users} />
          <StatCard label="Sarmoyadorlar" value={users.investors ?? 0} icon={Briefcase} />
          <StatCard label="Fermerlar" value={users.farmers ?? 0} icon={Sprout} />
          <StatCard label="Xodimlar" value={users.staff ?? 0} icon={ShieldCheck} />
          <StatCard label="Bloklangan" value={users.blocked ?? 0} icon={Ban} />
        </div>
      </section>
    </div>
  );
};

export default OverviewPanel;
