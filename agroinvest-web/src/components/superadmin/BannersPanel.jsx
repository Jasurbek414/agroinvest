import React, { useEffect, useState } from 'react';
import { Plus, Pencil, Trash2 } from 'lucide-react';
import { getAllBanners, deleteBanner } from '../../api/banners.api';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Badge from '../ui/Badge';
import ConfirmDialog from '../ui/ConfirmDialog';
import { useToast } from '../ui/ToastProvider';
import { formatDate } from '../../utils/format';
import BannerFormModal from './BannerFormModal';

const AUDIENCE_LABEL_UZ = { ALL: 'Hammaga', INVESTOR: 'Investorlarga', FARMER: 'Fermerlarga' };

const BannersPanel = () => {
  const [banners, setBanners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [formTarget, setFormTarget] = useState(null); // null | 'new' | banner object
  const [deleteTarget, setDeleteTarget] = useState(null);
  const { showToast } = useToast();

  const fetchBanners = async () => {
    setLoading(true);
    try {
      const res = await getAllBanners();
      setBanners(res.data || []);
    } catch (err) {
      showToast('Reklamalarni yuklashda xatolik yuz berdi', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchBanners(); }, []);

  const handleDelete = async () => {
    try {
      await deleteBanner(deleteTarget);
      showToast("Reklama o'chirildi");
      setDeleteTarget(null);
      fetchBanners();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  return (
    <Card>
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">Reklamalar / E'lonlar</h2>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">Mobil ilovaning "Market" bo'limida ko'rsatiladi</p>
        </div>
        <Button variant="primary" size="sm" icon={Plus} onClick={() => setFormTarget('new')}>Yangi reklama</Button>
      </div>

      {loading ? (
        <p className="text-sm text-gray-400 text-center py-6">Yuklanmoqda...</p>
      ) : banners.length === 0 ? (
        <p className="text-sm text-gray-400 text-center py-6">Hali reklama qo'shilmagan</p>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {banners.map((b) => (
            <div key={b.id} className="rounded-xl border border-gray-100 dark:border-slate-700 overflow-hidden">
              <img src={b.imageUrl} alt={b.title} className="w-full h-32 object-cover" />
              <div className="p-3 space-y-1.5">
                <div className="flex items-center justify-between gap-2">
                  <p className="font-semibold text-sm text-gray-900 dark:text-slate-100 truncate">{b.title}</p>
                  {b.isActive ? <Badge tone="green">Faol</Badge> : <Badge tone="gray">Nofaol</Badge>}
                </div>
                <p className="text-xs text-gray-400">{AUDIENCE_LABEL_UZ[b.targetAudience]} · #{b.sortOrder}</p>
                {(b.startDate || b.endDate) && (
                  <p className="text-[11px] text-gray-400">
                    {b.startDate ? formatDate(b.startDate) : '...'} – {b.endDate ? formatDate(b.endDate) : '...'}
                  </p>
                )}
                <div className="flex gap-2 pt-1">
                  <Button variant="secondary" size="sm" icon={Pencil} onClick={() => setFormTarget(b)}>Tahrirlash</Button>
                  <Button variant="danger" size="sm" icon={Trash2} onClick={() => setDeleteTarget(b.id)} />
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {formTarget && (
        <BannerFormModal
          banner={formTarget === 'new' ? null : formTarget}
          onClose={() => setFormTarget(null)}
          onSaved={() => { setFormTarget(null); fetchBanners(); }}
        />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        title="Reklamani o'chirish"
        message="Ushbu reklamani o'chirishga ishonchingiz komilmi?"
        tone="danger"
        confirmLabel="O'chirish"
        onCancel={() => setDeleteTarget(null)}
        onConfirm={handleDelete}
      />
    </Card>
  );
};

export default BannersPanel;
