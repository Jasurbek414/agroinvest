import React, { useEffect, useState } from 'react';
import { getUsers, verifyUserKyc } from '../../../api/admin.api';
import Badge from '../../ui/Badge';
import EmptyState from '../../ui/EmptyState';
import ErrorState from '../../ui/ErrorState';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';

const KycTab = ({ onActionDone }) => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const { showToast } = useToast();

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await getUsers();
      setUsers(res.data.content || []);
    } catch (err) {
      setError("Foydalanuvchilarni yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);

  const runAction = async (id, status, reason) => {
    try {
      await verifyUserKyc(id, status, reason);
      showToast('KYC holati yangilandi');
      fetchData();
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  if (loading) return <p className="p-8 text-center text-sm text-gray-400 animate-pulse">Yuklanmoqda...</p>;
  if (error) return <ErrorState message={error} onRetry={fetchData} />;

  return (
    <div>
      <div className="p-6 border-b border-gray-100">
        <h2 className="text-base font-bold text-gray-900">KYC Vetting (Fermer va Investorlar)</h2>
      </div>
      {users.length === 0 ? (
        <EmptyState title="Foydalanuvchilar topilmadi" />
      ) : (
        <div className="overflow-x-auto text-sm text-left">
          <table className="w-full">
            <thead>
              <tr className="bg-gray-50 text-gray-500 uppercase text-[10px] font-bold">
                <th className="p-4">Ism</th>
                <th className="p-4">Telefon</th>
                <th className="p-4">Rol</th>
                <th className="p-4">KYC Holati</th>
                <th className="p-4 text-right">Amallar</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {users.map((u) => (
                <tr key={u.id} className="hover:bg-gray-50/50">
                  <td className="p-4 font-semibold">{u.fullName}</td>
                  <td className="p-4 text-xs font-mono text-gray-400">{u.phoneNumber}</td>
                  <td className="p-4 text-xs font-bold text-gray-500">{u.role}</td>
                  <td className="p-4"><Badge status={u.kycStatus} /></td>
                  <td className="p-4 text-right">
                    {u.kycStatus === 'PENDING' && (
                      <div className="flex justify-end gap-2">
                        <button onClick={() => setRejectTarget(u.id)} className="px-2 py-1 bg-red-50 text-red-700 rounded-lg text-xs font-bold">Rad etish</button>
                        <button onClick={() => runAction(u.id, 'VERIFIED', null)} className="px-2 py-1 bg-green-50 text-green-700 rounded-lg text-xs font-bold">Tasdiqlash</button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

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
    </div>
  );
};

export default KycTab;
