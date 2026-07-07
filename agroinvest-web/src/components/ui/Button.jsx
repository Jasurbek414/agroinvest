import React from 'react';

const VARIANT_CLASSES = {
  primary: 'bg-primary-600 hover:bg-primary-700 text-white',
  secondary: 'bg-gray-50 hover:bg-gray-100 dark:bg-slate-700 dark:hover:bg-slate-600 text-gray-700 dark:text-slate-200',
  danger: 'bg-red-50 hover:bg-red-100 dark:bg-red-950 dark:hover:bg-red-900 text-red-600 dark:text-red-300',
  solidDanger: 'bg-red-600 hover:bg-red-700 text-white',
  ghost: 'bg-transparent hover:bg-gray-100 dark:hover:bg-slate-800 text-gray-600 dark:text-slate-300',
};

const SIZE_CLASSES = {
  sm: 'px-3 py-1.5 text-xs',
  md: 'px-4 py-2.5 text-sm',
  lg: 'px-5 py-3 text-base',
};

// Centralizes the button styling that was previously copy-pasted (with slightly
// different padding/colors each time) across every page and admin tab.
const Button = ({ variant = 'primary', size = 'md', icon: Icon, className = '', children, ...props }) => (
  <button
    className={`inline-flex items-center justify-center gap-2 font-bold rounded-xl transition disabled:opacity-40 disabled:cursor-not-allowed ${VARIANT_CLASSES[variant]} ${SIZE_CLASSES[size]} ${className}`}
    {...props}
  >
    {Icon && <Icon size={size === 'sm' ? 14 : 16} />}
    {children}
  </button>
);

export default Button;
