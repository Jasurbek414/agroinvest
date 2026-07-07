import React from 'react';
import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { STATUS_LABEL_UZ } from '../../ui/Badge';
import { useThemeStore } from '../../../store/theme.store';
import EmptyState from '../../ui/EmptyState';

// Distinct from AssetTypeBarChart's palette on purpose (a status color must
// never be confused with a category color) - validated separately with the
// dataviz skill's checker for both chart surfaces.
const STATUS_COLORS = {
  PENDING: { light: '#ca8a04', dark: '#a16207' },
  APPROVED: { light: '#0d9488', dark: '#0f9488' },
  FUNDING: { light: '#2563eb', dark: '#0284c7' },
  ACTIVE: { light: '#16a34a', dark: '#16a34a' },
  COMPLETED: { light: '#6d28d9', dark: '#8b5cf6' },
  CANCELLED: { light: '#dc2626', dark: '#dc4444' },
};

const ProjectStatusPieChart = ({ data }) => {
  const isDark = useThemeStore((s) => s.theme === 'dark');
  const entries = Object.entries(data || {}).filter(([, count]) => count > 0);

  if (entries.length === 0) {
    return <EmptyState title="Hali loyihalar yo'q" />;
  }

  const chartData = entries.map(([status, count]) => ({
    status,
    name: STATUS_LABEL_UZ[status] || status,
    value: count,
    color: (STATUS_COLORS[status] || STATUS_COLORS.COMPLETED)[isDark ? 'dark' : 'light'],
  }));

  return (
    <ResponsiveContainer width="100%" height={260}>
      <PieChart>
        <Pie
          data={chartData}
          dataKey="value"
          nameKey="name"
          cx="50%"
          cy="50%"
          innerRadius={50}
          outerRadius={85}
          paddingAngle={2}
          label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
          labelLine={false}
          style={{ fontSize: 11, fontWeight: 600 }}
        >
          {chartData.map((entry) => (
            <Cell key={entry.status} fill={entry.color} stroke={isDark ? '#1e293b' : '#ffffff'} strokeWidth={2} />
          ))}
        </Pie>
        <Tooltip
          contentStyle={{
            background: isDark ? '#1e293b' : '#ffffff',
            border: `1px solid ${isDark ? '#334155' : '#f1f5f9'}`,
            borderRadius: 12,
            fontSize: 12,
          }}
          labelStyle={{ color: isDark ? '#e2e8f0' : '#0f172a', fontWeight: 700 }}
          formatter={(value, name) => [`${value} ta loyiha`, name]}
        />
        <Legend
          verticalAlign="bottom"
          height={36}
          wrapperStyle={{ fontSize: 11, color: isDark ? '#c3c2b7' : '#52514e' }}
        />
      </PieChart>
    </ResponsiveContainer>
  );
};

export default ProjectStatusPieChart;
