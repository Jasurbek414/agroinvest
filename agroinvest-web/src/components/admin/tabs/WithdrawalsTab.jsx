import React, { useEffect, useState } from 'react';
import { getWithdrawalRequests, approveWithdrawal } from '../../../api/admin.api';
import { formatAmount, formatDate } from '../../../utils/format';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';
import { exportToCsv } from '../../../utils/exportCsv';

const WITHDRAWAL_CSV_COLUMNS = [
  { header: 'Foydalanuvchi', value: (w) => w.userName },
  { header: 'Bank', value: (w) => w.bankName },
  { header: 'Karta', value: (w) => w.cardNumber },
  { header: 'Summa', value: (w) => w.amount },
  { header: 'Holat', value: (w) => w.status },
  { header: 'Sana', value: (w) => (w.createdAt ? formatDate(w.createdAt) : '') },
];

const WithdrawalsTab = ({ onActionDone }) => {
  const [withdrawals, setWithdrawals] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getWithdrawalRequests(page, 12);
      setWithdrawals(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError("Yechish so'rovlarini yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(0); }, []);

  const runAction = async (id, approve, comment) => {
    try {
      await approveWithdrawal(id, approve, comment);
      showToast(approve ? "Yechish so'rovi tasdiqlandi" : "Yechish so'rovi rad etildi");
      fetchData(pageInfo.pageNumber);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  return (
    <div>
      <div className="p-6 border-b border-gray-100 dark:border-slate-700">
        <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">Pul yechib olish so'rovlari</h2>
      </div>

      <DataTable
        loading={loading}
        error={error}
        onRetry={() => fetchData(pageInfo.pageNumber)}
        rows={withdrawals}
        emptyTitle="Yechib olish so'rovlari yo'q"
        page={{ ...pageInfo, onPageChange: fetchData }}
        onExport={() => exportToCsv(withdrawals, WITHDRAWAL_CSV_COLUMNS, 'yechish-sorovlari.csv')}
        columns={[
          { key: 'userName', header: 'Foydalanuvchi', render: (w) => <span className="font-semibold">{w.userName}</span> },
          { key: 'card', header: 'Karta', render: (w) => <span className="text-xs font-mono text-gray-400">{w.bankName} - {w.cardNumber}</span> },
          { key: 'amount', header: 'Summa', render: (w) => <span className="font-bold">{formatAmount(w.amount)}</span> },
          { key: 'status', header: 'Holat', render: (w) => <Badge status={w.status} /> },
          {
            key: 'actions',
            header: 'Amallar',
            align: 'right',
            render: (w) => w.status === 'PENDING' ? (
              <div className="flex justify-end gap-2">
                <Button variant="danger" size="sm" onClick={() => setRejectTarget(w.id)}>Rad etish</Button>
                <Button variant="primary" size="sm" onClick={() => runAction(w.id, true, null)}>Tasdiqlash</Button>
              </div>
            ) : null,
          },
        ]}
        renderMobileCard={(w) => (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <p className="font-semibold text-gray-900 dark:text-slate-100">{w.userName}</p>
              <Badge status={w.status} />
            </div>
            <p className="text-xs font-mono text-gray-400">{w.bankName} - {w.cardNumber}</p>
            <p className="font-bold text-gray-900 dark:text-slate-100">{formatAmount(w.amount)}</p>
            {w.status === 'PENDING' && (
              <div className="flex gap-2 pt-1">
                <Button variant="danger" size="sm" onClick={() => setRejectTarget(w.id)}>Rad etish</Button>
                <Button variant="primary" size="sm" onClick={() => runAction(w.id, true, null)}>Tasdiqlash</Button>
              </div>
            )}
          </div>
        )}
      />

      <PromptDialog
        open={!!rejectTarget}
        title="Yechish so'rovini rad etish"
        label="Rad etish sababi"
        required
        tone="danger"
        confirmLabel="Rad etish"
        onCancel={() => setRejectTarget(null)}
        onConfirm={(reason) => { runAction(rejectTarget, false, reason); setRejectTarget(null); }}
      />
    </div>
  );
};

export default WithdrawalsTab;
