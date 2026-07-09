import React, { useEffect, useState } from 'react';
import { getAdminDashboardStats, getAssetTypeBreakdown, getProjectStatusBreakdown } from '../../api/admin.api';
import AdminStatsBar from './AdminStatsBar';
import Card from '../ui/Card';
import { SkeletonCard } from '../ui/Skeleton';
import { useToast } from '../ui/ToastProvider';
import AssetTypeBarChart from './charts/AssetTypeBarChart';
import ProjectStatusPieChart from './charts/ProjectStatusPieChart';

// KPI bar + charts shared by AdminDashboard and SuperAdminDashboard (previously
// duplicated in both) - pass a `refreshKey` that changes to force a refetch
// (e.g. after an admin action elsewhere on the page).
const AdminStatsAndCharts = ({ refreshKey }) => {
  const [stats, setStats] = useState(null);
  const [assetTypeData, setAssetTypeData] = useState(null);
  const [statusData, setStatusData] = useState(null);
  const [chartsLoading, setChartsLoading] = useState(true);
  const { showToast } = useToast();

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const res = await getAdminDashboardStats();
        setStats(res.data);
      } catch (err) {
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

    fetchStats();
    fetchCharts();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [refreshKey]);

  return (
    <>
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
    </>
  );
};

export default AdminStatsAndCharts;
