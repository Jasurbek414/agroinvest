import React from 'react';
import { AlertTriangle } from 'lucide-react';

const ErrorState = ({ message, onRetry }) => (
  <div className="text-center py-12 px-6">
    <AlertTriangle className="mx-auto mb-3 text-red-300 dark:text-red-800" size={40} strokeWidth={1.5} />
    <p className="text-red-600 dark:text-red-400 text-sm font-semibold">{message}</p>
    {onRetry && (
      <button
        onClick={onRetry}
        className="mt-4 px-4 py-2 bg-red-50 hover:bg-red-100 dark:bg-red-950 dark:hover:bg-red-900 text-red-700 dark:text-red-300 text-xs font-bold rounded-xl transition"
      >
        Qayta urinish
      </button>
    )}
  </div>
);

export default ErrorState;
