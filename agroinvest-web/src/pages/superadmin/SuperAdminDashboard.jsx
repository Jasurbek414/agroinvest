import React, { useState, useEffect } from 'react';
import { getPlatformSettings, getAuditLogs } from '../../api/superadmin.api';
import ErrorState from '../../components/ui/ErrorState';
import SettingsPanel from '../../components/superadmin/SettingsPanel';
import CreateAdminForm from '../../components/superadmin/CreateAdminForm';
import AuditLogPanel from '../../components/superadmin/AuditLogPanel';
import AccountsPanel from '../../components/superadmin/AccountsPanel';

const TABS = [
  { key: 'overview', label: 'Sozlamalar va audit' },
  { key: 'accounts', label: 'Hisoblarni boshqarish' },
];

const SuperAdminDashboard = () => {
  const [activeTab, setActiveTab] = useState('overview');
  const [settings, setSettings] = useState([]);
  const [auditLogs, setAuditLogs] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchSuperAdminData();
  }, []);

  const fetchSuperAdminData = async () => {
    setLoading(true);
    setError(null);
    try {
      const settingsRes = await getPlatformSettings();
      setSettings(settingsRes.data.content || []);

      const logsRes = await getAuditLogs();
      setAuditLogs(logsRes.data.content || []);
    } catch (err) {
      setError("SuperAdmin ma'lumotlarini yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50/50 p-6 md:p-12">
      <div className="max-w-5xl mx-auto space-y-8">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Super Administrator paneli</h1>
            <p className="text-sm text-gray-500 mt-1">Platforma sozlamalari, audit tizimi va ma'muriy akkountlar boshqaruvi</p>
          </div>
          <div className="flex bg-white p-1 rounded-xl border border-gray-100 shadow-sm">
            {TABS.map((tab) => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={`px-3 py-1.5 text-xs font-bold rounded-lg transition ${
                  activeTab === tab.key ? 'bg-green-600 text-white shadow-sm' : 'text-gray-500 hover:text-green-600'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        {error ? (
          <ErrorState message={error} onRetry={fetchSuperAdminData} />
        ) : loading ? (
          <p className="text-gray-500 animate-pulse text-center">Yuklanmoqda...</p>
        ) : activeTab === 'overview' ? (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-1 space-y-8">
              <SettingsPanel settings={settings} onChanged={fetchSuperAdminData} />
              <CreateAdminForm onCreated={fetchSuperAdminData} />
            </div>
            <div className="lg:col-span-2">
              <AuditLogPanel auditLogs={auditLogs} />
            </div>
          </div>
        ) : (
          <AccountsPanel />
        )}
      </div>
    </div>
  );
};

export default SuperAdminDashboard;
