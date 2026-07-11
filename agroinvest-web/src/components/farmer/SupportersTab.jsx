import React, { useEffect, useMemo, useState } from 'react';
import { Inbox, Users, Download } from 'lucide-react';
import { getProjectInvestments } from '../../api/investments.api';
import SearchBar from '../ui/SearchBar';
import { downloadCsv } from '../../utils/csv';
import { formatAmount, formatDate } from '../../utils/format';

// All investors backing the farmer's FUNDING/ACTIVE/COMPLETED projects.
// Owns its fetch (one request per relevant project, merged client-side -
// there is no cross-project investors endpoint for farmers).
const SupportersTab = ({ projects }) => {
  const [supporters, setSupporters] = useState([]);
  const [loading, setLoading] = useState(false);
  const [query, setQuery] = useState('');

  useEffect(() => {
    if (projects.length === 0) return;
    let cancelled = false;

    const fetchSupporters = async () => {
      setLoading(true);
      try {
        const relevant = projects.filter((p) => ['ACTIVE', 'FUNDING', 'COMPLETED'].includes(p.status));
        const results = await Promise.all(relevant.map(async (p) => {
          try {
            const res = await getProjectInvestments(p.id);
            return (res.data || []).map((inv) => ({ ...inv, projectTitle: p.title }));
          } catch {
            return [];
          }
        }));
        if (!cancelled) {
          setSupporters(results.flat().sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    fetchSupporters();
    return () => { cancelled = true; };
  }, [projects]);

  const summary = useMemo(() => ({
    uniqueInvestors: new Set(supporters.map((s) => s.investorName || s.investorId)).size,
    totalAmount: supporters.reduce((acc, s) => acc + (Number(s.amount) || 0), 0),
  }), [supporters]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return supporters;
    return supporters.filter((s) =>
      (s.investorName || '').toLowerCase().includes(q) || (s.projectTitle || '').toLowerCase().includes(q));
  }, [supporters, query]);

  const exportCsv = () => {
    downloadCsv(
      `sarmoyadorlar_${new Date().toISOString().slice(0, 10)}.csv`,
      ['Sarmoyador', 'Loyiha', 'Sana', 'Summa (UZS)', 'Ulush (%)'],
      filtered.map((s) => [
        s.investorName || `Investor #${String(s.id).substring(0, 4)}`,
        s.projectTitle,
        formatDate(s.createdAt),
        s.amount,
        s.sharePct?.toFixed(2) ?? '',
      ]),
    );
  };

  return (
    <div className="bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/50 dark:border-slate-800/80 shadow-sm space-y-6 animate-in fade-in duration-300">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base">Sherik Sarmoyadorlar</h3>
          <p className="text-xs text-gray-450 dark:text-slate-500 mt-0.5">Sizning faol loyihalaringizni qo'llab-quvvatlayotgan barcha investorlar ro'yxati</p>
        </div>

        <div className="flex items-center gap-2">
          <SearchBar value={query} onChange={setQuery} placeholder="Ism yoki loyiha..." className="w-full md:w-52" />
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

      {/* Aggregate chips */}
      {supporters.length > 0 && (
        <div className="flex flex-wrap gap-3">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-primary-50 dark:bg-primary-950/30 border border-primary-100 dark:border-primary-900/40 rounded-2xl">
            <Users size={14} className="text-primary-600 dark:text-primary-400" />
            <span className="text-xs font-bold text-primary-800 dark:text-primary-300">{summary.uniqueInvestors} ta investor</span>
          </div>
          <div className="inline-flex items-center px-4 py-2 bg-gray-50 dark:bg-slate-950/40 border border-gray-100 dark:border-slate-800 rounded-2xl">
            <span className="text-xs font-bold text-gray-700 dark:text-slate-300">Jami: {formatAmount(summary.totalAmount)}</span>
          </div>
        </div>
      )}

      {loading ? (
        <div className="flex flex-col items-center justify-center py-10 space-y-3">
          <div className="w-6 h-6 border-3 border-primary-500 border-t-transparent rounded-full animate-spin" />
          <p className="text-[11px] text-gray-450 dark:text-slate-500">Sarmoyadorlar yuklanmoqda...</p>
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-10">
          <Inbox className="mx-auto text-gray-300 dark:text-slate-700" size={36} />
          <p className="text-xs text-gray-450 dark:text-slate-500 mt-2">
            {supporters.length === 0 ? "Hali sarmoyadorlar ro'yxatdan o'tmagan" : 'Qidiruvga mos natija topilmadi'}
          </p>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-gray-100 dark:border-slate-800 text-gray-400 font-bold uppercase tracking-wider">
                <th className="pb-3 pl-2">Sarmoyador</th>
                <th className="pb-3">Loyiha nomi</th>
                <th className="pb-3">Sarmoya sanasi</th>
                <th className="pb-3">Kiritilgan pul</th>
                <th className="pb-3 text-right pr-2">Loyiha ulushi</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((item) => (
                <tr key={item.id} className="border-b border-gray-50/50 dark:border-slate-900/50 hover:bg-gray-50/50 dark:hover:bg-slate-950/30 transition duration-150">
                  <td className="py-3 pl-2 font-bold text-gray-800 dark:text-slate-200">
                    {item.investorName || `Investor #${String(item.id).substring(0, 4)}`}
                  </td>
                  <td className="py-3 font-semibold text-gray-600 dark:text-slate-400">{item.projectTitle}</td>
                  <td className="py-3 text-gray-400 font-bold">{formatDate(item.createdAt)}</td>
                  <td className="py-3 font-black text-gray-900 dark:text-slate-100">{formatAmount(item.amount)}</td>
                  <td className="py-3 text-right pr-2 font-black text-primary-600 dark:text-primary-400">
                    {item.sharePct ? `${item.sharePct.toFixed(2)}%` : '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default SupportersTab;
