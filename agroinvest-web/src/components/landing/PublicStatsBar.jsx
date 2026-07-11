import React, { useEffect, useState } from 'react';
import { Users, Sprout, FolderCheck, Wallet } from 'lucide-react';
import { getPublicStats } from '../../api/settings.api';
import StatCard from '../ui/StatCard';
import { formatAmount } from '../../utils/format';

const PublicStatsBar = () => {
  const [stats, setStats] = useState(null);

  useEffect(() => {
    getPublicStats()
      .then((res) => setStats(res.data))
      .catch(() => {
        // Trust tiles are a nice-to-have on the landing page - a failed fetch
        // shouldn't block the rest of the page from rendering.
      });
  }, []);

  return (
    <section className="max-w-6xl mx-auto px-6 -mt-10 relative z-10">
      <div className="grid grid-cols-1 xs:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Investorlar" value={stats ? stats.totalInvestors : '—'} icon={Users} />
        <StatCard label="Fermerlar" value={stats ? stats.totalFarmers : '—'} icon={Sprout} />
        <StatCard label="Moliyalashtirilgan loyihalar" value={stats ? stats.totalFundedProjects : '—'} icon={FolderCheck} />
        <StatCard label="Jami sarmoya" value={stats ? formatAmount(stats.totalInvestedAmount) : '—'} icon={Wallet} />
      </div>
    </section>
  );
};

export default PublicStatsBar;
