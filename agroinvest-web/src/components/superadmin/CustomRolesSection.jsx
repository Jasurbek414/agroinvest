import React, { useEffect, useState } from 'react';
import { UserPlus, Plus } from 'lucide-react';
import { listCustomRoles, createCustomRole, addPermissionToCustomRole } from '../../api/permissions.api';
import Button from '../ui/Button';
import { useToast } from '../ui/ToastProvider';
import AssignCustomRoleModal from './AssignCustomRoleModal';

const CustomRolesSection = ({ permissions }) => {
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [creating, setCreating] = useState(false);
  const [addPermissionTarget, setAddPermissionTarget] = useState(null); // customRoleId
  const [selectedPermission, setSelectedPermission] = useState('');
  const [assignTarget, setAssignTarget] = useState(null); // customRole object
  const { showToast } = useToast();

  const fetchRoles = async () => {
    setLoading(true);
    try {
      const res = await listCustomRoles();
      setRoles(res.data || []);
    } catch (err) {
      showToast('Maxsus rollarni yuklashda xatolik yuz berdi', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchRoles(); }, []);

  const handleCreate = async (e) => {
    e.preventDefault();
    if (!name.trim()) return;
    setCreating(true);
    try {
      await createCustomRole(name.trim(), description.trim() || null);
      showToast('Maxsus rol yaratildi');
      setName('');
      setDescription('');
      fetchRoles();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    } finally {
      setCreating(false);
    }
  };

  const handleAddPermission = async () => {
    if (!selectedPermission) return;
    try {
      await addPermissionToCustomRole(addPermissionTarget, selectedPermission);
      showToast('Ruxsat qo\'shildi');
      setAddPermissionTarget(null);
      setSelectedPermission('');
      fetchRoles();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  return (
    <div className="space-y-4">
      <form onSubmit={handleCreate} className="flex flex-col sm:flex-row gap-2">
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Rol nomi (masalan: Hudud koordinatori)"
          className="flex-1 px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
        />
        <input
          type="text"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Tavsif (ixtiyoriy)"
          className="flex-1 px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
        />
        <Button type="submit" variant="primary" size="md" icon={Plus} disabled={creating}>Yangi rol</Button>
      </form>

      {loading ? (
        <p className="text-sm text-gray-400 text-center py-6">Yuklanmoqda...</p>
      ) : roles.length === 0 ? (
        <p className="text-sm text-gray-400 text-center py-6">Maxsus rollar yo'q</p>
      ) : (
        <div className="space-y-3">
          {roles.map((role) => (
            <div key={role.id} className="p-4 rounded-xl border border-gray-100 dark:border-slate-700">
              <div className="flex items-start justify-between gap-3 flex-wrap">
                <div>
                  <p className="font-bold text-gray-900 dark:text-slate-100">{role.name}</p>
                  {role.description && <p className="text-xs text-gray-500 dark:text-slate-400">{role.description}</p>}
                </div>
                <div className="flex gap-2">
                  <Button variant="secondary" size="sm" onClick={() => setAddPermissionTarget(role.id)}>Ruxsat qo'shish</Button>
                  <Button variant="primary" size="sm" icon={UserPlus} onClick={() => setAssignTarget(role)}>Biriktirish</Button>
                </div>
              </div>

              {addPermissionTarget === role.id && (
                <div className="flex gap-2 mt-3">
                  <select
                    value={selectedPermission}
                    onChange={(e) => setSelectedPermission(e.target.value)}
                    className="flex-1 px-3 py-2 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-xs outline-none focus:ring-1 focus:ring-primary-500"
                  >
                    <option value="">Ruxsat tanlang</option>
                    {permissions.map((p) => (
                      <option key={p.code} value={p.code}>{p.code}</option>
                    ))}
                  </select>
                  <Button variant="primary" size="sm" onClick={handleAddPermission}>Qo'shish</Button>
                  <Button variant="secondary" size="sm" onClick={() => { setAddPermissionTarget(null); setSelectedPermission(''); }}>Bekor</Button>
                </div>
              )}

              {role.permissionCodes?.length > 0 && (
                <div className="flex flex-wrap gap-1.5 mt-3">
                  {role.permissionCodes.map((code) => (
                    <span key={code} className="px-2 py-0.5 rounded-full text-[10px] font-mono font-bold bg-primary-50 dark:bg-primary-950 text-primary-700 dark:text-primary-300">
                      {code}
                    </span>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {assignTarget && (
        <AssignCustomRoleModal
          customRole={assignTarget}
          onClose={() => setAssignTarget(null)}
          onAssigned={() => setAssignTarget(null)}
        />
      )}
    </div>
  );
};

export default CustomRolesSection;
