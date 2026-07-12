import React, { useEffect, useState } from 'react';
import { KeyRound, UserCog } from 'lucide-react';
import { getAccounts, blockAccount, resetStaffPassword, changeStaffRole, topUpWallet } from '../../api/superadmin.api';
import Badge from '../ui/Badge';
import Button from '../ui/Button';
import Card from '../ui/Card';
import DataTable from '../ui/DataTable';
import PromptDialog from '../ui/PromptDialog';
import { useToast } from '../ui/ToastProvider';
import { useDebounce } from '../../hooks/useDebounce';

const ROLE_OPTIONS = [
  { value: '', label: 'Barcha rollar' },
  { value: 'ADMIN', label: 'Admin' },
  { value: 'MODERATOR', label: 'Moderator' },
  { value: 'VERIFIER', label: 'Verifikator' },
  { value: 'SUPERADMIN', label: 'SuperAdmin' },
  { value: 'FARMER', label: 'Fermer' },
  { value: 'INVESTOR', label: 'Sarmoyador' },
];

// Staff roles the SuperAdmin can manage in place (reset password / change role) -
// matches the backend's MANAGEABLE_STAFF_ROLES restriction.
const STAFF_ROLES = ['ADMIN', 'MODERATOR', 'VERIFIER'];
const STAFF_ROLE_LABEL = { ADMIN: 'Admin', MODERATOR: 'Moderator', VERIFIER: 'Verifikator' };

