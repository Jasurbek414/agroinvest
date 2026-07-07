import React, { useEffect, useState } from 'react';
import { FileText } from 'lucide-react';
import { getPendingExpenses, reviewExpense } from '../../../api/expenses.api';
import { formatAmount, formatDate } from '../../../utils/format';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
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

// Same "click a thumbnail to view" idea as MediaThumbnails, but receipts may be
// PDFs (FileStorageService now accepts them) which <img> can't render - so PDFs
// get a labeled link chip instead of a broken thumbnail.
const ReceiptChips = ({ urls = [] }) => {
  if (!urls.length) return <span className="text-xs text-gray-400 dark:text-slate-500">Chek yo'q</span>;
  return (
    <div className="flex gap-2 flex-wrap">
      {urls.map((url, i) =>
        url.toLowerCase().endsWith('.pdf') ? (
          <a
            key={url}
            href={url}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-1 px-2 py-1 rounded-lg border border-gray-200 dark:border-slate-600 text-[10px] font-bold text-gray-600 dark:text-slate-300 hover:border-primary-400"
          >
            <FileText size={12} /> PDF {i + 1}
          </a>
        ) : (
          <a key={url} href={url} target="_blank" rel="noreferrer" className="w-14 h-14 rounded-lg overflow-hidden border border-gray-200 dark:border-slate-600 shrink-0">
            <img src={url} alt={`Chek ${i + 1}`} className="w-full h-full object-cover" />
          </a>
        )
      )}
    </div>
  );
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
          { key: 'receiptUrls', header: 'Cheklar', render: (e) => <ReceiptChips urls={e.receiptUrls || []} /> },
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
            <ReceiptChips urls={e.receiptUrls || []} />
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
