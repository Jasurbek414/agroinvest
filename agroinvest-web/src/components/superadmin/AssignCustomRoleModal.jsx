import React, { useEffect, useState } from 'react';
import { getUsers } from '../../api/admin.api';
import { assignCustomRoleToUser } from '../../api/permissions.api';
import { useDebounce } from '../../hooks/useDebounce';
import { useToast } from '../ui/ToastProvider';

// Phone/name search-and-pick, since assigning a custom role needs a userId and
// nobody has UUIDs memorized - mirrors the search pattern used by KycTab/AccountsPanel.
const AssignCustomRoleModal = ({ customRole, onClose, onAssigned }) => {
  const [search, setSearch] = useState('');
  const [results, setResults] = useState([]);
  const [assigning, setAssigning] = useState(null);
  const debouncedSearch = useDebounce(search, 350);
  const { showToast } = useToast();

  useEffect(() => {
    if (!debouncedSearch) { setResults([]); return; }
    getUsers(0, 10, { q: debouncedSearch })
      .then((res) => setResults(res.data.content || []))
      .catch(() => setResults([]));
  }, [debouncedSearch]);

  const handleAssign = async (userId) => {
    setAssigning(userId);
    try {
      await assignCustomRoleToUser(customRole.id, userId);
      showToast('Maxsus rol biriktirildi');
      onAssigned?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    } finally {
      setAssigning(null);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-6">
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-xl max-w-sm w-full p-6 space-y-4">
        <div className="flex justify-between items-center">
          <h3 className="font-bold text-gray-900 dark:text-slate-100 text-lg">"{customRole.name}" rolini biriktirish</h3>
          <button onClick={onClose} aria-label="Yopish" className="text-gray-400 hover:text-gray-600 text-lg">&times;</button>
        </div>
        <input
          type="text"
          autoFocus
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Ism yoki telefon bo'yicha qidirish..."
          className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
        />
        <div className="max-h-64 overflow-y-auto divide-y divide-gray-100 dark:divide-slate-700">
          {results.map((u) => (
            <div key={u.id} className="flex items-center justify-between py-2">
              <div>
                <p className="text-sm font-semibold text-gray-900 dark:text-slate-100">{u.fullName}</p>
                <p className="text-xs font-mono text-gray-400">{u.phoneNumber} · {u.role}</p>
              </div>
              <button
                onClick={() => handleAssign(u.id)}
                disabled={assigning === u.id}
                className="px-3 py-1.5 rounded-lg text-xs font-bold bg-primary-600 hover:bg-primary-700 text-white transition disabled:opacity-40"
              >
                Biriktirish
              </button>
            </div>
          ))}
          {debouncedSearch && results.length === 0 && (
            <p className="text-xs text-gray-400 py-3 text-center">Foydalanuvchi topilmadi</p>
          )}
        </div>
      </div>
    </div>
  );
};

export default AssignCustomRoleModal;
