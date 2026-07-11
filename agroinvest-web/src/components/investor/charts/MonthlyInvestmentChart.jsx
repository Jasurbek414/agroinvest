import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { useThemeStore } from '../../../store/theme.store';
import EmptyState from '../../ui/EmptyState';
import { formatAmount } from '../../../utils/format';

const MONTH_LABELS_UZ = ['Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn', 'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'];

// Compact UZS ticks so 12 500 000 doesn't blow up the y-axis gutter.
const compactUzs = (v) => {
  if (v >= 1e9) return `${(v / 1e9).toFixed(1).replace(/\.0$/, '')} mlrd`;
  if (v >= 1e6) return `${(v / 1e6).toFixed(1).replace(/\.0$/, '')} mln`;
  if (v >= 1e3) return `${(v / 1e3).toFixed(0)} ming`;
  return String(v);
};

// Sums the investor's contributions per calendar month over the trailing
// 6 months. Single series = single hue (primary-600, same step in dark - it
// passes on both chart surfaces per the palette checks), no legend needed.
const MonthlyInvestmentChart = ({ investments }) => {
  const isDark = useThemeStore((s) => s.theme === 'dark');

  const now = new Date();
  const months = [];
  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    months.push({ key: `${d.getFullYear()}-${d.getMonth()}`, label: MONTH_LABELS_UZ[d.getMonth()], value: 0 });
  }
  const byKey = new Map(months.map((m) => [m.key, m]));
  (investments || []).forEach((inv) => {
    if (inv.status === 'CANCELLED') return;
    const d = new Date(inv.createdAt);
    const bucket = byKey.get(`${d.getFullYear()}-${d.getMonth()}`);
    if (bucket) bucket.value += Number(inv.amount) || 0;
  });

  if (months.every((m) => m.value === 0)) {
    return <EmptyState title="Oxirgi 6 oyda sarmoya kiritilmagan" />;
  }

  const gridColor = isDark ? '#2c2c2a' : '#e1e0d9';
  const tickColor = isDark ? '#c3c2b7' : '#52514e';

  return (
    <ResponsiveContainer width="100%" height={220}>
      <BarChart data={months} margin={{ top: 8, right: 12, left: 8, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke={gridColor} vertical={false} />
        <XAxis dataKey="label" tick={{ fontSize: 11, fill: tickColor }} axisLine={{ stroke: gridColor }} tickLine={false} />
        <YAxis tickFormatter={compactUzs} tick={{ fontSize: 10, fill: tickColor }} axisLine={false} tickLine={false} width={52} />
        <Tooltip
          cursor={{ fill: isDark ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.03)' }}
          contentStyle={{
            background: isDark ? '#1e293b' : '#ffffff',
            border: `1px solid ${isDark ? '#334155' : '#f1f5f9'}`,
            borderRadius: 12,
            fontSize: 12,
          }}
          labelStyle={{ color: isDark ? '#e2e8f0' : '#0f172a', fontWeight: 700 }}
          formatter={(value) => [formatAmount(value), 'Kiritilgan sarmoya']}
        />
        <Bar dataKey="value" fill="#16a34a" radius={[6, 6, 0, 0]} maxBarSize={48} />
      </BarChart>
    </ResponsiveContainer>
  );
};

export default MonthlyInvestmentChart;
