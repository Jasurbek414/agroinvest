import React, { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { LayoutDashboard, Wallet, ShieldCheck, FolderKanban, ClipboardList, Scale, Receipt, HeartPulse, Landmark } from 'lucide-react';
import AdminStatsAndCharts from '../../components/admin/AdminStatsAndCharts';
import WithdrawalsTab from '../../components/admin/tabs/WithdrawalsTab';
import DepositRequestsTab from '../../components/admin/tabs/DepositRequestsTab';
import KycTab from '../../components/admin/tabs/KycTab';
import ProjectsTab from '../../components/admin/tabs/ProjectsTab';
import ReportsTab from '../../components/admin/tabs/ReportsTab';
import DisputesTab from '../../components/admin/tabs/DisputesTab';
import ExpensesTab from '../../components/admin/tabs/ExpensesTab';
import VetInspectionsTab from '../../components/admin/tabs/VetInspectionsTab';

const TABS = [
  { key: 'overview', label: "Umumiy ko'rinish", icon: LayoutDashboard },
  { key: 'withdrawals', label: "Yechish so'rovlari", icon: Wallet },
  { key: 'deposits', label: "To'lov so'rovlari", icon: Landmark },
  { key: 'kyc', label: 'KYC Vetting', icon: ShieldCheck },
  { key: 'projects', label: 'Kutilayotgan loyihalar', icon: FolderKanban },
  { key: 'reports', label: 'Kutilayotgan hisobotlar', icon: ClipboardList },
  { key: 'expenses', label: 'Harajatlar', icon: Receipt },
  { key: 'vetInspections', label: 'Veterinar hujjatlari', icon: HeartPulse },
  { key: 'disputes', label: 'Shikoyatlar', icon: Scale },
];

const AdminDashboard = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const activeTab = searchParams.get('tab') || 'overview';
  const setActiveTab = (tabKey) => setSearchParams({ tab: tabKey });
  const [refreshKey, setRefreshKey] = useState(0);
  const refreshAll = () => setRefreshKey((k) => k + 1);

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-slate-900 p-6 md:p-12">
      <div className="max-w-7xl mx-auto space-y-8">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-slate-100">Tizim Administratori</h1>
            <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">Platformadagi faoliyat, moliyaviy so'rovlar va tasdiqlashlarni boshqaring</p>
          </div>
        </div>

        {activeTab === 'overview' && <AdminStatsAndCharts refreshKey={refreshKey} />}

        {activeTab !== 'overview' && (
          <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden">
            {activeTab === 'withdrawals' && <WithdrawalsTab onActionDone={refreshAll} />}
            {activeTab === 'deposits' && <DepositRequestsTab onActionDone={refreshAll} />}
            {activeTab === 'kyc' && <KycTab onActionDone={refreshAll} />}
            {activeTab === 'projects' && <ProjectsTab onActionDone={refreshAll} />}
            {activeTab === 'reports' && <ReportsTab />}
            {activeTab === 'expenses' && <ExpensesTab onActionDone={refreshAll} />}
            {activeTab === 'vetInspections' && <VetInspectionsTab onActionDone={refreshAll} />}
            {activeTab === 'disputes' && <DisputesTab />}
          </div>
        )}
      </div>
    </div>
  );
};

export default AdminDashboard;
