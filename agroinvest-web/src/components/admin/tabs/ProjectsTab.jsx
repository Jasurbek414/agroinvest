import React, { useEffect, useState } from 'react';
import { getProjects, changeProjectStatus } from '../../../api/projects.api';
import { formatAmount } from '../../../utils/format';
import EmptyState from '../../ui/EmptyState';
import ErrorState from '../../ui/ErrorState';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';

const ProjectsTab = ({ onActionDone }) => {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const { showToast } = useToast();

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await getProjects('PENDING');
      setProjects(res.data.content || []);
    } catch (err) {
      setError('Loyihalarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);

  const runAction = async (id, approved, reason) => {
    try {
      await changeProjectStatus(id, approved ? 'FUNDING' : 'CANCELLED', reason);
      showToast(approved ? "Loyiha tasdiqlandi va mablag' yig'ishga o'tdi" : 'Loyiha rad etildi');
      fetchData();
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  if (loading) return <p className="p-8 text-center text-sm text-gray-400 animate-pulse">Yuklanmoqda...</p>;
  if (error) return <ErrorState message={error} onRetry={fetchData} />;

  return (
    <div>
      <div className="p-6 border-b border-gray-100">
        <h2 className="text-base font-bold text-gray-900">Kutilayotgan loyiha arizalari</h2>
      </div>
      {projects.length === 0 ? (
        <EmptyState title="Tasdiqlash kutilayotgan loyihalar yo'q" />
      ) : (
        <div className="overflow-x-auto text-sm text-left">
          <table className="w-full">
            <thead>
              <tr className="bg-gray-50 text-gray-500 uppercase text-[10px] font-bold">
                <th className="p-4">Loyiha nomi</th>
                <th className="p-4">Viloyat</th>
                <th className="p-4">Maqsad summa</th>
                <th className="p-4">Foyda / Muddat</th>
                <th className="p-4 text-right">Amallar</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {projects.map((p) => (
                <tr key={p.id} className="hover:bg-gray-50/50">
                  <td className="p-4 font-semibold">{p.title}</td>
                  <td className="p-4 text-xs font-bold text-gray-400">{p.region}</td>
                  <td className="p-4 font-bold">{formatAmount(p.targetAmount)}</td>
                  <td className="p-4 text-xs font-bold text-green-600">+{p.expectedReturnPct}% / {p.durationDays} kun</td>
                  <td className="p-4 text-right">
                    <div className="flex justify-end gap-2">
                      <button onClick={() => setRejectTarget(p.id)} className="px-2 py-1 bg-red-50 text-red-700 rounded-lg text-xs font-bold">Rad etish</button>
                      <button onClick={() => runAction(p.id, true, null)} className="px-2 py-1 bg-green-50 text-green-700 rounded-lg text-xs font-bold">Tasdiqlash</button>
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
        title="Loyihani rad etish"
        label="Rad etish sababi"
        required
        tone="danger"
        confirmLabel="Rad etish"
        onCancel={() => setRejectTarget(null)}
        onConfirm={(reason) => { runAction(rejectTarget, false, reason); setRejectTarget(null); }}
      />
    </div>
  );
};

export default ProjectsTab;
