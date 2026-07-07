import React, { useState, useEffect } from 'react';
import { Settings, Users } from 'lucide-react';
import { getPlatformSettings } from '../../api/superadmin.api';
import ErrorState from '../../components/ui/ErrorState';
import { SkeletonCard } from '../../components/ui/Skeleton';
import SettingsPanel from '../../components/superadmin/SettingsPanel';
import CreateAdminForm from '../../components/superadmin/CreateAdminForm';
import AuditLogPanel from '../../components/superadmin/AuditLogPanel';
import AccountsPanel from '../../components/superadmin/AccountsPanel';

const TABS = [
  { key: 'overview', label: 'Sozlamalar va audit', icon: Settings },
  { key: 'accounts', label: 'Hisoblarni boshqarish', icon: Users },
];

const SuperAdminDashboard = () => {
  const [activeTab, setActiveTab] = useState('overview');
  const [settings, setSettings] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    setLoading(true);
    setError(null);
    try {
      const settingsRes = await getPlatformSettings();
      setSettings(settingsRes.data.content || []);
    } catch (err) {
      setError("SuperAdmin ma'lumotlarini yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-slate-900 p-6 md:p-12">
      <div className="max-w-7xl mx-auto space-y-8">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-slate-100">Super Administrator paneli</h1>
            <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">Platforma sozlamalari, audit tizimi va ma'muriy akkountlar boshqaruvi</p>
          </div>
          <div className="flex bg-white dark:bg-slate-800 p-1 rounded-xl border border-gray-100 dark:border-slate-700 shadow-sm">
            {TABS.map((tab) => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={`flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold rounded-lg transition ${
                  activeTab === tab.key
                    ? 'bg-primary-600 text-white shadow-sm'
                    : 'text-gray-500 dark:text-slate-400 hover:text-primary-600 dark:hover:text-primary-400'
                }`}
              >
                <tab.icon size={14} />
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        {activeTab === 'overview' ? (
          error ? (
            <ErrorState message={error} onRetry={fetchSettings} />
          ) : loading ? (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              <SkeletonCard className="lg:col-span-1" />
              <SkeletonCard className="lg:col-span-2" />
            </div>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              <div className="lg:col-span-1 space-y-8">
                <SettingsPanel settings={settings} onChanged={fetchSettings} />
                <CreateAdminForm onCreated={fetchSettings} />
              </div>
              <div className="lg:col-span-2">
                <AuditLogPanel />
              </div>
            </div>
          )
        ) : (
          <AccountsPanel />
        )}
      </div>
    </div>
  );
};

export default SuperAdminDashboard;
