import React, { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  Settings, Users, Wallet, Landmark, ShieldCheck, FolderKanban,
  ClipboardList, Receipt, HeartPulse, Scale, KeyRound, FolderTree, Megaphone,
  LayoutDashboard, ArrowLeftRight, Send, Newspaper, FileText
} from 'lucide-react';
import { getPlatformSettings } from '../../api/superadmin.api';
import ErrorState from '../../components/ui/ErrorState';
import { SkeletonCard } from '../../components/ui/Skeleton';
import AdminStatsAndCharts from '../../components/admin/AdminStatsAndCharts';
import SettingsPanel from '../../components/superadmin/SettingsPanel';
import CreateAdminForm from '../../components/superadmin/CreateAdminForm';
import AuditLogPanel from '../../components/superadmin/AuditLogPanel';
import AccountsPanel from '../../components/superadmin/AccountsPanel';
import PermissionsPanel from '../../components/superadmin/PermissionsPanel';
import CategoriesPanel from '../../components/superadmin/CategoriesPanel';
import BannersPanel from '../../components/superadmin/BannersPanel';
import NewsPanel from '../../components/superadmin/NewsPanel';
import CoopModerationPanel from '../../components/superadmin/CoopModerationPanel';
import WithdrawalsTab from '../../components/admin/tabs/WithdrawalsTab';
import DepositRequestsTab from '../../components/admin/tabs/DepositRequestsTab';
import KycTab from '../../components/admin/tabs/KycTab';
import ProjectsTab from '../../components/admin/tabs/ProjectsTab';
import ReportsTab from '../../components/admin/tabs/ReportsTab';
import DisputesTab from '../../components/admin/tabs/DisputesTab';
import ExpensesTab from '../../components/admin/tabs/ExpensesTab';
import VetInspectionsTab from '../../components/admin/tabs/VetInspectionsTab';

import OverviewPanel from '../../components/superadmin/OverviewPanel';
import BroadcastPanel from '../../components/superadmin/BroadcastPanel';
import TransactionsPanel from '../../components/superadmin/TransactionsPanel';
import ContractsPanel from '../../components/superadmin/ContractsPanel';

// SuperAdmin is a strict superset of ADMIN/MODERATOR (see navLinks.js) - every
// operational queue they can reach lives here too, alongside SuperAdmin-only
// tools (settings, audit, staff accounts, permissions, categories), so nothing
// requires bouncing between two different dashboard URLs.
const TABS = [
  { key: 'overview', label: "Umumiy ko'rinish", icon: LayoutDashboard },
  { key: 'withdrawals', label: "Yechish so'rovlari", icon: Wallet },
  { key: 'deposits', label: "To'lov so'rovlari", icon: Landmark },
  { key: 'kyc', label: 'KYC Vetting', icon: ShieldCheck },
  { key: 'projects', label: 'Kutilayotgan loyihalar', icon: FolderKanban },
  { key: 'reports', label: 'Kutilayotgan hisobotlar', icon: ClipboardList },
  { key: 'expenses', label: 'Harajatlar', icon: Receipt },
  { key: 'vetInspections', label: 'Veterinar nazorati', icon: HeartPulse },
  {key: 'disputes', label: 'Shikoyatlar', icon: Scale},
  {key: 'transactions', label: 'Tranzaksiyalar', icon: ArrowLeftRight},
  {key: 'contracts', label: 'Shartnomalar', icon: FileText},
  {key: 'broadcast', label: 'Xabarnoma yuborish', icon: Send},
  { key: 'categories', label: 'Kategoriyalar', icon: FolderTree },
  { key: 'banners', label: 'Reklamalar', icon: Megaphone },
  { key: 'news', label: 'Yangiliklar', icon: Newspaper },
  { key: 'settings', label: 'Sozlamalar va audit', icon: Settings },
  { key: 'accounts', label: 'Hisoblarni boshqarish', icon: Users },
  { key: 'permissions', label: 'Ruxsatlar', icon: KeyRound },
];

const SuperAdminDashboard = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const activeTab = searchParams.get('tab') || 'overview';
  const setActiveTab = (tabKey) => setSearchParams({ tab: tabKey });
  const [refreshKey, setRefreshKey] = useState(0);
  const refreshAll = () => setRefreshKey((k) => k + 1);

  const [settings, setSettings] = useState([]);
  const [settingsLoading, setSettingsLoading] = useState(false);
  const [settingsError, setSettingsError] = useState(null);

  const fetchSettings = async () => {
    setSettingsLoading(true);
    setSettingsError(null);
    try {
      const res = await getPlatformSettings();
      setSettings(res.data.content || []);
    } catch (err) {
      setSettingsError("SuperAdmin ma'lumotlarini yuklashda xatolik yuz berdi");
    } finally {
      setSettingsLoading(false);
    }
  };

  useEffect(() => { if (activeTab === 'settings') fetchSettings(); }, [activeTab]);

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-slate-900 p-6 md:p-12">
      <div className="max-w-7xl mx-auto space-y-8">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-slate-100">Super Administrator paneli</h1>
            <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">Platformaning barcha operatsion navbatlari va boshqaruv vositalari</p>
          </div>
        </div>

        {activeTab === 'overview' && (
          <div className="space-y-8">
            <AdminStatsAndCharts refreshKey={refreshKey} />
            <OverviewPanel />
          </div>
        )}
        {activeTab === 'transactions' && <TransactionsPanel />}
        {activeTab === 'contracts' && <ContractsPanel />}
        {activeTab === 'broadcast' && <BroadcastPanel />}

        {['withdrawals', 'deposits', 'kyc', 'projects', 'reports', 'expenses', 'vetInspections', 'disputes'].includes(activeTab) && (
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

        {activeTab === 'permissions' && <PermissionsPanel />}
        {activeTab === 'categories' && <CategoriesPanel />}
        {activeTab === 'banners' && <BannersPanel />}
        {activeTab === 'news' && <NewsPanel />}
        {activeTab === 'coop' && <CoopModerationPanel />}

        {activeTab === 'settings' && (
          settingsError ? (
            <ErrorState message={settingsError} onRetry={fetchSettings} />
          ) : settingsLoading ? (
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
        )}

        {activeTab === 'accounts' && <AccountsPanel />}
      </div>
    </div>
  );
};

export default SuperAdminDashboard;
