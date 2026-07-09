import React, { useState } from 'react';
import { createCategory, updateCategory } from '../../api/categories.api';
import { useToast } from '../ui/ToastProvider';

// Handles both "add a (root or child) category" and "edit an existing one" -
// code/parent are create-only (see AssetCategoryService: level is denormalized,
// so re-parenting isn't supported by this MVP screen).
const CategoryFormModal = ({ mode, parentId, category, onClose, onSaved }) => {
  const isEdit = mode === 'edit';
  const [code, setCode] = useState('');
  const [nameUz, setNameUz] = useState(isEdit ? category.nameUz : '');
  const [icon, setIcon] = useState(isEdit ? category.icon || '' : '');
  const [sortOrder, setSortOrder] = useState(isEdit ? category.sortOrder ?? 0 : 0);
  const [isActive, setIsActive] = useState(isEdit ? category.isActive : true);
  const [saving, setSaving] = useState(false);
  const { showToast } = useToast();

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!nameUz.trim() || (!isEdit && !code.trim())) return;
    setSaving(true);
    try {
      if (isEdit) {
        await updateCategory(category.id, { nameUz: nameUz.trim(), icon: icon.trim() || null, sortOrder: Number(sortOrder), isActive });
        showToast('Kategoriya yangilandi');
      } else {
        await createCategory({ parentId: parentId || null, code: code.trim(), nameUz: nameUz.trim(), icon: icon.trim() || null, sortOrder: Number(sortOrder) });
        showToast('Kategoriya yaratildi');
      }
      onSaved?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-6">
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-xl max-w-sm w-full p-6 space-y-4">
        <div className="flex justify-between items-center">
          <h3 className="font-bold text-gray-900 dark:text-slate-100 text-lg">
            {isEdit ? 'Kategoriyani tahrirlash' : parentId ? 'Bo\'lim qo\'shish' : 'Yangi kategoriya'}
          </h3>
          <button onClick={onClose} aria-label="Yopish" className="text-gray-400 hover:text-gray-600 text-lg">&times;</button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3">
          {!isEdit && (
            <div>
              <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Kod</label>
              <input
                type="text"
                value={code}
                onChange={(e) => setCode(e.target.value)}
                placeholder="masalan: qoramolchilik-sut"
                className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
                required
              />
            </div>
          )}
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Nomi</label>
            <input
              type="text"
              value={nameUz}
              onChange={(e) => setNameUz(e.target.value)}
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              required
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Ikonka (ixtiyoriy)</label>
              <input
                type="text"
                value={icon}
                onChange={(e) => setIcon(e.target.value)}
                className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Tartib raqami</label>
              <input
                type="number"
                value={sortOrder}
                onChange={(e) => setSortOrder(e.target.value)}
                className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              />
            </div>
          </div>
          {isEdit && (
            <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-slate-300">
              <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="rounded border-gray-300 dark:border-slate-600" />
              Faol
            </label>
          )}

          <button
            type="submit"
            disabled={saving}
            className="w-full py-2.5 bg-primary-600 hover:bg-primary-700 disabled:opacity-40 text-white text-sm font-bold rounded-xl transition"
          >
            {saving ? 'Saqlanmoqda...' : 'Saqlash'}
          </button>
        </form>
      </div>
    </div>
  );
};

export default CategoryFormModal;
