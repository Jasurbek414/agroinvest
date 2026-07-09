import React, { useEffect, useState } from 'react';
import { getPendingExpenses, reviewExpense } from '../../../api/expenses.api';
import { formatAmount, formatDate } from '../../../utils/format';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import DocumentChips from '../../ui/DocumentChips';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';

const CATEGORY_LABEL_UZ = {
  FEED: 'Yem-xashak',
  MEDICINE: 'Dori-darmon',
  VET_SERVICE: 'Veterinar xizmati',
  TRANSPORT: 'Transport',
  LABOR: 'Ish haqi',
  EQUIPMENT: 'Jihozlar',
  OTHER: 'Boshqa',
};

const PAYER_LABEL_UZ = {
  INVESTOR_BUDGET: "Loyiha byudjetidan",
  FARMER: "Fermer to'lagan",
};

// Mirrors ReportsTab's shape (the closest existing "review a PENDING queue" tab)
const ExpensesTab = ({ onActionDone }) => {
  const [expenses, setExpenses] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getPendingExpenses(page, 12);
      setExpenses(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError('Harajatlarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(0); }, []);

  const runAction = async (id, approve, comment) => {
    try {
      await reviewExpense(id, approve, comment);
      showToast(approve ? 'Harajat tasdiqlandi' : 'Harajat rad etildi');
      fetchData(pageInfo.pageNumber);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  return (
    <div>
      <div className="p-6 border-b border-gray-100 dark:border-slate-700">
        <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">Kutilayotgan harajatlar</h2>
        <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">
          Fermerlar kiritgan joriy harajatlar - tasdiqlangach sotuv daromadidan qaytariladi (FARMER to'lovchi bo'lsa)
        </p>
      </div>

      <DataTable
        loading={loading}
        error={error}
        onRetry={() => fetchData(pageInfo.pageNumber)}
        rows={expenses}
        emptyTitle="Tasdiqlanish kutilayotgan harajatlar yo'q"
        page={{ ...pageInfo, onPageChange: fetchData }}
        columns={[
          { key: 'projectTitle', header: 'Loyiha', render: (e) => <span className="font-semibold text-xs">{e.projectTitle}</span> },
          { key: 'category', header: 'Toifa', render: (e) => <span className="text-xs">{CATEGORY_LABEL_UZ[e.category] || e.category}</span> },
          { key: 'amount', header: 'Summa', render: (e) => <span className="font-bold text-xs">{formatAmount(e.amount)}</span> },
          { key: 'payerSource', header: "To'lovchi", render: (e) => <span className="text-xs">{PAYER_LABEL_UZ[e.payerSource] || e.payerSource}</span> },
          { key: 'expenseDate', header: 'Sana', render: (e) => <span className="text-xs">{formatDate(e.expenseDate)}</span> },
          { key: 'receiptUrls', header: 'Cheklar', render: (e) => <DocumentChips urls={e.receiptUrls || []} emptyLabel="Chek yo'q" altPrefix="Chek" /> },
          {
            key: 'actions', header: 'Amallar', align: 'right',
            render: (e) => (
              <div className="flex justify-end gap-2">
                <Button variant="danger" size="sm" onClick={() => setRejectTarget(e.id)}>Rad etish</Button>
                <Button variant="primary" size="sm" onClick={() => runAction(e.id, true, null)}>Tasdiqlash</Button>
              </div>
            ),
          },
        ]}
        renderMobileCard={(e) => (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="font-bold text-xs">{e.projectTitle}</span>
              <Badge status={e.status} />
            </div>
            <p className="text-xs text-gray-600 dark:text-slate-300">
              {CATEGORY_LABEL_UZ[e.category] || e.category} · {formatAmount(e.amount)} · {PAYER_LABEL_UZ[e.payerSource] || e.payerSource}
            </p>
            {e.description && <p className="text-xs text-gray-500 dark:text-slate-400">{e.description}</p>}
            <DocumentChips urls={e.receiptUrls || []} emptyLabel="Chek yo'q" altPrefix="Chek" />
            <div className="flex gap-2 pt-1">
              <Button variant="danger" size="sm" onClick={() => setRejectTarget(e.id)}>Rad etish</Button>
              <Button variant="primary" size="sm" onClick={() => runAction(e.id, true, null)}>Tasdiqlash</Button>
            </div>
          </div>
        )}
      />

      <PromptDialog
        open={!!rejectTarget}
        title="Harajatni rad etish"
        label="Izoh"
        tone="danger"
        confirmLabel="Rad etish"
        onCancel={() => setRejectTarget(null)}
        onConfirm={(comment) => { runAction(rejectTarget, false, comment); setRejectTarget(null); }}
      />
    </div>
  );
};

export default ExpensesTab;
