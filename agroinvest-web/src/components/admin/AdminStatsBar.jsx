import React from 'react';
import { Users, Sprout, FileCheck2, Clock3, Receipt, HeartPulse } from 'lucide-react';
import StatCard from '../ui/StatCard';
import { formatAmount } from '../../utils/format';

const AdminStatsBar = ({ stats }) => (
  <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
    <StatCard label="Foydalanuvchilar" value={stats?.totalUsers ?? 0} icon={Users} />
    <StatCard label="Faol loyihalar" value={stats?.activeProjects ?? 0} icon={Sprout} />
    <StatCard label="KYC kutilmoqda" value={stats?.pendingVetting ?? 0} icon={Clock3} />
    <StatCard label="Loyiha kutilmoqda" value={stats?.pendingProjects ?? 0} icon={FileCheck2} />
    {stats?.pendingExpenses != null && (
      <StatCard label="Harajat kutilmoqda" value={stats.pendingExpenses} icon={Receipt} />
    )}
    {stats?.pendingVetInspections != null && (
      <StatCard label="Vet hujjat kutilmoqda" value={stats.pendingVetInspections} icon={HeartPulse} />
    )}
    {stats?.totalRaised != null && (
      <StatCard label="Jami yig'ilgan mablag'" value={formatAmount(stats.totalRaised)} icon={Sprout} className="col-span-2 md:col-span-4" />
    )}
  </div>
);

export default AdminStatsBar;