// Lists staff accounts and general users (admin/moderator/verifier/superadmin/farmer/investor)
// via the GET /superadmin/accounts endpoint
const AccountsPanel = () => {
  const [users, setUsers] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [blockTarget, setBlockTarget] = useState(null);
  const [selectedUser, setSelectedUser] = useState(null);
  const [passwordTarget, setPasswordTarget] = useState(null);
  const [roleTarget, setRoleTarget] = useState(null);
  const [topUpTarget, setTopUpTarget] = useState(null);
  const [newRole, setNewRole] = useState('');
  const [role, setRole] = useState('');
  const [search, setSearch] = useState('');
  const debouncedSearch = useDebounce(search, 350);
  const { showToast } = useToast();

  const fetchUsers = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getAccounts(page, 20, { role: role || undefined, q: debouncedSearch || undefined });
      setUsers(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError("Hisoblarni yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchUsers(0); }, [role, debouncedSearch]);

  const handleUnblock = async (id) => {
    try {
      await blockAccount(id, false, null);
      showToast('Hisob blokdan chiqarildi');
      fetchUsers(pageInfo.pageNumber);
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const handleBlock = async (reason) => {
    try {
      await blockAccount(blockTarget, true, reason);
      showToast('Hisob bloklandi');
      setBlockTarget(null);
      fetchUsers(pageInfo.pageNumber);
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const handleResetPassword = async (newPassword) => {
    try {
      await resetStaffPassword(passwordTarget.id, newPassword);
      showToast(`${passwordTarget.fullName} uchun yangi parol o'rnatildi`);
      setPasswordTarget(null);
    } catch (err) {
      showToast(err.error?.message || 'Parolni tiklashda xatolik yuz berdi', 'error');
    }
  };

  const handleChangeRole = async () => {
    try {
      await changeStaffRole(roleTarget.id, newRole);
      showToast(`${roleTarget.fullName} endi ${STAFF_ROLE_LABEL[newRole]}`);
      setRoleTarget(null);
      fetchUsers(pageInfo.pageNumber);
    } catch (err) {
      showToast(err.error?.message || "Rolni o'zgartirishda xatolik yuz berdi", 'error');
    }
  };

  const handleTopUp = async (amountStr) => {
    const amount = parseFloat(amountStr);
    if (isNaN(amount) || amount <= 0) {
      showToast('Summa 0 dan katta son bo\'lishi kerak', 'error');
      return;
    }
    try {
      await topUpWallet(topUpTarget.id, amount);
      showToast(`${topUpTarget.fullName} balansi muvaffaqiyatli to'ldirildi!`);
      setTopUpTarget(null);
      setSelectedUser(null);
      fetchUsers(pageInfo.pageNumber);
    } catch (err) {
      showToast(err.error?.message || 'Balansni to\'ldirishda xatolik yuz berdi', 'error');
    }
  };

  const openRoleDialog = (u) => {
    setRoleTarget(u);
    setNewRole(STAFF_ROLES.find((r) => r !== u.role) || 'ADMIN');
  };

  return (
    <Card padded={false} className="overflow-hidden">
      <div className="p-6 border-b border-gray-100 dark:border-slate-700">
        <h2 className="text-lg font-bold text-gray-900 dark:text-slate-100">Foydalanuvchi hisoblari</h2>
      </div>

      <DataTable
        loading={loading}
        error={error}
        onRetry={() => fetchUsers(pageInfo.pageNumber)}
        rows={users}
        emptyTitle="Hisoblar topilmadi"
        searchable
        search={search}
        onSearchChange={setSearch}
        searchPlaceholder="Ism yoki telefon bo'yicha qidirish..."
        filters={
          <select
            value={role}
            onChange={(e) => setRole(e.target.value)}
            className="px-3 py-2 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500"
          >
            {ROLE_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
        }
        page={{ ...pageInfo, onPageChange: fetchUsers }}
        columns={[
          { key: 'fullName', header: 'Ism', render: (u) => <span className="font-semibold">{u.fullName}</span> },
          { key: 'phoneNumber', header: 'Telefon', render: (u) => <span className="text-xs font-mono text-gray-400">{u.phoneNumber}</span> },
          { key: 'role', header: 'Rol', render: (u) => <span className="text-xs font-bold text-gray-500 dark:text-slate-400">{u.role}</span> },
          { key: 'status', header: 'Holat', render: (u) => <Badge tone={u.isBlocked ? 'red' : 'green'}>{u.isBlocked ? 'Bloklangan' : 'Faol'}</Badge> },
          {
            key: 'actions',
            header: 'Amallar',
            align: 'right',
            render: (u) => (
              <div className="flex items-center justify-end gap-2">
                {STAFF_ROLES.includes(u.role) && (
                  <>
                    <Button variant="ghost" size="sm" icon={KeyRound} title="Parolni tiklash" onClick={() => setPasswordTarget(u)} />
                    <Button variant="ghost" size="sm" icon={UserCog} title="Rolni o'zgartirish" onClick={() => openRoleDialog(u)} />
                  </>
                )}
                <Button variant="secondary" size="sm" onClick={() => setSelectedUser(u)}>Batafsil</Button>
                {u.isBlocked ? (
                  <Button variant="primary" size="sm" onClick={() => handleUnblock(u.id)}>Blokdan chiqarish</Button>
                ) : (
                  <Button variant="danger" size="sm" onClick={() => setBlockTarget(u.id)}>Bloklash</Button>
                )}
              </div>
            ),
          },
        ]}
        renderMobileCard={(u) => (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <p className="font-semibold text-gray-900 dark:text-slate-100">{u.fullName}</p>
              <Badge tone={u.isBlocked ? 'red' : 'green'}>{u.isBlocked ? 'Bloklangan' : 'Faol'}</Badge>
            </div>
            <p className="text-xs font-mono text-gray-400">{u.phoneNumber} · {u.role}</p>
            <div className="flex gap-2">
              <Button variant="secondary" size="sm" className="flex-1" onClick={() => setSelectedUser(u)}>Batafsil</Button>
              {u.isBlocked ? (
                <Button variant="primary" size="sm" className="flex-1" onClick={() => handleUnblock(u.id)}>Blokdan chiqarish</Button>
              ) : (
                <Button variant="danger" size="sm" className="flex-1" onClick={() => setBlockTarget(u.id)}>Bloklash</Button>
              )}
            </div>
            {STAFF_ROLES.includes(u.role) && (
              <div className="flex gap-2">
                <Button variant="ghost" size="sm" className="flex-1" icon={KeyRound} onClick={() => setPasswordTarget(u)}>Parol</Button>
                <Button variant="ghost" size="sm" className="flex-1" icon={UserCog} onClick={() => openRoleDialog(u)}>Rol</Button>
              </div>
            )}
          </div>
        )}
      />

      <PromptDialog
        open={!!blockTarget}
        title="Hisobni bloklash"
        label="Bloklash sababi"
        required
        tone="danger"
        confirmLabel="Bloklash"
        onCancel={() => setBlockTarget(null)}
        onConfirm={handleBlock}
      />

      <PromptDialog
        open={!!passwordTarget}
        title={`Parolni tiklash: ${passwordTarget?.fullName || ''}`}
        label="Yangi parol (kamida 6 belgi)"
        required
        confirmLabel="Parolni o'rnatish"
        onCancel={() => setPasswordTarget(null)}
        onConfirm={handleResetPassword}
      />

      <PromptDialog
        open={!!topUpTarget}
        title={`Balansni to'ldirish: ${topUpTarget?.fullName || ''}`}
        label="To'ldirish summasi (UZS)"
        placeholder="Masalan: 5000000"
        required
        confirmLabel="Balansni to'ldirish"
        onCancel={() => setTopUpTarget(null)}
        onConfirm={handleTopUp}
      />

      {roleTarget && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-6">
          <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-xl max-w-sm w-full p-6 space-y-4">
            <h3 className="font-bold text-gray-900 dark:text-slate-100 text-lg">Rolni o'zgartirish</h3>
            <p className="text-sm text-gray-500 dark:text-slate-400">
              <strong className="text-gray-900 dark:text-slate-100">{roleTarget.fullName}</strong> hozirgi roli: {STAFF_ROLE_LABEL[roleTarget.role] || roleTarget.role}
            </p>
            <div>
              <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Yangi rol</label>
              <select
                value={newRole}
                onChange={(e) => setNewRole(e.target.value)}
                className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              >
                {STAFF_ROLES.map((r) => <option key={r} value={r}>{STAFF_ROLE_LABEL[r]}</option>)}
              </select>
            </div>
            <div className="flex gap-3 pt-2">
              <button
                onClick={() => setRoleTarget(null)}
                className="flex-1 py-2.5 bg-gray-50 hover:bg-gray-100 dark:bg-slate-700 dark:hover:bg-slate-600 text-gray-700 dark:text-slate-200 text-sm font-bold rounded-xl transition"
              >
                Bekor qilish
              </button>
              <button
                onClick={handleChangeRole}
                disabled={newRole === roleTarget.role}
                className="flex-1 py-2.5 bg-primary-600 hover:bg-primary-700 text-white text-sm font-bold rounded-xl transition disabled:opacity-40"
              >
                O'zgartirish
              </button>
            </div>
          </div>
        </div>
      )}

      {selectedUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm transition-opacity">
          <div className="relative w-full max-w-lg bg-white dark:bg-slate-800 rounded-3xl shadow-xl overflow-hidden animate-in fade-in zoom-in duration-200 border border-gray-100 dark:border-slate-700">
            {/* Header */}
            <div className="px-6 py-5 border-b border-gray-100 dark:border-slate-700 flex justify-between items-center bg-gray-50/50 dark:bg-slate-900/30">
              <div>
                <h3 className="text-lg font-bold text-gray-900 dark:text-slate-100">Foydalanuvchi ma'lumotlari</h3>
                <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">ID: {selectedUser.id}</p>
              </div>
              <button
                onClick={() => setSelectedUser(null)}
                className="p-2 rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 hover:text-gray-600 dark:hover:text-slate-200 transition"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Body */}
            <div className="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
              <div className="flex items-center gap-4 pb-4 border-b border-gray-100 dark:border-slate-700">
                <div className="w-16 h-16 rounded-full bg-primary-100 dark:bg-primary-950 text-primary-700 dark:text-primary-300 flex items-center justify-center text-xl font-extrabold shadow-inner overflow-hidden shrink-0">
                  {selectedUser.avatarUrl ? (
                    <img src={selectedUser.avatarUrl} alt="" className="w-full h-full object-cover" />
                  ) : (
                    selectedUser.fullName?.charAt(0).toUpperCase() || 'U'
                  )}
                </div>
                <div>
                  <h4 className="text-base font-bold text-gray-900 dark:text-slate-100">{selectedUser.fullName}</h4>
                  <div className="flex gap-2 mt-1 flex-wrap">
                    <Badge tone={selectedUser.isBlocked ? 'red' : 'green'}>
                      {selectedUser.isBlocked ? 'Bloklangan' : 'Faol'}
                    </Badge>
                    <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-gray-100 dark:bg-slate-700 text-gray-700 dark:text-slate-300">
                      {selectedUser.role}
                    </span>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-xs text-gray-400 dark:text-slate-500 font-medium">Telefon raqami</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 mt-0.5">{selectedUser.phoneNumber || 'Kiritilmagan'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400 dark:text-slate-500 font-medium">Elektron pochta</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 mt-0.5">{selectedUser.email || 'Kiritilmagan'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400 dark:text-slate-500 font-medium">KYC Vetting Holati</p>
                  <div className="mt-0.5">
                    <Badge tone={
                      selectedUser.kycStatus === 'APPROVED' ? 'green' : 
                      selectedUser.kycStatus === 'PENDING' ? 'yellow' : 'red'
                    }>
                      {selectedUser.kycStatus === 'APPROVED' ? 'Tasdiqlangan' :
                       selectedUser.kycStatus === 'PENDING' ? 'Kutilmoqda' : 'Tasdiqlanmagan'}
                    </Badge>
                  </div>
                </div>
                <div>
                  <p className="text-xs text-gray-400 dark:text-slate-500 font-medium">Jami loyihalari</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 mt-0.5">{selectedUser.totalProjects ?? 0} ta</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400 dark:text-slate-500 font-medium">Tizim reytingi</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 mt-0.5">{selectedUser.rating ? `⭐ ${selectedUser.rating}` : 'Yo\'q'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400 dark:text-slate-500 font-medium">Ro'yxatdan o'tgan sana</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 mt-0.5">
                    {selectedUser.createdAt ? new Date(selectedUser.createdAt).toLocaleDateString('uz-UZ', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric'
                    }) : 'Noma\'lum'}
                  </p>
                </div>
              </div>

              {selectedUser.kycStatus === 'REJECTED' && selectedUser.kycRejectedReason && (
                <div className="p-3 bg-red-50 dark:bg-red-950/20 border border-red-100 dark:border-red-900/30 rounded-2xl text-xs text-red-600 dark:text-red-400">
                  <span className="font-bold">KYC Rad etilish sababi:</span> {selectedUser.kycRejectedReason}
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="px-6 py-4 border-t border-gray-100 dark:border-slate-700 bg-gray-50/50 dark:bg-slate-900/30 flex justify-end gap-3">
              {(selectedUser.role === 'FARMER' || selectedUser.role === 'INVESTOR') && (
                <Button variant="primary" onClick={() => setTopUpTarget(selectedUser)}>Balansni to'ldirish</Button>
              )}
              <Button variant="secondary" onClick={() => setSelectedUser(null)}>Yopish</Button>
            </div>
          </div>
        </div>
      )}
    </Card>
  );
};

export default AccountsPanel;
