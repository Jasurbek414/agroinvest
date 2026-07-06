import React, { useEffect, useState } from 'react';
import { getUsers, blockUser } from '../../api/admin.api';
import Card from '../ui/Card';
import Badge from '../ui/Badge';
import EmptyState from '../ui/EmptyState';
import ErrorState from '../ui/ErrorState';
import PromptDialog from '../ui/PromptDialog';
import { useToast } from '../ui/ToastProvider';

// Wires up the previously-dead `blockAccount`/`blockUser` action: lists every account
// and lets SuperAdmin/Admin suspend or reinstate one, using the already-existing
// generic PATCH /users/{id}/block endpoint (no superadmin-only accounts list endpoint
// exists yet, so this reuses the same user list the KYC tab already fetches).
const AccountsPanel = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [blockTarget, setBlockTarget] = useState(null);
  const { showToast } = useToast();

  const fetchUsers = async () => {
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

  useEffect(() => { fetchUsers(); }, []);

  const handleUnblock = async (id) => {
    try {
      await blockUser(id, false, null);
      showToast('Hisob blokdan chiqarildi');
      fetchUsers();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const handleBlock = async (reason) => {
    try {
      await blockUser(blockTarget, true, reason);
      showToast('Hisob bloklandi');
      setBlockTarget(null);
      fetchUsers();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  if (loading) return <p className="text-gray-500 animate-pulse text-center">Yuklanmoqda...</p>;
  if (error) return <ErrorState message={error} onRetry={fetchUsers} />;

  return (
    <Card padded={false} className="overflow-hidden">
      <div className="p-6 border-b border-gray-100">
        <h2 className="text-lg font-bold text-gray-900">Hisoblarni boshqarish</h2>
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
                <th className="p-4">Holat</th>
                <th className="p-4 text-right">Amallar</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {users.map((u) => (
                <tr key={u.id} className="hover:bg-gray-50/50">
                  <td className="p-4 font-semibold">{u.fullName}</td>
                  <td className="p-4 text-xs font-mono text-gray-400">{u.phoneNumber}</td>
                  <td className="p-4 text-xs font-bold text-gray-500">{u.role}</td>
                  <td className="p-4">
                    <Badge tone={u.isBlocked ? 'red' : 'green'}>{u.isBlocked ? 'Bloklangan' : 'Faol'}</Badge>
                  </td>
                  <td className="p-4 text-right">
                    {u.isBlocked ? (
                      <button onClick={() => handleUnblock(u.id)} className="px-2 py-1 bg-green-50 text-green-700 rounded-lg text-xs font-bold">
                        Blokdan chiqarish
                      </button>
                    ) : (
                      <button onClick={() => setBlockTarget(u.id)} className="px-2 py-1 bg-red-50 text-red-700 rounded-lg text-xs font-bold">
                        Bloklash
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

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
