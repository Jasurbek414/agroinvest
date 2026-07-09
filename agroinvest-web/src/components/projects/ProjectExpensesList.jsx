import React, { useEffect, useState } from 'react';
import { Receipt } from 'lucide-react';
import { getProjectExpenses } from '../../api/expenses.api';
import EmptyState from '../ui/EmptyState';
import Badge from '../ui/Badge';
import { formatAmount, formatDate } from '../../utils/format';

const CATEGORY_LABEL_UZ = {
  FEED: 'Yem-xashak',
  MEDICINE: 'Dori-darmon',
  VET_SERVICE: 'Veterinar xizmati',
  TRANSPORT: 'Transport',
  LABOR: 'Ish haqi',
  EQUIPMENT: 'Jihozlar',
  OTHER: 'Boshqa',
};

// Visible to the project owner, its investors, and staff (server enforces this -
// an anonymous/unrelated caller gets 403). Shown on ProjectDetailPage so an
// investor can see how the raise/expenses are actually being spent.
const ProjectExpensesList = ({ projectId }) => {
  const [expenses, setExpenses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [forbidden, setForbidden] = useState(false);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      setForbidden(false);
      try {
        const res = await getProjectExpenses(projectId);
        setExpenses(res.data || []);
      } catch (err) {
        if (err?.error?.code === 'FORBIDDEN') setForbidden(true);
        setExpenses([]);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [projectId]);

  if (loading) {
    return <p className="text-sm text-gray-400 dark:text-slate-500 animate-pulse">Yuklanmoqda...</p>;
  }

  if (forbidden) {
    return <p className="text-xs text-gray-400 dark:text-slate-500">Harajatlarni faqat loyiha egasi, investorlari va adminlar ko'ra oladi</p>;
  }

  if (expenses.length === 0) {
    return <EmptyState icon={Receipt} title="Hali harajat kiritilmagan" />;
  }

  return (
    <div className="space-y-3">
      {expenses.map((e) => (
        <div key={e.id} className="border border-gray-100 dark:border-slate-700 rounded-2xl p-4">
          <div className="flex justify-between items-start gap-3 mb-1.5">
            <span className="text-xs font-bold text-gray-700 dark:text-slate-300">{CATEGORY_LABEL_UZ[e.category] || e.category}</span>
            <Badge status={e.status} />
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm font-bold text-gray-900 dark:text-slate-100">{formatAmount(e.amount)}</span>
            <span className="text-[11px] text-gray-400 dark:text-slate-500">{formatDate(e.expenseDate)}</span>
          </div>
          {e.description && <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">{e.description}</p>}
        </div>
      ))}
    </div>
  );
};

export default ProjectExpensesList;
