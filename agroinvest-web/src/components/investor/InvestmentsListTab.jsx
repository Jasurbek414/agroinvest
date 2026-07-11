import React, { useMemo, useState } from 'react';
import { Inbox, Download } from 'lucide-react';
import EmptyState from '../ui/EmptyState';
import ErrorState from '../ui/ErrorState';
import SearchBar from '../ui/SearchBar';
import InvestmentCard from './InvestmentCard';
import { STATUS_LABEL_UZ } from '../ui/Badge';
import { downloadCsv } from '../../utils/csv';
import { formatDate } from '../../utils/format';

const STATUS_FILTERS = ['ALL', 'CONFIRMED', 'PAID_OUT', 'CANCELLED'];

// Holdings list with client-side status/search filtering and a CSV export -
// the dataset is the already-fetched page, so no extra requests are needed.
const InvestmentsListTab = ({ investments, loading, error, onRetry, reviewedIds, onFarmerProfile, onCancel, onReview }) => {
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [query, setQuery] = useState('');

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return investments.filter((inv) => {
      if (statusFilter !== 'ALL' && inv.status !== statusFilter) return false;
      if (q && !inv.projectTitle.toLowerCase().includes(q)) return false;
      return true;
    });
  }, [investments, statusFilter, query]);

  const exportCsv = () => {
    downloadCsv(
      `sarmoyalarim_${new Date().toISOString().slice(0, 10)}.csv`,
      ['Loyiha', 'Sana', 'Summa (UZS)', 'Ulush (%)', 'Holat'],
      filtered.map((inv) => [
        inv.projectTitle,
        formatDate(inv.createdAt),
        inv.amount,
        inv.sharePct?.toFixed(2),
        STATUS_LABEL_UZ[inv.status] || inv.status,
      ]),
    );
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-20 space-y-3">
        <div className="w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin" />
        <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold animate-pulse">Sarmoyalar yuklanmoqda...</p>
      </div>
    );
  }

  if (error) return <ErrorState message={error} onRetry={onRetry} />;

  if (investments.length === 0) {
    return <EmptyState icon={Inbox} title="Sizda hali faol sarmoyalar mavjud emas" subtitle="Investitsiyalar bozoridan birinchi loyihangizni tanlang" />;
  }

  return (
    <div className="space-y-4 animate-in fade-in duration-300">
      {/* Filter row: status chips + search + export */}
      <div className="flex flex-col md:flex-row md:items-center gap-3">
        <div className="flex flex-wrap gap-1.5">
          {STATUS_FILTERS.map((s) => (
            <button
              key={s}
              onClick={() => setStatusFilter(s)}
              className={`px-3 py-1.5 text-[11px] font-bold rounded-xl border transition duration-200 ${
                statusFilter === s
                  ? 'bg-primary-600 border-primary-600 text-white shadow-sm'
                  : 'bg-white dark:bg-slate-900 border-gray-200 dark:border-slate-700 text-gray-500 dark:text-slate-400 hover:border-primary-400 hover:text-primary-600'
              }`}
            >
              {s === 'ALL' ? 'Barchasi' : STATUS_LABEL_UZ[s] || s}
            </button>
          ))}
        </div>

        <div className="flex items-center gap-2 md:ml-auto">
          <SearchBar value={query} onChange={setQuery} placeholder="Loyiha nomi bo'yicha..." className="w-full md:w-56" />
          <button
            onClick={exportCsv}
            disabled={filtered.length === 0}
            title="CSV yuklab olish"
            className="inline-flex items-center gap-1.5 px-3.5 py-2.5 bg-white dark:bg-slate-900 border border-gray-200 dark:border-slate-700 text-gray-600 dark:text-slate-300 text-xs font-bold rounded-xl hover:border-primary-400 hover:text-primary-600 disabled:opacity-40 disabled:cursor-not-allowed transition duration-200 shrink-0"
          >
            <Download size={14} />
            <span className="hidden sm:inline">CSV</span>
          </button>
        </div>
      </div>

      {filtered.length === 0 ? (
        <EmptyState icon={Inbox} title="Filtrga mos sarmoya topilmadi" />
      ) : (
        filtered.map((inv) => (
          <InvestmentCard
            key={inv.id}
            investment={inv}
            reviewed={reviewedIds.has(inv.id)}
            onFarmerProfile={onFarmerProfile}
            onCancel={onCancel}
            onReview={onReview}
          />
        ))
      )}
    </div>
  );
};

export default InvestmentsListTab;
