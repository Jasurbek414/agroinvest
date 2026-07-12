import React, { useEffect, useState } from 'react';
import { Plus, Trash2 } from 'lucide-react';
import { getRegions, createRegion, deleteRegion } from '../../api/regions.api';
import Card from '../ui/Card';
import Button from '../ui/Button';
import { useToast } from '../ui/ToastProvider';

const RegionsPanel = () => {
  const [regions, setRegions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [newRegionName, setNewRegionName] = useState('');
  const [showModal, setShowModal] = useState(false);
  const { showToast } = useToast();

  const fetchRegions = async () => {
    setLoading(true);
    try {
      const res = await getRegions();
      setRegions(res.data || []);
    } catch (err) {
      showToast('Hududlarni yuklashda xatolik yuz berdi', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRegions();
  }, []);

  const handleCreate = async (e) => {
    e.preventDefault();
    if (!newRegionName.trim()) return;
    try {
      await createRegion({ name: newRegionName.trim() });
      showToast('Yangi hudud muvaffaqiyatli qo\'shildi', 'success');
      setNewRegionName('');
      setShowModal(false);
      fetchRegions();
    } catch (err) {
      showToast('Hudud qo\'shishda xatolik yuz berdi', 'error');
    }
  };

  const handleDelete = async (id, name) => {
    if (!window.confirm(`Haqiqatan ham "${name}" hududini o'chirmoqchimisiz?`)) return;
    try {
      await deleteRegion(id);
      showToast('Hudud muvaffaqiyatli o\'chirildi', 'success');
      fetchRegions();
    } catch (err) {
      showToast('Hududni o\'chirishda xatolik yuz berdi', 'error');
    }
  };

  const filteredRegions = regions.filter((r) =>
    r.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <Card padded className="space-y-6">
      <div className="flex flex-col md:flex-row gap-4 justify-between items-start md:items-center">
        <div>
          <h2 className="text-lg font-bold text-gray-900 dark:text-slate-100">Hududlar (Viloyatlar) boshqaruvi</h2>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">Loyihalar yaratishda va filtrda ko'rinadigan hududlar ro'yxati</p>
        </div>
        <div className="flex gap-2 w-full md:w-auto">
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Hududni qidirish..."
            className="px-3.5 py-1.5 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500 w-full md:w-48 placeholder-gray-400"
          />
          <Button variant="primary" size="sm" icon={Plus} onClick={() => setShowModal(true)} className="shrink-0">
            Yangi hudud
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 p-4 bg-gray-50/50 dark:bg-slate-900/20 border border-gray-100 dark:border-slate-800 rounded-2xl text-center">
        <div>
          <p className="text-[10px] uppercase font-bold text-gray-400 dark:text-slate-500 tracking-wider">Jami hududlar</p>
          <p className="text-base font-extrabold text-gray-900 dark:text-slate-100 mt-0.5">{regions.length} ta</p>
        </div>
        <div>
          <p className="text-[10px] uppercase font-bold text-gray-400 dark:text-slate-500 tracking-wider">Filtrdagi hududlar</p>
          <p className="text-base font-extrabold text-green-600 dark:text-green-400 mt-0.5">{filteredRegions.length} ta</p>
        </div>
      </div>

      {loading ? (
        <p className="text-sm text-gray-400 text-center py-6">Yuklanmoqda...</p>
      ) : filteredRegions.length === 0 ? (
        <p className="text-sm text-gray-400 text-center py-6">Hududlar topilmadi</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filteredRegions.map((r) => (
            <div
              key={r.id}
              className="flex justify-between items-center p-4 bg-white dark:bg-slate-800 border border-gray-100 dark:border-slate-700/50 rounded-2xl shadow-sm hover:shadow-md transition-all duration-200"
            >
              <span className="text-sm font-bold text-gray-900 dark:text-slate-100">{r.name}</span>
              <button
                onClick={() => handleDelete(r.id, r.name)}
                className="p-2 text-red-500 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-950/30 rounded-xl transition-all"
                title="O'chirish"
              >
                <Trash2 size={16} />
              </button>
            </div>
          ))}
        </div>
      )}

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white dark:bg-slate-800 border border-gray-100 dark:border-slate-700 w-full max-w-md rounded-3xl p-6 shadow-2xl space-y-6">
            <div>
              <h3 className="text-base font-extrabold text-gray-950 dark:text-slate-50">Yangi hudud qo'shish</h3>
              <p className="text-xs text-gray-500 mt-1">Platformadagi barcha loyihalar uchun yangi hudud nomini kiriting.</p>
            </div>

            <form onSubmit={handleCreate} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-gray-400 dark:text-slate-500 uppercase tracking-wider">Hudud nomi</label>
                <input
                  type="text"
                  required
                  value={newRegionName}
                  onChange={(e) => setNewRegionName(e.target.value)}
                  placeholder="Masalan: Xorazm viloyati"
                  className="w-full px-4 py-3 border border-gray-200 dark:border-slate-700 rounded-2xl text-sm bg-white dark:bg-slate-900 text-gray-900 dark:text-slate-50 outline-none focus:ring-2 focus:ring-green-500/20 focus:border-green-500"
                />
              </div>

              <div className="flex gap-3 justify-end pt-2">
                <Button variant="ghost" type="button" onClick={() => setShowModal(false)}>
                  Bekor qilish
                </Button>
                <Button variant="primary" type="submit">
                  Qo'shish
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </Card>
  );
};

export default RegionsPanel;
