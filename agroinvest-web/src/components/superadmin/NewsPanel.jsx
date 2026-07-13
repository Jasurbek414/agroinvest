import React, { useEffect, useState } from 'react';
import { Plus, Pencil, Trash2 } from 'lucide-react';
import { getAllNews, deleteNews } from '../../api/news.api';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Badge from '../ui/Badge';
import ConfirmDialog from '../ui/ConfirmDialog';
import { useToast } from '../ui/ToastProvider';
import { formatDate } from '../../utils/format';
import NewsFormModal from './NewsFormModal';

const NewsPanel = () => {
  const [news, setNews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [formTarget, setFormTarget] = useState(null); // null | 'new' | news object
  const [deleteTarget, setDeleteTarget] = useState(null);
  const { showToast } = useToast();

  const fetchNews = async () => {
    setLoading(true);
    try {
      const res = await getAllNews();
      setNews(res.data.content || []);
    } catch (err) {
      showToast('Yangiliklarni yuklashda xatolik yuz berdi', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchNews(); }, []);

  const handleDelete = async () => {
    try {
      await deleteNews(deleteTarget);
      showToast("Yangilik o'chirildi");
      setDeleteTarget(null);
      fetchNews();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  return (
    <Card>
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">Yangiliklar</h2>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">Mobil ilovaning bosh sahifasida ko'rsatiladi</p>
        </div>
        <Button variant="primary" size="sm" icon={Plus} onClick={() => setFormTarget('new')}>Yangi yangilik</Button>
      </div>

      {loading ? (
        <p className="text-sm text-gray-400 text-center py-6">Yuklanmoqda...</p>
      ) : news.length === 0 ? (
        <p className="text-sm text-gray-400 text-center py-6">Hali yangilik qo'shilmagan</p>
      ) : (
        <div className="space-y-3">
          {news.map((n) => (
            <div key={n.id} className="flex gap-4 rounded-xl border border-gray-100 dark:border-slate-700 p-3">
              {n.imageUrl && (
                <img src={n.imageUrl} alt={n.title} className="w-24 h-20 object-cover rounded-lg shrink-0" />
              )}
              <div className="flex-1 min-w-0 space-y-1">
                <div className="flex items-center justify-between gap-2">
                  <p className="font-semibold text-sm text-gray-900 dark:text-slate-100 truncate">{n.title}</p>
                  {n.isActive ? <Badge tone="green">Faol</Badge> : <Badge tone="gray">Nofaol</Badge>}
                </div>
                <p className="text-xs text-gray-500 dark:text-slate-400 line-clamp-2">{n.body}</p>
                {(n.startDate || n.endDate) && (
                  <p className="text-[11px] text-gray-400">
                    Muddati: {n.startDate ? formatDate(n.startDate) : '...'} – {n.endDate ? formatDate(n.endDate) : '...'}
                  </p>
                )}
                <div className="flex items-center justify-between pt-1">
                  <p className="text-[11px] text-gray-400">{formatDate(n.createdAt)}</p>
                  <div className="flex gap-2">
                    <Button variant="secondary" size="sm" icon={Pencil} onClick={() => setFormTarget(n)}>Tahrirlash</Button>
                    <Button variant="danger" size="sm" icon={Trash2} onClick={() => setDeleteTarget(n.id)} />
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {formTarget && (
        <NewsFormModal
          news={formTarget === 'new' ? null : formTarget}
          onClose={() => setFormTarget(null)}
          onSaved={() => { setFormTarget(null); fetchNews(); }}
        />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        title="Yangilikni o'chirish"
        message="Ushbu yangilikni o'chirishga ishonchingiz komilmi?"
        tone="danger"
        confirmLabel="O'chirish"
        onCancel={() => setDeleteTarget(null)}
        onConfirm={handleDelete}
      />
    </Card>
  );
};

export default NewsPanel;
