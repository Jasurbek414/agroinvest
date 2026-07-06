import React, { createContext, useCallback, useContext, useState } from 'react';

const ToastContext = createContext(null);

let nextId = 1;

export const ToastProvider = ({ children }) => {
  const [toasts, setToasts] = useState([]);

  const dismiss = useCallback((id) => {
    setToasts((current) => current.filter((t) => t.id !== id));
  }, []);

  const showToast = useCallback((message, type = 'success') => {
    const id = nextId++;
    setToasts((current) => [...current, { id, message, type }]);
    setTimeout(() => dismiss(id), 4000);
  }, [dismiss]);

  return (
    <ToastContext.Provider value={{ showToast }}>
      {children}
      <div className="fixed bottom-6 right-6 z-[100] flex flex-col gap-2 w-full max-w-sm px-4 sm:px-0">
        {toasts.map((t) => (
          <div
            key={t.id}
            role="status"
            className={`px-4 py-3 rounded-xl shadow-lg border text-sm font-semibold flex items-start justify-between gap-3 animate-[fadeIn_0.15s_ease-out] ${
              t.type === 'error'
                ? 'bg-red-50 border-red-200 text-red-700'
                : 'bg-white border-gray-100 text-gray-800'
            }`}
          >
            <span>{t.message}</span>
            <button
              onClick={() => dismiss(t.id)}
              aria-label="Yopish"
              className="text-current opacity-50 hover:opacity-100 leading-none"
            >
              &times;
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
};

export const useToast = () => {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return ctx;
};
