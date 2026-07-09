import React, { useEffect, useState } from 'react';
import { Plus } from 'lucide-react';
import {
  getRolePermissions,
  grantToRole,
  revokeFromRole,
  createPermission,
} from '../../api/permissions.api';
import Button from '../ui/Button';
import { useToast } from '../ui/ToastProvider';

const ROLES = ['SUPERADMIN', 'ADMIN', 'MODERATOR', 'VERIFIER', 'INVESTOR', 'FARMER'];

// Rol x ruxsat matritsasi. role_permissions'ni o'qish uchun bulk endpoint yo'q
// (faqat grant/revoke bor), shuning uchun har bir rol uchun alohida so'rov
// yuboriladi - 6 ta rol bo'lgani uchun bu yetarlicha arzon.
const PermissionMatrix = ({ permissions, onPermissionCreated }) => {
  const [grants, setGrants] = useState({});
  const [loading, setLoading] = useState(true);
  const [newCode, setNewCode] = useState('');
  const [newDescription, setNewDescription] = useState('');
  const [creating, setCreating] = useState(false);
  const { showToast } = useToast();

  const fetchGrants = async () => {
    setLoading(true);
    try {
      const results = await Promise.all(ROLES.map((role) => getRolePermissions(role)));
      const next = {};
      ROLES.forEach((role, i) => { next[role] = new Set(results[i].data || []); });
      setGrants(next);
    } catch (err) {
      showToast("Ruxsatlar holatini yuklashda xatolik yuz berdi", 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchGrants(); }, [permissions]);

  const toggle = async (role, code) => {
    const isGranted = grants[role]?.has(code);
    // Optimistic update - matritsa 36+ katakli bo'lishi mumkin, har bir bosishda
    // to'liq qayta yuklash sekin va sakrovchi ko'rinadi.
    setGrants((prev) => {
      const next = new Set(prev[role]);
      isGranted ? next.delete(code) : next.add(code);
      return { ...prev, [role]: next };
    });
    try {
      if (isGranted) {
        await revokeFromRole(role, code);
      } else {
        await grantToRole(role, code);
      }
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
      fetchGrants(); // rollback to the real server state
    }
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    if (!newCode.trim() || !newDescription.trim()) return;
    setCreating(true);
    try {
      await createPermission(newCode.trim(), newDescription.trim());
      showToast('Yangi ruxsat yaratildi');
      setNewCode('');
      setNewDescription('');
      onPermissionCreated?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    } finally {
      setCreating(false);
    }
  };

  return (
    <div className="space-y-4">
      <form onSubmit={handleCreate} className="flex flex-col sm:flex-row gap-2">
        <input
          type="text"
          value={newCode}
          onChange={(e) => setNewCode(e.target.value)}
          placeholder="Kod (masalan: project.approve)"
          className="flex-1 px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
        />
        <input
          type="text"
          value={newDescription}
          onChange={(e) => setNewDescription(e.target.value)}
          placeholder="Tavsif"
          className="flex-1 px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
        />
        <Button type="submit" variant="primary" size="md" icon={Plus} disabled={creating}>Yangi ruxsat</Button>
      </form>

      <div className="overflow-x-auto border border-gray-100 dark:border-slate-700 rounded-xl">
        <table className="w-full text-sm text-left">
          <thead>
            <tr className="bg-gray-50 dark:bg-slate-900/60 text-gray-500 dark:text-slate-400 uppercase text-[10px] font-bold">
              <th className="p-3 min-w-[180px]">Ruxsat</th>
              {ROLES.map((role) => (
                <th key={role} className="p-3 text-center whitespace-nowrap">{role}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-slate-700">
            {permissions.map((perm) => (
              <tr key={perm.code} className="text-gray-800 dark:text-slate-200">
                <td className="p-3">
                  <p className="font-mono text-xs font-bold">{perm.code}</p>
                  <p className="text-xs text-gray-500 dark:text-slate-400">{perm.description}</p>
                </td>
                {ROLES.map((role) => (
                  <td key={role} className="p-3 text-center">
                    <input
                      type="checkbox"
                      disabled={loading}
                      checked={grants[role]?.has(perm.code) || false}
                      onChange={() => toggle(role, perm.code)}
                      className="rounded border-gray-300 dark:border-slate-600"
                    />
                  </td>
                ))}
              </tr>
            ))}
            {permissions.length === 0 && (
              <tr>
                <td colSpan={ROLES.length + 1} className="p-6 text-center text-gray-400 text-sm">
                  Ruxsatlar topilmadi
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default PermissionMatrix;
