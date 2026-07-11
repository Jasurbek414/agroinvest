import React, { useState } from 'react';
import { createNews, updateNews } from '../../api/news.api';
import ImageUploadPicker from '../ui/ImageUploadPicker';
import { useToast } from '../ui/ToastProvider';

const NewsFormModal = ({ news, onClose, onSaved }) => {
  const isEdit = !!news;
  const [title, setTitle] = useState(news?.title || '');
  const [body, setBody] = useState(news?.body || '');
  const [imageUrls, setImageUrls] = useState(news?.imageUrl ? [news.imageUrl] : []);
  const [isActive, setIsActive] = useState(news ? news.isActive : true);
  const [saving, setSaving] = useState(false);
  const { showToast } = useToast();

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) {
      showToast('Sarlavha va matn kiritilishi shart', 'error');
      return;
    }

    const payload = {
      title: title.trim(),
      body: body.trim(),
      imageUrl: imageUrls[0] || null,
      isActive,
    };

    setSaving(true);
    try {
      if (isEdit) {
        await updateNews(news.id, payload);
        showToast('Yangilik yangilandi');
      } else {
        await createNews(payload);
        showToast('Yangilik yaratildi');
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
          <h3 className="font-bold text-gray-900 dark:text-slate-100 text-lg">{isEdit ? 'Yangilikni tahrirlash' : 'Yangi yangilik'}</h3>
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
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Matn</label>
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              rows={6}
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500 resize-y"
              required
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Rasm (ixtiyoriy)</label>
            <ImageUploadPicker category="banner" urls={imageUrls} onChange={setImageUrls} maxImages={1} />
          </div>

          <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-slate-300">
            <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="rounded border-gray-300 dark:border-slate-600" />
            Faol (mobil ilovada ko'rinadi)
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

export default NewsFormModal;
