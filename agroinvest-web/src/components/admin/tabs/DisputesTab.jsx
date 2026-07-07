import React, { useEffect, useState } from 'react';
import { getAllDisputes, resolveDispute, startInvestigation, closeDispute } from '../../../api/disputes.api';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import EmptyState from '../../ui/EmptyState';
import ErrorState from '../../ui/ErrorState';
import Pagination from '../../ui/Pagination';
import PromptDialog from '../../ui/PromptDialog';
import { SkeletonCard } from '../../ui/Skeleton';
import { useToast } from '../../ui/ToastProvider';
import DisputeList from '../../disputes/DisputeList';

const DisputesTab = () => {
  const [disputes, setDisputes] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [resolveTarget, setResolveTarget] = useState(null);
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getAllDisputes(page, 10);
      setDisputes(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError('Shikoyatlarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(0); }, []);

  const openDisputes = disputes.filter((d) => d.status === 'OPEN' || d.status === 'INVESTIGATING');
  const closedDisputes = disputes.filter((d) => d.status === 'RESOLVED' || d.status === 'CLOSED');

  const handleResolve = async (resolution) => {
    try {
      await resolveDispute(resolveTarget, resolution);
      showToast('Shikoyat hal qilindi deb belgilandi');
      setResolveTarget(null);
      fetchData(pageInfo.pageNumber);
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const handleInvestigate = async (id) => {
    try {
      await startInvestigation(id);
      showToast("Shikoyat ko'rib chiqilmoqda deb belgilandi");
      fetchData(pageInfo.pageNumber);
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const handleClose = async (id) => {
    try {
      await closeDispute(id);
      showToast('Shikoyat yopildi');
      fetchData(pageInfo.pageNumber);
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  if (loading) return <div className="p-6 space-y-3"><SkeletonCard /><SkeletonCard /></div>;
  if (error) return <ErrorState message={error} onRetry={() => fetchData(pageInfo.pageNumber)} />;

  return (
    <div className="p-6 space-y-8">
      <div>
        <h2 className="text-base font-bold text-gray-900 dark:text-slate-100 mb-4">Ochiq shikoyatlar</h2>
        {openDisputes.length === 0 ? (
          <EmptyState title="Ochiq shikoyatlar yo'q" />
        ) : (
          <div className="space-y-4">
            {openDisputes.map((d) => (
              <div key={d.id} className="border border-gray-100 dark:border-slate-700 rounded-2xl p-5 space-y-2">
                <div className="flex justify-between items-start gap-3">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <p className="font-bold text-gray-900 dark:text-slate-100">{d.projectTitle}</p>
                      <Badge status={d.status} />
                    </div>
                    <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">
                      <span className="font-semibold">{d.filedByName}</span> tomonidan <span className="font-semibold">{d.againstUserName}</span> ustidan — {d.disputeType}
                    </p>
                  </div>
                  <div className="flex gap-2 shrink-0">
                    {d.status === 'OPEN' && (
                      <Button variant="secondary" size="sm" onClick={() => handleInvestigate(d.id)}>Tekshiruvga olish</Button>
                    )}
                    <Button variant="primary" size="sm" onClick={() => setResolveTarget(d.id)}>Hal qilish</Button>
                  </div>
                </div>
                <p className="text-sm text-gray-600 dark:text-slate-300">{d.description}</p>
              </div>
            ))}
          </div>
        )}
      </div>

      <div>
        <h2 className="text-base font-bold text-gray-900 dark:text-slate-100 mb-4">Yopilgan shikoyatlar</h2>
        <div className="space-y-3">
          {closedDisputes.map((d) => (
            <div key={d.id}>
              <DisputeList disputes={[d]} showParties />
              {d.status === 'RESOLVED' && (
                <div className="flex justify-end mt-2">
                  <Button variant="secondary" size="sm" onClick={() => handleClose(d.id)}>Yopish</Button>
                </div>
              )}
            </div>
          ))}
          {closedDisputes.length === 0 && <EmptyState title="Yopilgan shikoyatlar yo'q" />}
        </div>
      </div>

      <Pagination pageNumber={pageInfo.pageNumber} totalPages={pageInfo.totalPages} onPageChange={fetchData} />

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
