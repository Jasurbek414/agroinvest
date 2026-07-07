import React from 'react';

// Centralizes the text-input styling/padding that previously differed slightly
// between forms (e.g. CreateAdminForm's px-3 py-2 vs LoginPage's px-4 py-3).
const Input = React.forwardRef(({ label, error, icon: Icon, className = '', containerClassName = '', ...props }, ref) => (
  <div className={containerClassName}>
    {label && <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">{label}</label>}
    <div className="relative">
      {Icon && <Icon size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 dark:text-slate-500" />}
      <input
        ref={ref}
        className={`w-full ${Icon ? 'pl-10' : 'pl-3.5'} pr-3.5 py-2.5 border rounded-xl text-sm outline-none transition
          bg-white dark:bg-slate-900 text-gray-900 dark:text-slate-100 border-gray-300 dark:border-slate-600
          focus:ring-1 focus:ring-primary-500 focus:border-primary-500
          ${error ? 'border-red-400 focus:ring-red-500 focus:border-red-500' : ''} ${className}`}
        {...props}
      />
    </div>
    {error && <p className="mt-1 text-xs text-red-600 dark:text-red-400 font-medium">{error}</p>}
  </div>
));
Input.displayName = 'Input';

export default Input;
