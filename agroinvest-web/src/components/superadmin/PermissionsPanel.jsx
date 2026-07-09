import React, { useEffect, useState } from 'react';
import { listPermissions } from '../../api/permissions.api';
import Card from '../ui/Card';
import { useToast } from '../ui/ToastProvider';
import PermissionMatrix from './PermissionMatrix';
import CustomRolesSection from './CustomRolesSection';

// SuperAdmin's dynamic role/permission control surface (PLATFORM_ROADMAP.md
// Phase 2): the backend (PermissionController, Phase 0.1) has been ready since
// before this UI existed - this just exposes it.
const PermissionsPanel = () => {
  const [permissions, setPermissions] = useState([]);
  const [loading, setLoading] = useState(true);
  const { showToast } = useToast();

  const fetchPermissions = async () => {
    setLoading(true);
    try {
      const res = await listPermissions();
      setPermissions(res.data || []);
    } catch (err) {
      showToast('Ruxsatlar ro\'yxatini yuklashda xatolik yuz berdi', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchPermissions(); }, []);

  return (
    <div className="space-y-6 p-6">
      <Card>
        <h2 className="text-base font-bold text-gray-900 dark:text-slate-100 mb-1">Ruxsatlar</h2>
        <p className="text-xs text-gray-500 dark:text-slate-400 mb-4">
          Har bir bazaviy rolga qaysi ruxsatlar berilganini belgilang
        </p>
        {loading ? (
          <p className="text-sm text-gray-400 text-center py-6">Yuklanmoqda...</p>
        ) : (
          <PermissionMatrix permissions={permissions} onPermissionCreated={fetchPermissions} />
        )}
      </Card>

      <Card>
        <h2 className="text-base font-bold text-gray-900 dark:text-slate-100 mb-1">Maxsus rollar</h2>
        <p className="text-xs text-gray-500 dark:text-slate-400 mb-4">
          Bazaviy 6 rol ustiga qo'shimcha ruxsatlar to'plamini istalgan foydalanuvchiga biriktiring
        </p>
        <CustomRolesSection permissions={permissions} />
      </Card>
    </div>
  );
};

export default PermissionsPanel;
