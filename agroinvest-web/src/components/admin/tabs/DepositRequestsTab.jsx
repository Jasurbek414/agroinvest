import React, { useEffect, useState } from 'react';
import { Eye, ShieldAlert, Award, FileText, CheckCircle2, XCircle, Search, Landmark, Download } from 'lucide-react';
import { getDepositRequests, approveDeposit } from '../../../api/admin.api';
import { formatAmount, formatDate } from '../../../utils/format';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
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
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getDepositRequests(page, 15);
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
      setSelectedRequest(null);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const filteredRequests = requests.filter(r => {
    const matchesSearch = r.userName?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter ? r.status === statusFilter : true;
    return matchesSearch && matchesStatus;
  });

  const pendingCount = requests.filter(r => r.status === 'PENDING').length;
  const completedCount = requests.filter(r => r.status === 'COMPLETED').length;
  const totalCompletedAmount = requests
    .filter(r => r.status === 'COMPLETED')
    .reduce((sum, r) => sum + (r.amount || 0), 0);

  return (
    <div className="space-y-6 p-6">
      {/* Stats bar */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-amber-50/50 dark:bg-amber-950/10 border border-amber-100 dark:border-amber-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-amber-500/10 text-amber-600 dark:text-amber-400 rounded-xl shrink-0">
            <Landmark size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Kutilayotgan so'rovlar</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{pendingCount} ta</p>
          </div>
        </div>

        <div className="bg-primary-50/50 dark:bg-primary-950/10 border border-primary-100 dark:border-primary-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-primary-500/10 text-primary-600 dark:text-primary-400 rounded-xl shrink-0">
            <CheckCircle2 size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Tasdiqlangan so'rovlar</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{completedCount} ta</p>
          </div>
        </div>

        <div className="bg-sky-50/50 dark:bg-sky-950/10 border border-sky-100 dark:border-sky-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-sky-500/10 text-sky-600 dark:text-sky-400 rounded-xl shrink-0">
            <Award size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Tasdiqlangan jami summa</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{formatAmount(totalCompletedAmount)}</p>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden">
        <DataTable
          loading={loading}
          error={error}
          onRetry={() => fetchData(pageInfo.pageNumber)}
          rows={filteredRequests}
          emptyTitle="To'lov so'rovlari yo'q"
          searchable
          search={searchQuery}
          onSearchChange={setSearchQuery}
          searchPlaceholder="Foydalanuvchi ismi bo'yicha..."
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
          onExport={() => exportToCsv(requests, DEPOSIT_CSV_COLUMNS, 'tolov-sorovlari.csv')}
          columns={[
            { key: 'userName', header: 'Foydalanuvchi', render: (d) => <span className="font-semibold text-gray-900 dark:text-slate-100">{d.userName}</span> },
            { key: 'amount', header: 'Summa', render: (d) => <span className="font-bold text-primary-700 dark:text-primary-400">{formatAmount(d.amount)}</span> },
            { key: 'proofUrl', header: 'To\'lov Hujjati (Chek)', render: (d) => d.proofUrl ? (
              <button 
                onClick={() => { setSelectedRequest(d); }}
                className="flex items-center gap-1.5 px-3 py-1 bg-gray-50 dark:bg-slate-950 border border-gray-100 dark:border-slate-800 rounded-lg text-xs text-primary-600 hover:text-primary-700 font-bold transition shadow-sm"
              >
                <FileText size={14} />
                Chekni ko'rish
              </button>
            ) : <span className="text-xs text-gray-400">Yuklanmagan</span> },
            { key: 'createdAt', header: 'Sana', render: (d) => <span className="text-xs text-gray-500 dark:text-slate-400">{formatDate(d.createdAt)}</span> },
            { key: 'status', header: 'Holat', render: (d) => <Badge status={d.status} /> },
            {
              key: 'actions', header: 'Amallar', align: 'right',
              render: (d) => (
                <div className="flex justify-end gap-1.5">
                  <Button variant="ghost" size="sm" icon={Eye} onClick={() => { setSelectedRequest(d); }}>Batafsil</Button>
                  {d.status === 'PENDING' && (
                    <>
                      <Button variant="danger" size="sm" onClick={() => setRejectTarget(d.id)}>Rad etish</Button>
                      <Button variant="primary" size="sm" onClick={() => runAction(d.id, true, null)}>Tasdiqlash</Button>
                    </>
                  )}
                </div>
              ),
            },
          ]}
          renderMobileCard={(d) => (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="font-bold text-gray-900 dark:text-slate-100">{d.userName}</span>
                <Badge status={d.status} />
              </div>
              <p className="text-xs text-gray-600 dark:text-slate-300">{formatAmount(d.amount)} · {formatDate(d.createdAt)}</p>
              {d.proofUrl && (
                <button 
                  onClick={() => { setSelectedRequest(d); }}
                  className="flex items-center gap-1 bg-gray-50 dark:bg-slate-900 px-2 py-1 rounded-lg border border-gray-100 dark:border-slate-800 text-xs text-primary-600 font-bold"
                >
                  <FileText size={12} />
                  Chekni ochish
                </button>
              )}
              <div className="flex gap-2 pt-1">
                <Button variant="secondary" size="sm" className="flex-1" onClick={() => setSelectedRequest(d)}>Batafsil</Button>
                {d.status === 'PENDING' && (
                  <>
                    <Button variant="danger" size="sm" className="flex-1" onClick={() => setRejectTarget(d.id)}>Rad etish</Button>
                    <Button variant="primary" size="sm" className="flex-1" onClick={() => runAction(d.id, true, null)}>Tasdiqlash</Button>
                  </>
                )}
              </div>
            </div>
          )}
        />
      </div>

      {/* Details & Proof zoom modal */}
      {selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm transition-opacity">
          <div className="relative w-full max-w-lg bg-white dark:bg-slate-800 rounded-3xl shadow-xl overflow-hidden animate-in fade-in zoom-in duration-200 border border-gray-100 dark:border-slate-700">
            <div className="px-6 py-5 border-b border-gray-100 dark:border-slate-700 flex justify-between items-center bg-gray-50/50 dark:bg-slate-900/30">
              <div>
                <h3 className="text-lg font-bold text-gray-900 dark:text-slate-100">To'lov arizasi batafsil</h3>
                <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">Yaratilgan: {formatDate(selectedRequest.createdAt)}</p>
              </div>
              <button onClick={() => setSelectedRequest(null)} className="p-2 rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 hover:text-gray-600">&times;</button>
            </div>

            <div className="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
              <div className="flex items-center gap-4 pb-4 border-b border-gray-100 dark:border-slate-700">
                <div className="w-12 h-12 rounded-xl bg-primary-50 dark:bg-primary-950/40 text-primary-600 dark:text-primary-400 flex items-center justify-center font-extrabold shrink-0">
                  <Landmark size={24} />
                </div>
                <div>
                  <h4 className="text-base font-bold text-gray-900 dark:text-slate-100">{selectedRequest.userName}</h4>
                  <Badge status={selectedRequest.status} />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-xs text-gray-400 font-medium">To'ldirish summasi</p>
                  <p className="text-lg font-black text-primary-700 dark:text-primary-400 mt-0.5">{formatAmount(selectedRequest.amount)}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400 font-medium">To'lov tizimi</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 mt-2">Bank Transfer (Offline)</p>
                </div>
              </div>

              {selectedRequest.proofUrl && (
                <div className="space-y-1.5">
                  <p className="text-xs text-gray-400 font-medium">To'lov cheki (Kvitansiya)</p>
                  <div className="border border-gray-100 dark:border-slate-700 rounded-2xl overflow-hidden bg-gray-50/20 max-h-60 flex items-center justify-center relative group">
                    <img 
                      src={selectedRequest.proofUrl} 
                      alt="To'lov cheki" 
                      className="max-h-60 object-contain w-full transition group-hover:scale-102"
                    />
                    <a 
                      href={selectedRequest.proofUrl} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-xs font-bold transition gap-1.5"
                    >
                      <Eye size={16} /> Asl hajmini ochish
                    </a>
                  </div>
                </div>
              )}

              {selectedRequest.comment && (
                <div className="p-3 bg-red-50 dark:bg-red-950/20 border border-red-100 dark:border-red-900/30 rounded-xl text-xs text-red-700 dark:text-red-400">
                  <span className="font-bold">Rad etilish sababi:</span> {selectedRequest.comment}
                </div>
              )}
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
