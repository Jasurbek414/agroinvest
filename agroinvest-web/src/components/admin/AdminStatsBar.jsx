import React from 'react';

const STAT_TONE = {
  gray: 'text-gray-800',
  green: 'text-green-600',
  yellow: 'text-yellow-600',
  blue: 'text-blue-600',
};

const AdminStatsBar = ({ stats }) => {
  const items = [
    { label: 'Foydalanuvchilar', value: stats?.totalUsers, tone: 'gray' },
    { label: 'Faol loyihalar', value: stats?.activeProjects, tone: 'green' },
    { label: 'KYC kutilmoqda', value: stats?.pendingVetting, tone: 'yellow' },
    { label: 'Loyiha kutilmoqda', value: stats?.pendingProjects, tone: 'blue' },
  ];

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
      {items.map((item) => (
        <div key={item.label} className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm text-center">
          <p className="text-[10px] text-gray-400 font-semibold uppercase">{item.label}</p>
          <p className={`text-xl font-black mt-1 ${STAT_TONE[item.tone]}`}>{item.value || 0}</p>
        </div>
      ))}
    </div>
  );
};

export default AdminStatsBar;
