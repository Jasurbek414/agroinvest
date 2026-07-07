import React, { useState, useEffect } from 'react';
import { getMyInvestments, cancelInvestment } from '../../api/investments.api';
import Badge from '../../components/ui/Badge';
import EmptyState from '../../components/ui/EmptyState';
import ErrorState from '../../components/ui/ErrorState';
import ConfirmDialog from '../../components/ui/ConfirmDialog';
import { useToast } from '../../components/ui/ToastProvider';
import { formatAmount, formatDate } from '../../utils/format';

const MyInvestments = () => {
  const [investments, setInvestments] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [cancelTarget, setCancelTarget] = useState(null);
  const { showToast } = useToast();

  useEffect(() => {
    fetchInvestments();
  }, []);

  const fetchInvestments = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await getMyInvestments();
      setInvestments(response.data.content || []);
    } catch (err) {
      setError("Investitsiyalarni yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = async () => {
    const investmentId = cancelTarget;
    setCancelTarget(null);
    try {
      await cancelInvestment(investmentId);
      showToast('Sarmoya muvaffaqiyatli bekor qilindi');
      fetchInvestments();
    } catch (err) {
      showToast(err.error?.message || 'Bekor qilishda xatolik yuz berdi', 'error');
    }
  };

  const isCancellable = (createdAtStr) => {
    const createdDate = new Date(createdAtStr);
    const differenceInMs = new Date() - createdDate;
    const hours = differenceInMs / (1000 * 60 * 60);
    return hours < 24;
  };

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-slate-900 p-6 md:p-12">
      <div className="max-w-4xl mx-auto space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Sarmoyalarim</h1>
          <p className="text-sm text-gray-500 mt-1">Siz sarmoya kiritgan faol va yakunlangan qishloq xo'jaligi aktivlari</p>
        </div>

        {loading ? (
          <p className="text-gray-500 animate-pulse text-center">Yuklanmoqda...</p>
        ) : error ? (
          <ErrorState message={error} onRetry={fetchInvestments} />
        ) : investments.length === 0 ? (
          <div className="bg-white rounded-2xl border border-gray-100">
            <EmptyState title="Sizda hali sarmoyalar mavjud emas" />
          </div>
        ) : (
          <div className="space-y-4">
            {investments.map((inv) => (
              <div
                key={inv.id}
                className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col md:flex-row md:items-center md:justify-between gap-4"
              >
                <div>
                  <h3 className="font-bold text-gray-900 text-base mb-1">{inv.projectTitle}</h3>
                  <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-gray-400">
                    <span>Sana: {formatDate(inv.createdAt)}</span>
                    <span>Ulush: <strong className="text-green-600 font-bold">{inv.sharePct.toFixed(2)}%</strong></span>
                  </div>
                </div>

                <div className="flex items-center justify-between md:justify-end gap-6">
                  <div className="text-right">
                    <p className="text-xs text-gray-400">Kiritilgan sarmoya</p>
                    <p className="font-extrabold text-gray-900">{formatAmount(inv.amount)}</p>
                  </div>

                  <div className="flex items-center gap-3">
                    <Badge status={inv.status} />

                    {inv.status === 'CONFIRMED' && isCancellable(inv.createdAt) && (
                      <button
                        onClick={() => setCancelTarget(inv.id)}
                        className="px-3 py-1.5 bg-red-50 hover:bg-red-100 text-red-700 text-xs font-semibold rounded-lg transition"
                      >
                        Bekor qilish
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <ConfirmDialog
        open={!!cancelTarget}
        title="Sarmoyani bekor qilish"
        message="Haqiqatan ham ushbu sarmoyani bekor qilmoqchimisiz? Pul hamyoningizga qaytariladi."
        confirmLabel="Bekor qilish"
        tone="danger"
        onCancel={() => setCancelTarget(null)}
        onConfirm={handleCancel}
      />
    </div>
  );
};

export default MyInvestments;
