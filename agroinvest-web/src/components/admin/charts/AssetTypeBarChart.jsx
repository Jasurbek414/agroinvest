import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Cell, ResponsiveContainer, LabelList } from 'recharts';
import { ASSET_TYPE_META } from '../../../utils/assetType';
import { useThemeStore } from '../../../store/theme.store';
import EmptyState from '../../ui/EmptyState';

// One bar per AssetType, colored with the same fixed hues used for the icon
// tint everywhere else (ProjectsTab rows, mobile app) - color follows the
// category identity, never a cycled/generated palette.
const AssetTypeBarChart = ({ data }) => {
  const isDark = useThemeStore((s) => s.theme === 'dark');
  const entries = Object.entries(data || {}).filter(([, count]) => count > 0);

  if (entries.length === 0) {
    return <EmptyState title="Hali loyihalar yo'q" />;
  }

  const chartData = entries.map(([assetType, count]) => {
    const meta = ASSET_TYPE_META[assetType] || ASSET_TYPE_META.OTHER;
    return { assetType, label: meta.label, value: count, color: isDark ? meta.colorDark : meta.color };
  });

  const gridColor = isDark ? '#2c2c2a' : '#e1e0d9';
  const tickColor = isDark ? '#c3c2b7' : '#52514e';

  return (
    <ResponsiveContainer width="100%" height={260}>
      <BarChart data={chartData} margin={{ top: 8, right: 12, left: -16, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke={gridColor} vertical={false} />
        <XAxis dataKey="label" tick={{ fontSize: 11, fill: tickColor }} axisLine={{ stroke: gridColor }} tickLine={false} />
        <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: tickColor }} axisLine={false} tickLine={false} width={28} />
        <Tooltip
          cursor={{ fill: isDark ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.03)' }}
          contentStyle={{
            background: isDark ? '#1e293b' : '#ffffff',
            border: `1px solid ${isDark ? '#334155' : '#f1f5f9'}`,
            borderRadius: 12,
            fontSize: 12,
          }}
          labelStyle={{ color: isDark ? '#e2e8f0' : '#0f172a', fontWeight: 700 }}
          formatter={(value) => [`${value} ta loyiha`, '']}
        />
        <Bar dataKey="value" radius={[6, 6, 0, 0]} maxBarSize={48}>
          {chartData.map((entry) => (
            <Cell key={entry.assetType} fill={entry.color} />
          ))}
          <LabelList dataKey="value" position="top" style={{ fontSize: 11, fontWeight: 700, fill: tickColor }} />
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
};

export default AssetTypeBarChart;
