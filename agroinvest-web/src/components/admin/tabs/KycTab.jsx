import React, { useEffect, useState } from 'react';
import { FileSearch, Ban, ShieldAlert, Users, CheckCircle, AlertTriangle, UserCheck, XCircle } from 'lucide-react';
import { getUsers, verifyUserKyc, blockUser } from '../../../api/admin.api';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';
import { useDebounce } from '../../../hooks/useDebounce';
import KycDocumentModal from '../KycDocumentModal';
import { exportToCsv } from '../../../utils/exportCsv';

const ROLE_OPTIONS = [
  { value: '', label: 'Barcha rollar' },
  { value: 'FARMER', label: 'Fermer' },
  { value: 'INVESTOR', label: 'Investor' },
];

const KYC_CSV_COLUMNS = [
  { header: 'Ism', value: (u) => u.fullName },
  { header: 'Telefon', value: (u) => u.phoneNumber },
  { header: 'Rol', value: (u) => u.role },
  { header: 'KYC holati', value: (u) => u.kycStatus },
  { header: 'Bloklangan', value: (u) => (u.isBlocked ? 'Ha' : "Yo'q") },
];

const REJECT_REASONS = [
  "Pasport rasmi aniq ko'rinmayapti (xira)",
  "Selfi va pasport rasmi bir-biriga mos kelmadi",
  "Pasport muddati o'tgan yoki haqiqiy emas",
  "Kiritilgan ma'lumotlar pasportga mos kelmaydi",
  "Qo'shimcha hujjatlar yetarli emas",
];

