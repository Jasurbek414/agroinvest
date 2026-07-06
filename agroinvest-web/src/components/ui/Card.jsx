import React from 'react';

const Card = ({ children, className = '', padded = true }) => (
  <div className={`bg-white rounded-2xl border border-gray-100 shadow-sm ${padded ? 'p-6' : ''} ${className}`}>
    {children}
  </div>
);

export default Card;
