import React, { useState } from 'react';

// Replaces window.prompt() for admin actions that need a short reason/comment
// (reject withdrawal, reject KYC, reject project, verify report).
const PromptDialog = ({ open, title, label, required, confirmLabel = 'Tasdiqlash', tone = 'primary', onConfirm, onCancel }) => {
  const [value, setValue] = useState('');

  if (!open) return null;

  const confirmClasses = tone === 'danger' ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700';

  const handleConfirm = () => {
    if (required && !value.trim()) return;
    onConfirm(value.trim());
    setValue('');
  };

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-6">
      <div className="bg-white rounded-2xl border border-gray-100 shadow-xl max-w-sm w-full p-6 space-y-4">
        <h3 className="font-bold text-gray-900 text-lg">{title}</h3>
        <div>
          <label className="block text-xs font-semibold text-gray-600 mb-1.5">{label}{required ? '' : ' (ixtiyoriy)'}</label>
          <textarea
            autoFocus
            value={value}
            onChange={(e) => setValue(e.target.value)}
            rows="3"
            className="w-full px-3.5 py-2.5 border border-gray-300 rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
          />
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => { setValue(''); onCancel(); }}
            className="flex-1 py-2.5 bg-gray-50 hover:bg-gray-100 text-gray-700 text-sm font-bold rounded-xl transition"
          >
            Bekor qilish
          </button>
          <button
            onClick={handleConfirm}
            disabled={required && !value.trim()}
            className={`flex-1 py-2.5 text-white text-sm font-bold rounded-xl transition disabled:opacity-40 ${confirmClasses}`}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
};

export default PromptDialog;
