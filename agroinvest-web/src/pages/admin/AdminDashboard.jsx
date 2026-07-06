import React, { useEffect, useState } from 'react';
import { getAdminDashboardStats } from '../../api/admin.api';
import AdminStatsBar from '../../components/admin/AdminStatsBar';
import WithdrawalsTab from '../../components/admin/tabs/WithdrawalsTab';
import KycTab from '../../components/admin/tabs/KycTab';
import ProjectsTab from '../../components/admin/tabs/ProjectsTab';
import ReportsTab from '../../components/admin/tabs/ReportsTab';
import DisputesTab from '../../components/admin/tabs/DisputesTab';

const TABS = [
  { key: 'withdrawals', label: "Yechish so'rovlari" },
  { key: 'kyc', label: 'KYC Vetting' },
  { key: 'projects', label: 'Kutilayotgan loyihalar' },
  { key: 'reports', label: 'Kutilayotgan hisobotlar' },
  { key: 'disputes', label: 'Shikoyatlar' },
];

const AdminDashboard = () => {
  const [activeTab, setActiveTab] = useState('withdrawals');
  const [stats, setStats] = useState(null);

  const fetchStats = async () => {
    try {
      const res = await getAdminDashboardStats();
      setStats(res.data);
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => { fetchStats(); }, []);

  return (
    <div className="min-h-screen bg-gray-50/50 p-6 md:p-12">
      <div className="max-w-5xl mx-auto space-y-8">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Tizim Administratori</h1>
            <p className="text-sm text-gray-500 mt-1">Platformadagi faoliyat, moliyaviy so'rovlar va tasdiqlashlarni boshqaring</p>
          </div>

          <div className="flex bg-white p-1 rounded-xl border border-gray-100 shadow-sm flex-wrap">
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

        <AdminStatsBar stats={stats} />

        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          {activeTab === 'withdrawals' && <WithdrawalsTab onActionDone={fetchStats} />}
          {activeTab === 'kyc' && <KycTab onActionDone={fetchStats} />}
          {activeTab === 'projects' && <ProjectsTab onActionDone={fetchStats} />}
          {activeTab === 'reports' && <ReportsTab />}
          {activeTab === 'disputes' && <DisputesTab />}
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;
