import React, { useEffect, useState } from 'react';
import { FileSearch } from 'lucide-react';
import { getUsers, verifyUserKyc } from '../../../api/admin.api';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';
import { useDebounce } from '../../../hooks/useDebounce';
import KycDocumentModal from '../KycDocumentModal';

const ROLE_OPTIONS = [
  { value: '', label: 'Barcha rollar' },
  { value: 'FARMER', label: 'Fermer' },
  { value: 'INVESTOR', label: 'Investor' },
];

const KycTab = ({ onActionDone }) => {
  const [users, setUsers] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const [viewTarget, setViewTarget] = useState(null);
  const [search, setSearch] = useState('');
  const [role, setRole] = useState('');
  const debouncedSearch = useDebounce(search, 350);
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getUsers(page, 20, { role: role || undefined, q: debouncedSearch || undefined });
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
      showToast('KYC holati yangilandi');
      fetchData(pageInfo.pageNumber);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  return (
    <div>
      <div className="p-6 border-b border-gray-100 dark:border-slate-700">
        <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">KYC Vetting (Fermer va Investorlar)</h2>
      </div>

      <DataTable
        loading={loading}
        error={error}
        onRetry={() => fetchData(pageInfo.pageNumber)}
        rows={users}
        emptyTitle="Foydalanuvchilar topilmadi"
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
            {ROLE_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        }
        page={{ ...pageInfo, onPageChange: fetchData }}
        columns={[
          { key: 'fullName', header: 'Ism', render: (u) => <span className="font-semibold">{u.fullName}</span> },
          { key: 'phoneNumber', header: 'Telefon', render: (u) => <span className="text-xs font-mono text-gray-400">{u.phoneNumber}</span> },
          { key: 'role', header: 'Rol', render: (u) => <span className="text-xs font-bold text-gray-500 dark:text-slate-400">{u.role}</span> },
          { key: 'kycStatus', header: 'KYC Holati', render: (u) => <Badge status={u.kycStatus} /> },
          {
            key: 'actions',
            header: 'Amallar',
            align: 'right',
            render: (u) => (
              <div className="flex justify-end gap-2">
                <Button variant="secondary" size="sm" icon={FileSearch} onClick={() => setViewTarget(u)}>Ko'rish</Button>
                {u.kycStatus === 'PENDING' && (
                  <>
                    <Button variant="danger" size="sm" onClick={() => setRejectTarget(u.id)}>Rad etish</Button>
                    <Button variant="primary" size="sm" onClick={() => runAction(u.id, 'VERIFIED', null)}>Tasdiqlash</Button>
                  </>
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
            <div className="flex gap-2 pt-1">
              <Button variant="secondary" size="sm" icon={FileSearch} onClick={() => setViewTarget(u)}>Ko'rish</Button>
              {u.kycStatus === 'PENDING' && (
                <>
                  <Button variant="danger" size="sm" onClick={() => setRejectTarget(u.id)}>Rad etish</Button>
                  <Button variant="primary" size="sm" onClick={() => runAction(u.id, 'VERIFIED', null)}>Tasdiqlash</Button>
                </>
              )}
            </div>
          </div>
        )}
      />

      <PromptDialog
        open={!!rejectTarget}
        title="KYC'ni rad etish"
        label="Rad etish sababi"
        required
        tone="danger"
        confirmLabel="Rad etish"
        onCancel={() => setRejectTarget(null)}
        onConfirm={(reason) => { runAction(rejectTarget, 'REJECTED', reason); setRejectTarget(null); }}
      />

      <KycDocumentModal user={viewTarget} onClose={() => setViewTarget(null)} />
    </div>
  );
};

export default KycTab;
