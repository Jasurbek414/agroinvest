import React from 'react';

// Generic pulsing placeholder block - replaces the bare "Yuklanmoqda..." text
// that was repeated (and visually inconsistent) across almost every page/tab.
const Skeleton = ({ className = '' }) => (
  <div className={`animate-pulse bg-gray-200 dark:bg-slate-700 rounded-lg ${className}`} />
);

export const SkeletonTable = ({ rows = 5, cols = 4 }) => (
  <div className="p-4 space-y-3">
    {Array.from({ length: rows }).map((_, r) => (
      <div key={r} className="flex gap-4">
        {Array.from({ length: cols }).map((__, c) => (
          <Skeleton key={c} className="h-4 flex-1" />
        ))}
      </div>
    ))}
  </div>
);

export const SkeletonCard = ({ className = '' }) => (
  <div className={`bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 p-5 space-y-3 ${className}`}>
    <Skeleton className="h-3 w-1/3" />
    <Skeleton className="h-6 w-1/2" />
  </div>
);

export default Skeleton;
