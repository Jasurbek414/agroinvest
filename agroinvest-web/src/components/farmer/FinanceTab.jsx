import React, { useEffect, useMemo, useState } from 'react';
import { Receipt, Inbox } from 'lucide-react';
import { getProjectExpenses } from '../../api/expenses.api';
import Badge from '../ui/Badge';
import { formatAmount, formatDate } from '../../utils/format';
import { getExpenseCategoryLabel } from '../../utils/expenseCategory';

// Budget utilization + expense history from real /expenses/project/{id} data.
// (The previous version read stats.totalExpensesByProject, a field the backend
// never returned, so "spent" was silently always 0.)
const FinanceTab = ({ projects, stats }) => {
  const [expenses, setExpenses] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (projects.length === 0) return;
    let cancelled = false;

    const fetchExpenses = async () => {
      setLoading(true);
      try {
        const results = await Promise.all(projects.map(async (p) => {
          try {
            const res = await getProjectExpenses(p.id);
            return (res.data || []).map((e) => ({ ...e, projectTitle: e.projectTitle || p.title }));
          } catch {
            return [];
          }
        }));
        if (!cancelled) {
          setExpenses(results.flat().sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    fetchExpenses();
    return () => { cancelled = true; };
  }, [projects]);

  // Only APPROVED spend counts against the raise; PENDING/REJECTED are listed
  // in the history but don't move the utilization bar.
  const approvedByProject = useMemo(() => {
    const map = new Map();
    expenses.forEach((e) => {
      if (e.status !== 'APPROVED') return;
      map.set(e.projectId, (map.get(e.projectId) || 0) + (Number(e.amount) || 0));
    });
    return map;
  }, [expenses]);

  const totalApproved = [...approvedByProject.values()].reduce((a, b) => a + b, 0);

  // Real average of the farmer's own share across projects (farmerSharePct
  // straight from the project DTO; fall back to 100 - investorSharePct).
  const avgFarmerShare = useMemo(() => {
    const shares = projects
      .map((p) => (p.farmerSharePct ?? (p.investorSharePct != null ? 100 - Number(p.investorSharePct) : null)))
      .filter((v) => v !== null && !Number.isNaN(Number(v)));
    if (shares.length === 0) return null;
    return shares.reduce((a, b) => a + Number(b), 0) / shares.length;
  }, [projects]);

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6 animate-in fade-in duration-300">

      {/* Budget utilization per project */}
      <div className="md:col-span-2 bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/50 dark:border-slate-800/80 shadow-sm space-y-6">
        <div>
          <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base">Moliyaviy foydalanish (Budget Utilization)</h3>
          <p className="text-xs text-gray-450 dark:text-slate-500 mt-0.5">Yig'ilgan sarmoyalarning loyihalar kesimida ishlatilish darajasi (faqat tasdiqlangan xarajatlar)</p>
        </div>

        {projects.length === 0 ? (
          <p className="text-xs text-gray-450 py-10 text-center">Loyihalar mavjud emas</p>
        ) : (
          <div className="space-y-6">
            {projects.map((p) => {
              const raised = Number(p.raisedAmount) || 0;
              const spent = approvedByProject.get(p.id) || 0;
              const usePct = raised > 0 ? Math.min(100, Math.round((spent / raised) * 100)) : 0;
              return (
                <div key={p.id} className="space-y-2 p-4 bg-gray-50 dark:bg-slate-950/40 rounded-2xl border border-gray-100/50 dark:border-slate-950">
                  <div className="flex justify-between items-center text-xs">
                    <span className="font-extrabold text-gray-950 dark:text-slate-100 truncate max-w-[200px]">{p.title}</span>
                    <span className="font-black text-primary-600 dark:text-primary-400">{usePct}% ishlatildi</span>
                  </div>
                  <div className="h-2 w-full rounded-full bg-gray-200 dark:bg-slate-800 overflow-hidden">
                    <div className="bg-primary-600 h-full rounded-full transition-all" style={{ width: `${usePct}%` }} />
                  </div>
                  <div className="flex justify-between items-center text-[10px] text-gray-400 dark:text-slate-555 font-bold">
                    <span>Yig'ilgan: {formatAmount(raised)}</span>
                    <span>Xarajat qilingan: {formatAmount(spent)}</span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Financial indicators - all computed from real data */}
      <div className="bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/50 dark:border-slate-800/80 shadow-sm space-y-5">
        <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base">Fermer daromad tahlili</h3>

        <div className="space-y-4 pt-2 text-xs">
          <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-slate-850">
            <span className="text-gray-400 font-bold">Jami jalb etilgan investitsiya</span>
            <span className="font-black text-gray-900 dark:text-slate-100">{formatAmount(stats?.totalRaised ?? 0)}</span>
          </div>
          <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-slate-850">
            <span className="text-gray-400 font-bold">Tasdiqlangan xarajatlar</span>
            <span className="font-black text-gray-900 dark:text-slate-100">{formatAmount(totalApproved)}</span>
          </div>
          <div className="flex justify-between items-center py-2 border-b border-gray-100 dark:border-slate-850">
            <span className="text-gray-400 font-bold">Kutilayotgan harajatlar</span>
            <span className="font-black text-amber-600 dark:text-amber-400">{stats?.pendingExpenses ?? 0} ta</span>
          </div>
          <div className="flex justify-between items-center py-2">
            <span className="text-gray-400 font-bold">Loyiha ulushingiz o'rtacha</span>
            <span className="font-black text-primary-600 dark:text-primary-400">
              {avgFarmerShare !== null ? `${avgFarmerShare.toFixed(1)}%` : '—'}
            </span>
          </div>
        </div>
      </div>

      {/* Expense history across all projects */}
      <div className="md:col-span-3 bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/50 dark:border-slate-800/80 shadow-sm space-y-5">
        <div className="flex items-center gap-2">
          <Receipt size={16} className="text-primary-600 dark:text-primary-400" />
          <div>
            <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base">Xarajatlar tarixi</h3>
            <p className="text-xs text-gray-450 dark:text-slate-500 mt-0.5">Barcha loyihalaringiz bo'yicha kiritilgan xarajatlar va ularning tasdiqlanish holati</p>
          </div>
        </div>

        {loading ? (
          <div className="flex flex-col items-center justify-center py-8 space-y-3">
            <div className="w-6 h-6 border-3 border-primary-500 border-t-transparent rounded-full animate-spin" />
            <p className="text-[11px] text-gray-450 dark:text-slate-500">Xarajatlar yuklanmoqda...</p>
          </div>
        ) : expenses.length === 0 ? (
          <div className="text-center py-8">
            <Inbox className="mx-auto text-gray-300 dark:text-slate-700" size={32} />
            <p className="text-xs text-gray-450 dark:text-slate-500 mt-2">Hali xarajatlar kiritilmagan</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-gray-100 dark:border-slate-800 text-gray-400 font-bold uppercase tracking-wider">
                  <th className="pb-3 pl-2">Sana</th>
                  <th className="pb-3">Loyiha</th>
                  <th className="pb-3">Kategoriya</th>
                  <th className="pb-3">Izoh</th>
                  <th className="pb-3">Summa</th>
                  <th className="pb-3 text-right pr-2">Holat</th>
                </tr>
              </thead>
              <tbody>
                {expenses.map((e) => (
                  <tr key={e.id} className="border-b border-gray-50/50 dark:border-slate-900/50 hover:bg-gray-50/50 dark:hover:bg-slate-950/30 transition duration-150">
                    <td className="py-3 pl-2 text-gray-400 font-bold whitespace-nowrap">{formatDate(e.expenseDate || e.createdAt)}</td>
                    <td className="py-3 font-semibold text-gray-600 dark:text-slate-400 max-w-[160px] truncate">{e.projectTitle}</td>
                    <td className="py-3 font-bold text-gray-800 dark:text-slate-200 whitespace-nowrap">{getExpenseCategoryLabel(e.category)}</td>
                    <td className="py-3 text-gray-500 dark:text-slate-400 max-w-[220px] truncate" title={e.description}>{e.description || '—'}</td>
                    <td className="py-3 font-black text-gray-900 dark:text-slate-100 whitespace-nowrap">{formatAmount(e.amount)}</td>
                    <td className="py-3 text-right pr-2">
                      <Badge status={e.status} />
                      {e.status === 'REJECTED' && e.reviewComment && (
                        <p className="text-[10px] text-rose-500 dark:text-rose-400 mt-1 max-w-[160px] truncate ml-auto" title={e.reviewComment}>{e.reviewComment}</p>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

    </div>
  );
};

export default FinanceTab;
