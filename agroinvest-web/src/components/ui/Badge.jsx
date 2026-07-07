import React from 'react';

const TONE_CLASSES = {
  gray: 'bg-gray-100 text-gray-700 border-gray-200 dark:bg-slate-700 dark:text-slate-200 dark:border-slate-600',
  green: 'bg-green-50 text-green-700 border-green-100 dark:bg-green-950 dark:text-green-300 dark:border-green-900',
  blue: 'bg-blue-50 text-blue-700 border-blue-100 dark:bg-blue-950 dark:text-blue-300 dark:border-blue-900',
  yellow: 'bg-yellow-50 text-yellow-800 border-yellow-200 dark:bg-yellow-950 dark:text-yellow-300 dark:border-yellow-900',
  red: 'bg-red-50 text-red-700 border-red-100 dark:bg-red-950 dark:text-red-300 dark:border-red-900',
};

// Central status-color mapping so every screen (admin queue, farmer's own list,
// investor history) renders the same status with the same color instead of each
// page inventing its own switch/case.
const STATUS_TONE = {
  PENDING: 'yellow',
  APPROVED: 'green',
  FUNDING: 'blue',
  ACTIVE: 'green',
  COMPLETED: 'gray',
  CANCELLED: 'red',
  REJECTED: 'red',
  CONFIRMED: 'green',
  PAID_OUT: 'gray',
  VERIFIED: 'green',
  UNVERIFIED: 'gray',
  OPEN: 'yellow',
  INVESTIGATING: 'blue',
  RESOLVED: 'green',
  CLOSED: 'gray',
  LOW: 'blue',
  MEDIUM: 'yellow',
  HIGH: 'red',
};

// Exported so charts (e.g. ProjectStatusPieChart) can label the same status
// codes the same way, instead of inventing a second translation map.
export const STATUS_LABEL_UZ = {
  PENDING: "Kutilmoqda",
  APPROVED: 'Tasdiqlangan',
  FUNDING: "Mablag' yig'ilmoqda",
  ACTIVE: 'Faol',
  COMPLETED: 'Yakunlangan',
  CANCELLED: 'Bekor qilingan',
  REJECTED: 'Rad etilgan',
  CONFIRMED: 'Tasdiqlangan',
  PAID_OUT: "To'langan",
  VERIFIED: 'Tasdiqlangan',
  UNVERIFIED: 'Tasdiqlanmagan',
  OPEN: 'Ochiq',
  INVESTIGATING: 'Ko\'rib chiqilmoqda',
  RESOLVED: 'Hal qilingan',
  CLOSED: 'Yopilgan',
  LOW: 'Past',
  MEDIUM: "O'rtacha",
  HIGH: 'Yuqori',
};

const Badge = ({ status, tone, children, className = '' }) => {
  const resolvedTone = tone || STATUS_TONE[status] || 'gray';
  const label = children ?? STATUS_LABEL_UZ[status] ?? status;

  return (
    <span
      className={`inline-flex items-center text-[11px] font-bold uppercase tracking-wide px-2.5 py-0.5 rounded-full border ${TONE_CLASSES[resolvedTone]} ${className}`}
    >
      {label}
    </span>
  );
};

export default Badge;
