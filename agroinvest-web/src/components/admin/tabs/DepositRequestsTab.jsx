import React, { useEffect, useState } from 'react';
import { getDepositRequests, approveDeposit } from '../../../api/admin.api';
import { formatAmount, formatDate } from '../../../utils/format';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import DocumentChips from '../../ui/DocumentChips';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';
import { exportToCsv } from '../../../utils/exportCsv';

const DEPOSIT_CSV_COLUMNS = [
  { header: 'Foydalanuvchi', value: (d) => d.userName },
  { header: 'Summa', value: (d) => d.amount },
  { header: 'Holat', value: (d) => d.status },
  { header: 'Sana', value: (d) => formatDate(d.createdAt) },
];

const DepositRequestsTab = ({ onActionDone }) => {
  const [requests, setRequests] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getDepositRequests(page, 12);
      setRequests(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError("To'lov so'rovlarini yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(0); }, []);

  const runAction = async (id, approve, comment) => {
    try {
      await approveDeposit(id, approve, comment);
      showToast(approve ? "To'lov so'rovi tasdiqlandi va hamyonga qo'shildi" : "To'lov so'rovi rad etildi");
      fetchData(pageInfo.pageNumber);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  return (
    <div>
      <div className="p-6 border-b border-gray-100 dark:border-slate-700">
        <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">To'lov (depozit) so'rovlari</h2>
        <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">
          Foydalanuvchi bank o'tkazmasi cheki bilan yuborgan to'ldirish so'rovlari - tasdiqlansa hamyonga qo'shiladi
        </p>
      </div>

      <DataTable
        loading={loading}
        error={error}
        onRetry={() => fetchData(pageInfo.pageNumber)}
        rows={requests}
        emptyTitle="To'lov so'rovlari yo'q"
        page={{ ...pageInfo, onPageChange: fetchData }}
        onExport={() => exportToCsv(requests, DEPOSIT_CSV_COLUMNS, 'tolov-sorovlari.csv')}
        columns={[
          { key: 'userName', header: 'Foydalanuvchi', render: (d) => <span className="font-semibold text-xs">{d.userName}</span> },
          { key: 'amount', header: 'Summa', render: (d) => <span className="font-bold text-xs">{formatAmount(d.amount)}</span> },
          { key: 'proofUrl', header: 'Chek', render: (d) => <DocumentChips urls={d.proofUrl ? [d.proofUrl] : []} emptyLabel="Chek yo'q" altPrefix="Chek" /> },
          { key: 'createdAt', header: 'Sana', render: (d) => <span className="text-xs">{formatDate(d.createdAt)}</span> },
          { key: 'status', header: 'Holat', render: (d) => <Badge status={d.status} /> },
          {
            key: 'actions', header: 'Amallar', align: 'right',
            render: (d) => d.status === 'PENDING' ? (
              <div className="flex justify-end gap-2">
                <Button variant="danger" size="sm" onClick={() => setRejectTarget(d.id)}>Rad etish</Button>
                <Button variant="primary" size="sm" onClick={() => runAction(d.id, true, null)}>Tasdiqlash</Button>
              </div>
            ) : null,
          },
        ]}
        renderMobileCard={(d) => (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="font-bold text-xs">{d.userName}</span>
              <Badge status={d.status} />
            </div>
            <p className="text-xs text-gray-600 dark:text-slate-300">{formatAmount(d.amount)} · {formatDate(d.createdAt)}</p>
            <DocumentChips urls={d.proofUrl ? [d.proofUrl] : []} emptyLabel="Chek yo'q" altPrefix="Chek" />
            {d.status === 'PENDING' && (
              <div className="flex gap-2 pt-1">
                <Button variant="danger" size="sm" onClick={() => setRejectTarget(d.id)}>Rad etish</Button>
                <Button variant="primary" size="sm" onClick={() => runAction(d.id, true, null)}>Tasdiqlash</Button>
              </div>
            )}
          </div>
        )}
      />

      <PromptDialog
        open={!!rejectTarget}
        title="To'lov so'rovini rad etish"
        label="Rad etish sababi"
        tone="danger"
        confirmLabel="Rad etish"
        onCancel={() => setRejectTarget(null)}
        onConfirm={(reason) => { runAction(rejectTarget, false, reason); setRejectTarget(null); }}
      />
    </div>
  );
};

export default DepositRequestsTab;