const KycTab = ({ onActionDone }) => {
  const [users, setUsers] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const [blockTarget, setBlockTarget] = useState(null);
  const [bulkBlockTargets, setBulkBlockTargets] = useState(null);
  const [viewTarget, setViewTarget] = useState(null);
  const [search, setSearch] = useState('');
  const [role, setRole] = useState('');
  const [kycStatusFilter, setKycStatusFilter] = useState('');
  const [selectedRejectReason, setSelectedRejectReason] = useState('');
  const debouncedSearch = useDebounce(search, 350);
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getUsers(page, 15, { role: role || undefined, q: debouncedSearch || undefined });
      setUsers(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError("Foydalanuvchilarni yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(0); }, [debouncedSearch, role]);

  const runAction = async (id, status, reason) => {
    try {
      await verifyUserKyc(id, status, reason);
      showToast(status === 'VERIFIED' ? 'KYC muvaffaqiyatli tasdiqlandi' : 'KYC so\'rovi rad etildi');
      fetchData(pageInfo.pageNumber);
      setSelectedRejectReason('');
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const runBlockAction = async (id, block, reason) => {
    try {
      await blockUser(id, block, reason);
      showToast(block ? 'Foydalanuvchi bloklandi' : 'Foydalanuvchi blokdan yechildi');
      fetchData(pageInfo.pageNumber);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const runBulkBlock = async (ids, reason) => {
    try {
      await Promise.all(ids.map((id) => blockUser(id, true, reason)));
      showToast(`${ids.length} ta foydalanuvchi bloklandi`);
      fetchData(pageInfo.pageNumber);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  // Local filter for KYC status (in addition to server pagination)
  const filteredUsers = users.filter(u => {
    if (kycStatusFilter) return u.kycStatus === kycStatusFilter;
    return true;
  });

  // Calculate statistics
  const pendingKycCount = users.filter(u => u.kycStatus === 'PENDING').length;
  const verifiedKycCount = users.filter(u => u.kycStatus === 'VERIFIED').length;
  const blockedUsersCount = users.filter(u => u.isBlocked).length;

  return (
    <div className="space-y-6 p-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-amber-50/50 dark:bg-amber-950/10 border border-amber-100 dark:border-amber-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-amber-500/10 text-amber-600 dark:text-amber-400 rounded-xl shrink-0">
            <ShieldAlert size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Kutilayotgan KYC</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{pendingKycCount} ta ariza</p>
          </div>
        </div>

        <div className="bg-green-50/50 dark:bg-green-950/10 border border-green-100 dark:border-green-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-green-500/10 text-green-600 dark:text-green-400 rounded-xl shrink-0">
            <UserCheck size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Tasdiqlangan KYC</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{verifiedKycCount} ta foydalanuvchi</p>
          </div>
        </div>

        <div className="bg-red-50/50 dark:bg-red-950/10 border border-red-100 dark:border-red-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-red-500/10 text-red-600 dark:text-red-400 rounded-xl shrink-0">
            <Ban size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Bloklangan hisoblar</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{blockedUsersCount} ta foydalanuvchi</p>
          </div>
        </div>
      </div>

      {/* Grid container for users table */}
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden">
        <DataTable
          loading={loading}
          error={error}
          onRetry={() => fetchData(pageInfo.pageNumber)}
          rows={filteredUsers}
          emptyTitle="Foydalanuvchilar topilmadi"
          searchable
          search={search}
          onSearchChange={setSearch}
          searchPlaceholder="Ism yoki telefon bo'yicha qidirish..."
          filters={
            <div className="flex items-center gap-2">
              <select
                value={role}
                onChange={(e) => setRole(e.target.value)}
                className="px-3 py-2 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500"
              >
                {ROLE_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>{o.label}</option>
                ))}
              </select>
              <select
                value={kycStatusFilter}
                onChange={(e) => setKycStatusFilter(e.target.value)}
                className="px-3 py-2 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500"
              >
                <option value="">Barcha KYC holatlari</option>
                <option value="PENDING">Kutilmoqda</option>
                <option value="VERIFIED">Tasdiqlangan</option>
                <option value="REJECTED">Rad etilgan</option>
              </select>
            </div>
          }
          page={{ ...pageInfo, onPageChange: fetchData }}
          onExport={() => exportToCsv(users, KYC_CSV_COLUMNS, 'kyc-vetting.csv')}
          selectable
          bulkActions={[
            { label: 'Tanlanganlarni bloklash', tone: 'danger', onClick: (rows) => setBulkBlockTargets(rows.map((r) => r.id)) },
          ]}
          columns={[
            { key: 'fullName', header: 'Foydalanuvchi', render: (u) => <span className="font-semibold text-gray-900 dark:text-slate-100">{u.fullName}</span> },
            { key: 'phoneNumber', header: 'Telefon', render: (u) => <span className="text-xs font-mono text-gray-500 dark:text-slate-400 bg-gray-50 dark:bg-slate-900 px-2 py-1 rounded-lg border border-gray-100 dark:border-slate-800">{u.phoneNumber}</span> },
            { key: 'role', header: 'Rol', render: (u) => (
              <span className={`text-[11px] font-bold px-2.5 py-1 rounded-full ${
                u.role === 'FARMER' ? 'bg-indigo-50 text-indigo-700 dark:bg-indigo-950 dark:text-indigo-400' : 'bg-primary-50 text-primary-700 dark:bg-primary-950 dark:text-primary-400'
              }`}>
                {u.role === 'FARMER' ? 'Fermer' : 'Investor'}
              </span>
            )},
            { key: 'kycStatus', header: 'KYC Holati', render: (u) => <Badge status={u.kycStatus} /> },
            {
              key: 'status',
              header: 'Hisob Holati',
              render: (u) => (
                u.isBlocked ? (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-red-100 text-red-800 dark:bg-red-950 dark:text-red-400">
                    <XCircle size={12} /> Bloklangan
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-green-100 text-green-800 dark:bg-green-955 dark:text-green-400">
                    <CheckCircle size={12} /> Faol
                  </span>
                )
              )
            },
            {
              key: 'actions',
              header: 'Amallar',
              align: 'right',
              render: (u) => (
                <div className="flex justify-end gap-1.5">
                  <Button variant="ghost" size="sm" icon={FileSearch} onClick={() => setViewTarget(u)}>Hujjatlar</Button>
                  {u.kycStatus === 'PENDING' && (
                    <>
                      <Button variant="danger" size="sm" onClick={() => setRejectTarget(u.id)}>Rad etish</Button>
                      <Button variant="primary" size="sm" onClick={() => runAction(u.id, 'VERIFIED', null)}>Tasdiqlash</Button>
                    </>
                  )}
                  {u.isBlocked ? (
                    <Button variant="secondary" size="sm" onClick={() => runBlockAction(u.id, false, null)}>Aktivlashtirish</Button>
                  ) : (
                    <Button variant="danger" size="sm" icon={Ban} onClick={() => setBlockTarget(u.id)}>Bloklash</Button>
                  )}
                </div>
              ),
            },
          ]}
          renderMobileCard={(u) => (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <p className="font-semibold text-gray-900 dark:text-slate-100">{u.fullName}</p>
                <Badge status={u.kycStatus} />
              </div>
              <p className="text-xs font-mono text-gray-400">{u.phoneNumber} · {u.role}</p>
              {u.isBlocked && <p className="text-xs text-red-500 font-bold">Bloklangan: {u.blockedReason}</p>}
              <div className="flex gap-2 pt-1">
                <Button variant="secondary" size="sm" className="flex-1" icon={FileSearch} onClick={() => setViewTarget(u)}>Hujjatlar</Button>
                {u.kycStatus === 'PENDING' && (
                  <>
                    <Button variant="danger" size="sm" className="flex-1" onClick={() => setRejectTarget(u.id)}>Rad etish</Button>
                    <Button variant="primary" size="sm" className="flex-1" onClick={() => runAction(u.id, 'VERIFIED', null)}>Tasdiqlash</Button>
                  </>
                )}
                {u.isBlocked ? (
                  <Button variant="secondary" size="sm" className="flex-1" onClick={() => runBlockAction(u.id, false, null)}>Aktivlashtirish</Button>
                ) : (
                  <Button variant="danger" size="sm" className="flex-1" icon={Ban} onClick={() => setBlockTarget(u.id)}>Bloklash</Button>
                )}
              </div>
            </div>
          )}
        />
      </div>

      {/* Reject dialog with template options */}
      {rejectTarget && (
        <PromptDialog
          open={!!rejectTarget}
          title="KYC vetting arizasini rad etish"
          label="Rad etish sababi"
          required
          tone="danger"
          confirmLabel="Rad etish"
          onCancel={() => { setRejectTarget(null); setSelectedRejectReason(''); }}
          onConfirm={(reason) => { runAction(rejectTarget, 'REJECTED', reason || selectedRejectReason); setRejectTarget(null); }}
          extraContent={
            <div className="space-y-2 mt-3">
              <label className="block text-xs font-bold text-gray-400 uppercase">Yoki tayyor sabablardan birini tanlang:</label>
              <div className="flex flex-wrap gap-1.5">
                {REJECT_REASONS.map((reason) => (
                  <button
                    key={reason}
                    type="button"
                    onClick={() => setSelectedRejectReason(reason)}
                    className={`text-xs px-2.5 py-1.5 rounded-lg border transition ${
                      selectedRejectReason === reason
                        ? 'bg-red-50 text-red-700 border-red-300 dark:bg-red-950 dark:text-red-300 dark:border-red-900/60 font-semibold'
                        : 'bg-gray-50 border-gray-200 text-gray-600 dark:bg-slate-900 dark:border-slate-800 hover:bg-gray-100 dark:text-slate-300'
                    }`}
                  >
                    {reason}
                  </button>
                ))}
              </div>
            </div>
          }
        />
      )}

      <PromptDialog
        open={!!blockTarget}
        title="Foydalanuvchini bloklash"
        label="Bloklash sababi"
        required
        tone="danger"
        confirmLabel="Bloklash"
        onCancel={() => setBlockTarget(null)}
        onConfirm={(reason) => { runBlockAction(blockTarget, true, reason); setBlockTarget(null); }}
      />

      <PromptDialog
        open={!!bulkBlockTargets}
        title={`${bulkBlockTargets?.length || 0} ta foydalanuvchini bloklash`}
        label="Bloklash sababi"
        required
        tone="danger"
        confirmLabel="Bloklash"
        onCancel={() => setBulkBlockTargets(null)}
        onConfirm={(reason) => { runBulkBlock(bulkBlockTargets, reason); setBulkBlockTargets(null); }}
      />

      <KycDocumentModal user={viewTarget} onClose={() => setViewTarget(null)} />
    </div>
  );
};

export default KycTab;
