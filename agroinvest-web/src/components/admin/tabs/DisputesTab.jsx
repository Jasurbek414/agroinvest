import React, { useEffect, useState } from 'react';
import { getAllDisputes, resolveDispute } from '../../../api/disputes.api';
import EmptyState from '../../ui/EmptyState';
import ErrorState from '../../ui/ErrorState';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';
import DisputeList from '../../disputes/DisputeList';

const DisputesTab = () => {
  const [disputes, setDisputes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [resolveTarget, setResolveTarget] = useState(null);
  const { showToast } = useToast();

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await getAllDisputes();
      setDisputes(res.data.content || []);
    } catch (err) {
      setError('Shikoyatlarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);

  const openDisputes = disputes.filter((d) => d.status === 'OPEN' || d.status === 'INVESTIGATING');
  const closedDisputes = disputes.filter((d) => d.status === 'RESOLVED' || d.status === 'CLOSED');

  const handleResolve = async (resolution) => {
    try {
      await resolveDispute(resolveTarget, resolution);
      showToast('Shikoyat hal qilindi deb belgilandi');
      setResolveTarget(null);
      fetchData();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  if (loading) return <p className="p-8 text-center text-sm text-gray-400 animate-pulse">Yuklanmoqda...</p>;
  if (error) return <ErrorState message={error} onRetry={fetchData} />;

  return (
    <div className="p-6 space-y-8">
      <div>
        <h2 className="text-base font-bold text-gray-900 mb-4">Ochiq shikoyatlar</h2>
        {openDisputes.length === 0 ? (
          <EmptyState title="Ochiq shikoyatlar yo'q" />
        ) : (
          <div className="space-y-4">
            {openDisputes.map((d) => (
              <div key={d.id} className="border border-gray-100 rounded-2xl p-5 space-y-2">
                <div className="flex justify-between items-start">
                  <div>
                    <p className="font-bold text-gray-900">{d.projectTitle}</p>
                    <p className="text-xs text-gray-500 mt-0.5">
                      <span className="font-semibold">{d.filedByName}</span> tomonidan <span className="font-semibold">{d.againstUserName}</span> ustidan — {d.disputeType}
                    </p>
                  </div>
                  <button
                    onClick={() => setResolveTarget(d.id)}
                    className="px-3 py-1.5 bg-green-50 text-green-700 rounded-lg text-xs font-bold shrink-0"
                  >
                    Hal qilish
                  </button>
                </div>
                <p className="text-sm text-gray-600">{d.description}</p>
              </div>
            ))}
          </div>
        )}
      </div>

      <div>
        <h2 className="text-base font-bold text-gray-900 mb-4">Yopilgan shikoyatlar</h2>
        <DisputeList disputes={closedDisputes} showParties />
      </div>

      <PromptDialog
        open={!!resolveTarget}
        title="Shikoyatni hal qilish"
        label="Yechim tavsifi"
        required
        confirmLabel="Hal qilindi deb belgilash"
        onCancel={() => setResolveTarget(null)}
        onConfirm={handleResolve}
      />
    </div>
  );
};

export default DisputesTab;
