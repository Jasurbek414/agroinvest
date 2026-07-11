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
import { AlertCircle, Eye, ShieldAlert, Award, FileText, CheckCircle2, MessageSquare, Scale, HelpCircle } from 'lucide-react';

const DisputesTab = () => {
  const [disputes, setDisputes] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [resolveTarget, setResolveTarget] = useState(null);
  const [selectedDispute, setSelectedDispute] = useState(null);
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
      setSelectedDispute(null);
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
      setSelectedDispute(null);
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const handleClose = async (id) => {
    try {
      await closeDispute(id);
      showToast('Shikoyat yopildi');
      fetchData(pageInfo.pageNumber);
      setSelectedDispute(null);
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  if (loading) return <div className="p-6 space-y-3"><SkeletonCard /><SkeletonCard /></div>;
  if (error) return <ErrorState message={error} onRetry={() => fetchData(pageInfo.pageNumber)} />;

  // Calculate statistics
  const totalOpenCount = disputes.filter(d => d.status === 'OPEN').length;
  const investigatingCount = disputes.filter(d => d.status === 'INVESTIGATING').length;
  const resolvedCount = disputes.filter(d => d.status === 'RESOLVED' || d.status === 'CLOSED').length;

  return (
    <div className="space-y-6 p-6">
      {/* Stats bar */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-amber-50/50 dark:bg-amber-950/10 border border-amber-100 dark:border-amber-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-amber-500/10 text-amber-600 dark:text-amber-400 rounded-xl shrink-0">
            <Scale size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Ochiq shikoyatlar</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{totalOpenCount} ta ariza</p>
          </div>
        </div>

        <div className="bg-sky-50/50 dark:bg-sky-950/10 border border-sky-100 dark:border-sky-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-sky-500/10 text-sky-600 dark:text-sky-400 rounded-xl shrink-0">
            <HelpCircle size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Ko'rilayotgan shikoyatlar</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{investigatingCount} ta nizo</p>
          </div>
        </div>

        <div className="bg-green-50/50 dark:bg-green-950/10 border border-green-100 dark:border-green-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-green-500/10 text-green-600 dark:text-green-400 rounded-xl shrink-0">
            <CheckCircle2 size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Hal etilgan nizolar</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{resolvedCount} ta yakunlangan</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6">
        {/* Active disputes */}
        <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden p-6 space-y-4">
          <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">Faol shikoyat va nizolar</h2>
          {openDisputes.length === 0 ? (
            <EmptyState title="Ochiq shikoyatlar yo'q" />
          ) : (
            <div className="space-y-4">
              {openDisputes.map((d) => (
                <div key={d.id} className="border border-gray-100 dark:border-slate-700 rounded-2xl p-5 space-y-3 hover:shadow-sm transition bg-gray-50/20 dark:bg-slate-900/10">
                  <div className="flex justify-between items-start gap-3">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <p className="font-bold text-gray-900 dark:text-slate-100 text-sm">{d.projectTitle}</p>
                        <Badge status={d.status} />
                      </div>
                      <p className="text-[11px] text-gray-500 dark:text-slate-400 mt-1">
                        <span className="font-semibold text-primary-600">{d.filedByName}</span> tomonidan <span className="font-semibold text-red-600">{d.againstUserName}</span> ustidan — <span className="font-bold text-gray-600 dark:text-slate-300">{d.disputeType}</span>
                      </p>
                    </div>
                    <div className="flex gap-1.5 shrink-0">
                      <Button variant="ghost" size="sm" icon={Eye} onClick={() => setSelectedDispute(d)}>Batafsil</Button>
                      {d.status === 'OPEN' && (
                        <Button variant="secondary" size="sm" onClick={() => handleInvestigate(d.id)}>Tekshiruvga olish</Button>
                      )}
                      <Button variant="primary" size="sm" onClick={() => setResolveTarget(d.id)}>Hal qilish</Button>
                    </div>
                  </div>
                  <p className="text-xs text-gray-600 dark:text-slate-300 leading-relaxed font-semibold bg-white dark:bg-slate-900/40 p-3 rounded-xl border border-gray-100 dark:border-slate-800 line-clamp-2">
                    {d.description}
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Closed disputes */}
        <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden p-6 space-y-4">
          <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">Yopilgan / Hal qilingan shikoyatlar</h2>
          <div className="space-y-4">
            {closedDisputes.map((d) => (
              <div key={d.id} className="border border-gray-100 dark:border-slate-700 rounded-2xl p-5 space-y-3 bg-gray-50/20 dark:bg-slate-900/10">
                <div className="flex justify-between items-start gap-3">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <p className="font-bold text-gray-900 dark:text-slate-100 text-sm">{d.projectTitle}</p>
                      <Badge status={d.status} />
                    </div>
                    <p className="text-[11px] text-gray-500 dark:text-slate-400 mt-1">
                      <span className="font-semibold text-primary-600">{d.filedByName}</span> da'vosi
                    </p>
                  </div>
                  {d.status === 'RESOLVED' && (
                    <Button variant="secondary" size="sm" onClick={() => handleClose(d.id)}>Yopish</Button>
                  )}
                </div>
                <DisputeList disputes={[d]} showParties />
              </div>
            ))}
            {closedDisputes.length === 0 && <EmptyState title="Yopilgan shikoyatlar yo'q" />}
          </div>
        </div>
      </div>

      <Pagination pageNumber={pageInfo.pageNumber} totalPages={pageInfo.totalPages} onPageChange={fetchData} />

      {/* Details Modal */}
      {selectedDispute && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm transition-opacity">
          <div className="relative w-full max-w-lg bg-white dark:bg-slate-800 rounded-3xl shadow-xl overflow-hidden animate-in fade-in zoom-in duration-200 border border-gray-100 dark:border-slate-700">
            <div className="px-6 py-5 border-b border-gray-100 dark:border-slate-700 flex justify-between items-center bg-gray-50/50 dark:bg-slate-900/30">
              <div>
                <h3 className="text-lg font-bold text-gray-900 dark:text-slate-100">Nizo tafsilotlari</h3>
                <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">Turi: {selectedDispute.disputeType}</p>
              </div>
              <button onClick={() => setSelectedDispute(null)} className="p-2 rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 hover:text-gray-600">&times;</button>
            </div>

            <div className="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
              <div className="flex items-center gap-4 pb-4 border-b border-gray-100 dark:border-slate-700">
                <div className="w-12 h-12 rounded-xl bg-red-50 dark:bg-red-950/40 text-red-600 dark:text-red-400 flex items-center justify-center font-extrabold shrink-0">
                  <Scale size={24} />
                </div>
                <div>
                  <h4 className="text-base font-bold text-gray-900 dark:text-slate-100">{selectedDispute.projectTitle}</h4>
                  <Badge status={selectedDispute.status} />
                </div>
              </div>

              <div className="bg-gray-50 dark:bg-slate-900/50 p-4 rounded-xl space-y-2 text-xs">
                <p className="font-bold text-gray-400 uppercase tracking-wider">Tomonlar</p>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <span className="text-[10px] text-gray-400 block font-bold uppercase">Shikoyat qiluvchi</span>
                    <span className="font-bold text-gray-800 dark:text-slate-200 text-xs">{selectedDispute.filedByName}</span>
                  </div>
                  <div>
                    <span className="text-[10px] text-gray-400 block font-bold uppercase">Keltirilgan tomon</span>
                    <span className="font-bold text-gray-800 dark:text-slate-200 text-xs">{selectedDispute.againstUserName}</span>
                  </div>
                </div>
              </div>

              <div className="space-y-1">
                <p className="text-xs text-gray-400 font-bold uppercase">Nizo tavsifi</p>
                <p className="text-sm text-gray-700 dark:text-slate-200 leading-relaxed bg-gray-50 dark:bg-slate-900/40 p-4 rounded-xl border border-gray-100 dark:border-slate-800 whitespace-pre-line">
                  {selectedDispute.description}
                </p>
              </div>

              {selectedDispute.resolution && (
                <div className="p-4 bg-green-50 dark:bg-green-950/20 border border-green-100 dark:border-green-900/30 rounded-2xl space-y-1">
                  <p className="text-xs text-green-700 dark:text-green-400 font-bold uppercase">Moderator qarori (Yechim)</p>
                  <p className="text-xs text-green-800 dark:text-green-300 font-medium whitespace-pre-line">{selectedDispute.resolution}</p>
                </div>
              )}
            </div>

            <div className="px-6 py-4 border-t border-gray-100 dark:border-slate-700 bg-gray-50/50 dark:bg-slate-900/30 flex justify-end gap-2">
              <Button variant="secondary" onClick={() => setSelectedDispute(null)}>Yopish</Button>
              {selectedDispute.status === 'OPEN' && (
                <Button variant="secondary" onClick={() => handleInvestigate(selectedDispute.id)}>Tekshiruvga olish</Button>
              )}
              {(selectedDispute.status === 'OPEN' || selectedDispute.status === 'INVESTIGATING') && (
                <Button variant="primary" onClick={() => setResolveTarget(selectedDispute.id)}>Hal qilish</Button>
              )}
              {selectedDispute.status === 'RESOLVED' && (
                <Button variant="primary" onClick={() => handleClose(selectedDispute.id)}>Yopish</Button>
              )}
            </div>
          </div>
        </div>
      )}

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
