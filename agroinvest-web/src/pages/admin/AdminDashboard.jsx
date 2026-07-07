import React, { useEffect, useState } from 'react';
import { Wallet, ShieldCheck, FolderKanban, ClipboardList, Scale } from 'lucide-react';
import { getAdminDashboardStats, getAssetTypeBreakdown, getProjectStatusBreakdown } from '../../api/admin.api';
import AdminStatsBar from '../../components/admin/AdminStatsBar';
import WithdrawalsTab from '../../components/admin/tabs/WithdrawalsTab';
import KycTab from '../../components/admin/tabs/KycTab';
import ProjectsTab from '../../components/admin/tabs/ProjectsTab';
import ReportsTab from '../../components/admin/tabs/ReportsTab';
import DisputesTab from '../../components/admin/tabs/DisputesTab';
import Card from '../../components/ui/Card';
import { SkeletonCard } from '../../components/ui/Skeleton';
import { useToast } from '../../components/ui/ToastProvider';
import AssetTypeBarChart from '../../components/admin/charts/AssetTypeBarChart';
import ProjectStatusPieChart from '../../components/admin/charts/ProjectStatusPieChart';

const TABS = [
  { key: 'withdrawals', label: "Yechish so'rovlari", icon: Wallet },
  { key: 'kyc', label: 'KYC Vetting', icon: ShieldCheck },
  { key: 'projects', label: 'Kutilayotgan loyihalar', icon: FolderKanban },
  { key: 'reports', label: 'Kutilayotgan hisobotlar', icon: ClipboardList },
  { key: 'disputes', label: 'Shikoyatlar', icon: Scale },
];

const AdminDashboard = () => {
  const [activeTab, setActiveTab] = useState('withdrawals');
  const [stats, setStats] = useState(null);
  const [assetTypeData, setAssetTypeData] = useState(null);
  const [statusData, setStatusData] = useState(null);
  const [chartsLoading, setChartsLoading] = useState(true);
  const { showToast } = useToast();

  const fetchStats = async () => {
    try {
      const res = await getAdminDashboardStats();
      setStats(res.data);
    } catch (err) {
      // Previously swallowed with console.error only - the admin had no way to
      // know the dashboard numbers might be stale/missing.
      showToast("Statistikani yuklashda xatolik yuz berdi", 'error');
    }
  };

  const fetchCharts = async () => {
    setChartsLoading(true);
    try {
      const [assetRes, statusRes] = await Promise.all([getAssetTypeBreakdown(), getProjectStatusBreakdown()]);
      setAssetTypeData(assetRes.data);
      setStatusData(statusRes.data);
    } catch (err) {
      showToast('Grafik ma\'lumotlarini yuklashda xatolik yuz berdi', 'error');
    } finally {
      setChartsLoading(false);
    }
  };

  useEffect(() => { fetchStats(); fetchCharts(); }, []);

  const refreshAll = () => { fetchStats(); fetchCharts(); };

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-slate-900 p-6 md:p-12">
      <div className="max-w-7xl mx-auto space-y-8">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-slate-100">Tizim Administratori</h1>
            <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">Platformadagi faoliyat, moliyaviy so'rovlar va tasdiqlashlarni boshqaring</p>
          </div>

          <div className="flex bg-white dark:bg-slate-800 p-1 rounded-xl border border-gray-100 dark:border-slate-700 shadow-sm flex-wrap">
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

        <AdminStatsBar stats={stats} />

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <h2 className="text-sm font-bold text-gray-900 dark:text-slate-100 mb-3">Aktiv turlari bo'yicha loyihalar</h2>
            {chartsLoading ? <SkeletonCard className="border-0 shadow-none p-0" /> : <AssetTypeBarChart data={assetTypeData} />}
          </Card>
          <Card>
            <h2 className="text-sm font-bold text-gray-900 dark:text-slate-100 mb-3">Loyihalar holati taqsimoti</h2>
            {chartsLoading ? <SkeletonCard className="border-0 shadow-none p-0" /> : <ProjectStatusPieChart data={statusData} />}
          </Card>
        </div>

        <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden">
          {activeTab === 'withdrawals' && <WithdrawalsTab onActionDone={refreshAll} />}
          {activeTab === 'kyc' && <KycTab onActionDone={refreshAll} />}
          {activeTab === 'projects' && <ProjectsTab onActionDone={refreshAll} />}
          {activeTab === 'reports' && <ReportsTab />}
          {activeTab === 'disputes' && <DisputesTab />}
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;
