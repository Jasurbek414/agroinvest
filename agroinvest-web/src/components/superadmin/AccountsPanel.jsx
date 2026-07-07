import React, { useEffect, useState } from 'react';
import { getAccounts, blockAccount } from '../../api/superadmin.api';
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
];

// Lists staff accounts only (admin/moderator/verifier/superadmin) via the
// dedicated GET /superadmin/accounts endpoint, and actually calls
// blockAccount/superadmin.api - previously this reused the generic user list
// and a different (dead) block action.
const AccountsPanel = () => {
  const [users, setUsers] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [blockTarget, setBlockTarget] = useState(null);
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

  return (
    <Card padded={false} className="overflow-hidden">
      <div className="p-6 border-b border-gray-100 dark:border-slate-700">
        <h2 className="text-lg font-bold text-gray-900 dark:text-slate-100">Ma'muriy hisoblar</h2>
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
            render: (u) => u.isBlocked ? (
              <Button variant="primary" size="sm" onClick={() => handleUnblock(u.id)}>Blokdan chiqarish</Button>
            ) : (
              <Button variant="danger" size="sm" onClick={() => setBlockTarget(u.id)}>Bloklash</Button>
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
            {u.isBlocked ? (
              <Button variant="primary" size="sm" onClick={() => handleUnblock(u.id)}>Blokdan chiqarish</Button>
            ) : (
              <Button variant="danger" size="sm" onClick={() => setBlockTarget(u.id)}>Bloklash</Button>
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
    </Card>
  );
};

export default AccountsPanel;
