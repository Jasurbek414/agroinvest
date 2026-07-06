import React from 'react';

// Replaces window.confirm()/alert() for destructive or important actions so the
// prompt matches the app's own card/modal styling instead of a native browser dialog.
const ConfirmDialog = ({ open, title, message, confirmLabel = 'Tasdiqlash', tone = 'primary', onConfirm, onCancel }) => {
  if (!open) return null;

  const confirmClasses =
    tone === 'danger'
      ? 'bg-red-600 hover:bg-red-700'
      : 'bg-green-600 hover:bg-green-700';

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-6">
      <div className="bg-white rounded-2xl border border-gray-100 shadow-xl max-w-sm w-full p-6 space-y-4">
        <h3 className="font-bold text-gray-900 text-lg">{title}</h3>
        {message && <p className="text-sm text-gray-500">{message}</p>}
        <div className="flex gap-3 pt-2">
          <button
            onClick={onCancel}
            className="flex-1 py-2.5 bg-gray-50 hover:bg-gray-100 text-gray-700 text-sm font-bold rounded-xl transition"
          >
            Bekor qilish
          </button>
          <button
            onClick={onConfirm}
            className={`flex-1 py-2.5 text-white text-sm font-bold rounded-xl transition ${confirmClasses}`}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ConfirmDialog;
