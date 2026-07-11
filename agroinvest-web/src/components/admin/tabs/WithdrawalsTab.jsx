import React, { useEffect, useState } from 'react';
import { Copy, Check, Eye, Wallet, ShieldAlert, BadgeDollarSign, Landmark, Search } from 'lucide-react';
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
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [copiedId, setCopiedId] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getWithdrawalRequests(page, 15);
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
      setSelectedRequest(null);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const handleCopy = (text, id) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    showToast('Karta raqami nusxalandi!');
    setTimeout(() => setCopiedId(null), 2000);
  };

  // Local client-side filters for instant feedback alongside pagination
  const filteredWithdrawals = withdrawals.filter(w => {
    const matchesSearch = 
      w.userName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      w.bankName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      w.cardNumber?.includes(searchQuery);
    const matchesStatus = statusFilter ? w.status === statusFilter : true;
    return matchesSearch && matchesStatus;
  });

  // Calculate statistics
  const pendingCount = withdrawals.filter(w => w.status === 'PENDING').length;
  const totalPendingAmount = withdrawals
    .filter(w => w.status === 'PENDING')
    .reduce((sum, w) => sum + (w.amount || 0), 0);
  const averageAmount = withdrawals.length 
    ? Math.round(withdrawals.reduce((sum, w) => sum + (w.amount || 0), 0) / withdrawals.length) 
    : 0;

  return (
    <div className="space-y-6 p-6">
      {/* Stats row */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-amber-50/50 dark:bg-amber-950/10 border border-amber-100 dark:border-amber-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-amber-500/10 text-amber-600 dark:text-amber-400 rounded-xl shrink-0">
            <Wallet size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Kutilayotgan so'rovlar</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{pendingCount} ta</p>
          </div>
        </div>

        <div className="bg-primary-50/50 dark:bg-primary-950/10 border border-primary-100 dark:border-primary-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-primary-500/10 text-primary-600 dark:text-primary-400 rounded-xl shrink-0">
            <BadgeDollarSign size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Kutilayotgan jami summa</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{formatAmount(totalPendingAmount)}</p>
          </div>
        </div>

        <div className="bg-sky-50/50 dark:bg-sky-950/10 border border-sky-100 dark:border-sky-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-sky-500/10 text-sky-600 dark:text-sky-400 rounded-xl shrink-0">
            <Landmark size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">O'rtacha yechish summasi</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{formatAmount(averageAmount)}</p>
          </div>
        </div>
      </div>

      {/* Main Panel Content */}
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden">
        <DataTable
          loading={loading}
          error={error}
          onRetry={() => fetchData(pageInfo.pageNumber)}
          rows={filteredWithdrawals}
          emptyTitle="Yechib olish so'rovlari yo'q"
          searchable
          search={searchQuery}
          onSearchChange={setSearchQuery}
          searchPlaceholder="Ism, bank yoki karta bo'yicha..."
          filters={
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-2 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500"
            >
              <option value="">Barcha holatlar</option>
              <option value="PENDING">Kutilmoqda</option>
              <option value="COMPLETED">Tasdiqlangan</option>
              <option value="REJECTED">Rad etilgan</option>
            </select>
          }
          page={{ ...pageInfo, onPageChange: fetchData }}
          onExport={() => exportToCsv(withdrawals, WITHDRAWAL_CSV_COLUMNS, 'yechish-sorovlari.csv')}
          columns={[
            { key: 'userName', header: 'Foydalanuvchi', render: (w) => <span className="font-semibold text-gray-900 dark:text-slate-100">{w.userName}</span> },
            { key: 'card', header: 'Karta tafsilotlari', render: (w) => (
              <div className="flex items-center gap-2">
                <span className="text-xs font-mono text-gray-500 dark:text-slate-400 bg-gray-50 dark:bg-slate-900 px-2.5 py-1 rounded-lg border border-gray-100 dark:border-slate-800">
                  {w.bankName} · {w.cardNumber}
                </span>
                <button
                  onClick={() => handleCopy(w.cardNumber, w.id)}
                  className="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-400 hover:text-gray-600 transition"
                  title="Nusxalash"
                >
                  {copiedId === w.id ? <Check size={14} className="text-green-500" /> : <Copy size={14} />}
                </button>
              </div>
            )},
            { key: 'amount', header: 'Summa', render: (w) => <span className="font-bold text-primary-700 dark:text-primary-400">{formatAmount(w.amount)}</span> },
            { key: 'status', header: 'Holat', render: (w) => <Badge status={w.status} /> },
            {
              key: 'actions',
              header: 'Amallar',
              align: 'right',
              render: (w) => (
                <div className="flex justify-end gap-1.5">
                  <Button variant="ghost" size="sm" icon={Eye} onClick={() => setSelectedRequest(w)}>Batafsil</Button>
                  {w.status === 'PENDING' && (
                    <>
                      <Button variant="danger" size="sm" onClick={() => setRejectTarget(w.id)}>Rad etish</Button>
                      <Button variant="primary" size="sm" onClick={() => runAction(w.id, true, null)}>Tasdiqlash</Button>
                    </>
                  )}
                </div>
              ),
            },
          ]}
          renderMobileCard={(w) => (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <p className="font-semibold text-gray-900 dark:text-slate-100">{w.userName}</p>
                <Badge status={w.status} />
              </div>
              <div className="flex items-center justify-between text-xs bg-gray-50 dark:bg-slate-900 px-2 py-1.5 rounded-lg border border-gray-100 dark:border-slate-800">
                <span className="font-mono text-gray-500 dark:text-slate-400">{w.bankName} - {w.cardNumber}</span>
                <button onClick={() => handleCopy(w.cardNumber, w.id)} className="text-gray-400 hover:text-gray-600">
                  {copiedId === w.id ? <Check size={12} className="text-green-500" /> : <Copy size={12} />}
                </button>
              </div>
              <div className="flex items-center justify-between">
                <p className="font-bold text-primary-700 dark:text-primary-400">{formatAmount(w.amount)}</p>
                <button onClick={() => setSelectedRequest(w)} className="text-xs text-primary-600 hover:underline font-bold">Batafsil</button>
              </div>
              {w.status === 'PENDING' && (
                <div className="flex gap-2 pt-1">
                  <Button variant="danger" size="sm" className="flex-1" onClick={() => setRejectTarget(w.id)}>Rad etish</Button>
                  <Button variant="primary" size="sm" className="flex-1" onClick={() => runAction(w.id, true, null)}>Tasdiqlash</Button>
                </div>
              )}
            </div>
          )}
        />
      </div>

      {/* Details modal */}
      {selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm transition-opacity">
          <div className="relative w-full max-w-md bg-white dark:bg-slate-800 rounded-3xl shadow-xl overflow-hidden animate-in fade-in zoom-in duration-200 border border-gray-100 dark:border-slate-700">
            <div className="px-6 py-5 border-b border-gray-100 dark:border-slate-700 flex justify-between items-center bg-gray-50/50 dark:bg-slate-900/30">
              <div>
                <h3 className="text-lg font-bold text-gray-900 dark:text-slate-100">Yechish so'rovi batafsil</h3>
                <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">Yaratilgan sana: {formatDate(selectedRequest.createdAt)}</p>
              </div>
              <button onClick={() => setSelectedRequest(null)} className="p-2 rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 hover:text-gray-600">&times;</button>
            </div>

            <div className="p-6 space-y-4">
              <div className="flex items-center gap-4 pb-4 border-b border-gray-100 dark:border-slate-700">
                <div className="w-12 h-12 rounded-xl bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 flex items-center justify-center font-extrabold shrink-0">
                  <Wallet size={24} />
                </div>
                <div>
                  <h4 className="text-base font-bold text-gray-900 dark:text-slate-100">{selectedRequest.userName}</h4>
                  <Badge status={selectedRequest.status} />
                </div>
              </div>

              <div className="space-y-3 text-sm">
                <div>
                  <p className="text-xs text-gray-400 font-medium">Bank nomi</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 mt-0.5">{selectedRequest.bankName || 'Noma\'lum Bank'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400 font-medium">Karta raqami</p>
                  <div className="flex items-center gap-2 mt-0.5 bg-gray-50 dark:bg-slate-900 p-2 rounded-xl border border-gray-100 dark:border-slate-800">
                    <span className="font-mono font-bold text-gray-800 dark:text-slate-200">{selectedRequest.cardNumber}</span>
                    <button onClick={() => handleCopy(selectedRequest.cardNumber, 'modal')} className="p-1 text-gray-400 hover:text-gray-600">
                      {copiedId === 'modal' ? <Check size={14} className="text-green-500" /> : <Copy size={14} />}
                    </button>
                  </div>
                </div>
                <div>
                  <p className="text-xs text-gray-400 font-medium">So'ralayotgan summa</p>
                  <p className="text-lg font-black text-primary-700 dark:text-primary-400 mt-0.5">{formatAmount(selectedRequest.amount)}</p>
                </div>
                {selectedRequest.comment && (
                  <div className="p-3 bg-red-50 dark:bg-red-950/20 border border-red-100 dark:border-red-900/30 rounded-xl text-xs text-red-700 dark:text-red-400">
                    <span className="font-bold">Rad etilish sababi:</span> {selectedRequest.comment}
                  </div>
                )}
              </div>
            </div>

            <div className="px-6 py-4 border-t border-gray-100 dark:border-slate-700 bg-gray-50/50 dark:bg-slate-900/30 flex justify-end gap-2">
              <Button variant="secondary" onClick={() => setSelectedRequest(null)}>Yopish</Button>
              {selectedRequest.status === 'PENDING' && (
                <>
                  <Button variant="danger" onClick={() => { setRejectTarget(selectedRequest.id); }}>Rad etish</Button>
                  <Button variant="primary" onClick={() => runAction(selectedRequest.id, true, null)}>Tasdiqlash</Button>
                </>
              )}
            </div>
          </div>
        </div>
      )}

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
