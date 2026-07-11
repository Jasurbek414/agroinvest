import React, { useEffect, useState } from 'react';
import { Download } from 'lucide-react';
import { getPlatformTransactions, exportPlatformTransactionsCsv } from '../../api/superadmin.api';
import Badge from '../ui/Badge';
import Button from '../ui/Button';
import Card from '../ui/Card';
import DataTable from '../ui/DataTable';
import { useToast } from '../ui/ToastProvider';
import { formatAmount, formatDate } from '../../utils/format';

const TYPE_OPTIONS = [
  { value: '', label: 'Barcha turlar' },
  { value: 'DEPOSIT', label: "Hisob to'ldirish" },
  { value: 'WITHDRAWAL', label: 'Yechish' },
  { value: 'PAYOUT', label: "Daromad to'lovi" },
  { value: 'FARMER_PAYOUT', label: "Fermer to'lovi" },
  { value: 'COMMISSION', label: 'Komissiya' },
  { value: 'REFUND', label: 'Qaytarish' },
];

const STATUS_OPTIONS = [
  { value: '', label: 'Barcha holatlar' },
  { value: 'PENDING', label: 'Kutilmoqda' },
  { value: 'COMPLETED', label: 'Yakunlangan' },
  { value: 'FAILED', label: 'Muvaffaqiyatsiz' },
  { value: 'CANCELLED', label: 'Bekor qilingan' },
];

const TYPE_LABEL = Object.fromEntries(TYPE_OPTIONS.filter((o) => o.value).map((o) => [o.value, o.label]));

const selectClasses = 'px-3 py-2 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500';

// Platform-wide money movement: every deposit/withdrawal/payout/commission row,
// filterable and exportable as CSV via GET /superadmin/transactions.
const TransactionsPanel = () => {
  const [rows, setRows] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [type, setType] = useState('');
  const [status, setStatus] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [exporting, setExporting] = useState(false);
  const { showToast } = useToast();

  const filters = { type: type || undefined, status: status || undefined, from: from || undefined, to: to || undefined };

  const fetchRows = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getPlatformTransactions(page, 20, filters);
      setRows(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError('Tranzaksiyalarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchRows(0); }, [type, status, from, to]);

  const handleExport = async () => {
    setExporting(true);
    try {
      const blob = await exportPlatformTransactionsCsv(filters);
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `agroinvest-tranzaksiyalar-${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      URL.revokeObjectURL(url);
    } catch (err) {
      showToast('CSV eksport qilishda xatolik yuz berdi', 'error');
    } finally {
      setExporting(false);
    }
  };

  return (
    <Card padded={false} className="overflow-hidden">
      <div className="p-6 border-b border-gray-100 dark:border-slate-700 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold text-gray-900 dark:text-slate-100">Platforma tranzaksiyalari</h2>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">Barcha pul harakatlari: to'ldirish, yechish, to'lovlar va komissiyalar</p>
        </div>
        <Button variant="secondary" size="sm" icon={Download} onClick={handleExport} disabled={exporting}>
          {exporting ? 'Yuklanmoqda...' : 'CSV yuklab olish'}
        </Button>
      </div>

      <DataTable
        loading={loading}
        error={error}
        onRetry={() => fetchRows(pageInfo.pageNumber)}
        rows={rows}
        emptyTitle="Tranzaksiyalar topilmadi"
        filters={
          <div className="flex flex-wrap items-center gap-2">
            <select value={type} onChange={(e) => setType(e.target.value)} className={selectClasses}>
              {TYPE_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
            <select value={status} onChange={(e) => setStatus(e.target.value)} className={selectClasses}>
              {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
            <input type="date" value={from} onChange={(e) => setFrom(e.target.value)} className={selectClasses} title="Boshlanish sanasi" />
            <span className="text-xs text-gray-400 dark:text-slate-500 font-semibold">—</span>
            <input type="date" value={to} onChange={(e) => setTo(e.target.value)} className={selectClasses} title="Tugash sanasi" />
          </div>
        }
        page={{ ...pageInfo, onPageChange: fetchRows }}
        columns={[
          { key: 'createdAt', header: 'Sana', render: (t) => <span className="text-xs text-gray-500 dark:text-slate-400 whitespace-nowrap">{formatDate(t.createdAt)}</span> },
          {
            key: 'user', header: 'Foydalanuvchi', render: (t) => (
              <div>
                <p className="font-semibold text-gray-900 dark:text-slate-100">{t.userName || '—'}</p>
                <p className="text-[11px] font-mono text-gray-400">{t.userPhone}</p>
              </div>
            ),
          },
          { key: 'type', header: 'Turi', render: (t) => <span className="text-xs font-bold text-gray-600 dark:text-slate-300">{TYPE_LABEL[t.type] || t.type}</span> },
          { key: 'amount', header: 'Summa', align: 'right', render: (t) => <span className="font-bold text-gray-900 dark:text-slate-100 whitespace-nowrap">{formatAmount(t.amount)}</span> },
          { key: 'status', header: 'Holat', render: (t) => <Badge status={t.status} /> },
          { key: 'project', header: 'Loyiha', render: (t) => <span className="text-xs text-gray-500 dark:text-slate-400 line-clamp-1 max-w-[180px]">{t.projectTitle || '—'}</span> },
          { key: 'provider', header: "To'lov tizimi", render: (t) => <span className="text-[11px] font-mono text-gray-400">{t.paymentProvider || '—'}</span> },
        ]}
        renderMobileCard={(t) => (
          <div className="space-y-2">
            <div className="flex items-center justify-between gap-2">
              <span className="text-xs font-bold text-gray-600 dark:text-slate-300">{TYPE_LABEL[t.type] || t.type}</span>
              <Badge status={t.status} />
            </div>
            <p className="font-bold text-gray-900 dark:text-slate-100">{formatAmount(t.amount)}</p>
            <p className="text-xs text-gray-500 dark:text-slate-400">{t.userName || '—'} · {t.userPhone}</p>
            <p className="text-[11px] text-gray-400">{formatDate(t.createdAt)}{t.projectTitle ? ` · ${t.projectTitle}` : ''}</p>
          </div>
        )}
      />
    </Card>
  );
};

export default TransactionsPanel;
