import React, { useEffect, useState } from 'react';
import { getUnverifiedReports, verifyReport } from '../../../api/reports.api';
import EmptyState from '../../ui/EmptyState';
import ErrorState from '../../ui/ErrorState';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';

const ReportsTab = () => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const { showToast } = useToast();

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await getUnverifiedReports();
      setReports(res.data.content || []);
    } catch (err) {
      setError('Hisobotlarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);

  const runAction = async (id, verify, comment) => {
    try {
      await verifyReport(id, verify, comment);
      showToast(verify ? 'Hisobot tasdiqlandi' : 'Hisobot rad etildi');
      fetchData();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  if (loading) return <p className="p-8 text-center text-sm text-gray-400 animate-pulse">Yuklanmoqda...</p>;
  if (error) return <ErrorState message={error} onRetry={fetchData} />;

  return (
    <div>
      <div className="p-6 border-b border-gray-100">
        <h2 className="text-base font-bold text-gray-900">Kutilayotgan progress hisobotlari</h2>
      </div>
      {reports.length === 0 ? (
        <EmptyState title="Tasdiqlanish kutilayotgan hisobotlar yo'q" />
      ) : (
        <div className="overflow-x-auto text-sm text-left">
          <table className="w-full">
            <thead>
              <tr className="bg-gray-50 text-gray-500 uppercase text-[10px] font-bold">
                <th className="p-4">Hisobot ID</th>
                <th className="p-4">Turi</th>
                <th className="p-4">Izoh</th>
                <th className="p-4">Media</th>
                <th className="p-4 text-right">Amallar</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {reports.map((r) => (
                <tr key={r.id} className="hover:bg-gray-50/50">
                  <td className="p-4 text-xs font-mono text-gray-400">{r.id.substring(0, 8)}...</td>
                  <td className="p-4 font-bold text-xs text-yellow-600">{r.reportType}</td>
                  <td className="p-4 text-xs max-w-xs truncate">{r.notes}</td>
                  <td className="p-4">
                    {r.mediaUrls && r.mediaUrls.length > 0 ? (
                      <a href={r.mediaUrls[0]} target="_blank" rel="noreferrer" className="text-xs text-green-600 underline">Ko'rish</a>
                    ) : (
                      "Media yo'q"
                    )}
                  </td>
                  <td className="p-4 text-right">
                    <div className="flex justify-end gap-2">
                      <button onClick={() => setRejectTarget(r.id)} className="px-2 py-1 bg-red-50 text-red-700 rounded-lg text-xs font-bold">Rad etish</button>
                      <button onClick={() => runAction(r.id, true, null)} className="px-2 py-1 bg-green-50 text-green-700 rounded-lg text-xs font-bold">Tasdiqlash</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <PromptDialog
        open={!!rejectTarget}
        title="Hisobotni rad etish"
        label="Izoh"
        tone="danger"
        confirmLabel="Rad etish"
        onCancel={() => setRejectTarget(null)}
        onConfirm={(comment) => { runAction(rejectTarget, false, comment); setRejectTarget(null); }}
      />
    </div>
  );
};

export default ReportsTab;
