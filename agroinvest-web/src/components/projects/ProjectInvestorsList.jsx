import React, { useEffect, useState } from 'react';
import { Users } from 'lucide-react';
import { getProjectInvestors } from '../../api/projects.api';
import EmptyState from '../ui/EmptyState';
import { formatAmount } from '../../utils/format';

// Co-investor transparency ("sherikchilik"): shows who else is in a project and
// at what share, with names masked server-side (e.g. "Jasurbek M.").
const ProjectInvestorsList = ({ projectId }) => {
  const [investors, setInvestors] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const res = await getProjectInvestors(projectId);
        setInvestors(res.data || []);
      } catch {
        setInvestors([]);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [projectId]);

  if (loading) {
    return <p className="text-sm text-gray-400 dark:text-slate-500 animate-pulse">Yuklanmoqda...</p>;
  }

  if (investors.length === 0) {
    return <EmptyState icon={Users} title="Hali investorlar yo'q" />;
  }

  return (
    <div className="space-y-2">
      {investors.map((inv, i) => (
        <div key={i} className="flex items-center justify-between border border-gray-100 dark:border-slate-700 rounded-xl px-4 py-3">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full bg-primary-50 dark:bg-primary-950 text-primary-700 dark:text-primary-400 flex items-center justify-center text-xs font-bold">
              {inv.maskedName?.[0]?.toUpperCase() || '?'}
            </div>
            <span className="text-sm font-semibold text-gray-800 dark:text-slate-200">{inv.maskedName}</span>
          </div>
          <div className="text-right">
            <p className="text-sm font-bold text-gray-900 dark:text-slate-100">{inv.sharePct?.toFixed(1)}%</p>
            <p className="text-[11px] text-gray-400 dark:text-slate-500">{formatAmount(inv.amount)}</p>
          </div>
        </div>
      ))}
    </div>
  );
};

export default ProjectInvestorsList;
