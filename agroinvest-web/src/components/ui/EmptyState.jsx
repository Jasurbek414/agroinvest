import React from 'react';

const EmptyState = ({ icon: Icon, title, subtitle, action }) => (
  <div className="text-center py-12 px-6">
    {Icon && <Icon className="mx-auto mb-3 text-gray-300 dark:text-slate-600" size={40} strokeWidth={1.5} />}
    <p className="text-gray-500 dark:text-slate-400 text-sm font-semibold">{title}</p>
    {subtitle && <p className="text-gray-400 dark:text-slate-500 text-xs mt-1">{subtitle}</p>}
    {action && <div className="mt-4">{action}</div>}
  </div>
);

export default EmptyState;
