import React, { useState } from 'react';
import { updatePlatformSetting } from '../../api/superadmin.api';
import Card from '../ui/Card';
import PromptDialog from '../ui/PromptDialog';
import { useToast } from '../ui/ToastProvider';

const SettingsPanel = ({ settings, onChanged }) => {
  const [editTarget, setEditTarget] = useState(null); // settingKey
  const { showToast } = useToast();

  const handleUpdate = async (value) => {
    if (!value.trim()) {
      setEditTarget(null);
      return;
    }
    try {
      await updatePlatformSetting(editTarget, value.trim());
      showToast('Platforma sozlamasi muvaffaqiyatli yangilandi');
      onChanged?.();
    } catch (err) {
      showToast(err.error?.message || "Sozlamani o'zgartirishda xatolik", 'error');
    } finally {
      setEditTarget(null);
    }
  };

  return (
    <Card>
      <h2 className="text-lg font-bold text-gray-900 mb-4">Sozlamalar</h2>
      <div className="space-y-4">
        {settings.map((s) => (
          <div key={s.id} className="flex justify-between items-center border-b pb-3 text-sm">
            <div>
              <p className="font-bold text-gray-800 text-xs">{s.settingKey}</p>
              <p className="text-gray-500 font-extrabold mt-1">{s.settingValue}</p>
            </div>
            <button
              onClick={() => setEditTarget(s.settingKey)}
              className="px-2.5 py-1.5 border border-green-200 text-green-700 hover:bg-green-50 text-xs font-semibold rounded-lg transition"
            >
              O'zgartirish
            </button>
          </div>
        ))}
      </div>

      <PromptDialog
        open={!!editTarget}
        title={`Sozlamani yangilash: ${editTarget}`}
        label="Yangi qiymat"
        required
        confirmLabel="Saqlash"
        onCancel={() => setEditTarget(null)}
        onConfirm={handleUpdate}
      />
    </Card>
  );
};

export default SettingsPanel;
