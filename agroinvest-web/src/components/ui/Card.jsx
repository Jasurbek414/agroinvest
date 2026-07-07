import React from 'react';

const Card = ({ children, className = '', padded = true }) => (
  <div className={`bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm ${padded ? 'p-6' : ''} ${className}`}>
    {children}
  </div>
);

export default Card;
