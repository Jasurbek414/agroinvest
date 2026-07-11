import React from 'react';
import { Sprout, Wallet, Receipt, HeartPulse } from 'lucide-react';
import StatCard from '../ui/StatCard';
import { formatAmount, formatDate } from '../../utils/format';

// GET /dashboard/me for a FARMER: total/active/funding projects, raised total,
// how many of their own submitted expenses are still pending and the last
// verified vet check date. Reports-due moved to the actionable ReportsDueBanner.
const FarmerStatsBar = ({ stats }) => (
  <div className="grid grid-cols-1 xs:grid-cols-2 lg:grid-cols-4 gap-6">
    <StatCard label="Faol loyihalar" value={stats?.activeProjects ?? 0} icon={Sprout} />
    <StatCard label="Yig'ilgan mablag'" value={formatAmount(stats?.totalRaised ?? 0)} icon={Wallet} />
    <StatCard label="Harajat kutilmoqda" value={stats?.pendingExpenses ?? 0} icon={Receipt} />
    <StatCard
      label="Oxirgi vet ko'rik"
      value={stats?.lastVetInspectionAt ? formatDate(stats.lastVetInspectionAt) : '—'}
      icon={HeartPulse}
    />
  </div>
);

export default FarmerStatsBar;
