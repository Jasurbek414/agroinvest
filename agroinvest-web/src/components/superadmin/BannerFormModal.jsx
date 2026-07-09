import React, { useState } from 'react';
import { createBanner, updateBanner } from '../../api/banners.api';
import ImageUploadPicker from '../ui/ImageUploadPicker';
import { useToast } from '../ui/ToastProvider';

const AUDIENCE_OPTIONS = [
  { value: 'ALL', label: 'Hammaga' },
  { value: 'INVESTOR', label: 'Faqat investorlarga' },
  { value: 'FARMER', label: 'Faqat fermerlarga' },
];

const toDateInputValue = (isoString) => (isoString ? isoString.slice(0, 10) : '');

const BannerFormModal = ({ banner, onClose, onSaved }) => {
  const isEdit = !!banner;
  const [title, setTitle] = useState(banner?.title || '');
  const [imageUrls, setImageUrls] = useState(banner?.imageUrl ? [banner.imageUrl] : []);
  const [linkUrl, setLinkUrl] = useState(banner?.linkUrl || '');
  const [targetAudience, setTargetAudience] = useState(banner?.targetAudience || 'ALL');
  const [isActive, setIsActive] = useState(banner ? banner.isActive : true);
  const [sortOrder, setSortOrder] = useState(banner?.sortOrder ?? 0);
  const [startDate, setStartDate] = useState(toDateInputValue(banner?.startDate));
  const [endDate, setEndDate] = useState(toDateInputValue(banner?.endDate));
  const [saving, setSaving] = useState(false);
  const { showToast } = useToast();

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!title.trim() || imageUrls.length === 0) {
      showToast('Sarlavha va rasm kiritilishi shart', 'error');
      return;
    }

    const payload = {
      title: title.trim(),
      imageUrl: imageUrls[0],
      linkUrl: linkUrl.trim() || null,
      targetAudience,
      isActive,
      sortOrder: Number(sortOrder),
      startDate: startDate ? `${startDate}T00:00:00` : null,
      endDate: endDate ? `${endDate}T23:59:59` : null,
    };

    setSaving(true);
    try {
      if (isEdit) {
        await updateBanner(banner.id, payload);
        showToast('Reklama yangilandi');
      } else {
        await createBanner(payload);
        showToast('Reklama yaratildi');
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
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-xl max-w-md w-full p-6 space-y-4 max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center">
          <h3 className="font-bold text-gray-900 dark:text-slate-100 text-lg">{isEdit ? 'Reklamani tahrirlash' : 'Yangi reklama'}</h3>
          <button onClick={onClose} aria-label="Yopish" className="text-gray-400 hover:text-gray-600 text-lg">&times;</button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Sarlavha</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              required
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Rasm</label>
            <ImageUploadPicker category="banner" urls={imageUrls} onChange={setImageUrls} maxImages={1} />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Havola (ixtiyoriy)</label>
            <input
              type="text"
              value={linkUrl}
              onChange={(e) => setLinkUrl(e.target.value)}
              placeholder="https://..."
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Auditoriya</label>
              <select
                value={targetAudience}
                onChange={(e) => setTargetAudience(e.target.value)}
                className="w-full px-3 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              >
                {AUDIENCE_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>{o.label}</option>
                ))}
              </select>
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

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Boshlanish sanasi (ixtiyoriy)</label>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Tugash sanasi (ixtiyoriy)</label>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              />
            </div>
          </div>

          <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-slate-300">
            <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="rounded border-gray-300 dark:border-slate-600" />
            Faol
          </label>

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

export default BannerFormModal;
