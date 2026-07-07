import React, { useEffect, useState } from 'react';
import { getUnverifiedReports, verifyReport } from '../../../api/reports.api';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import MediaThumbnails from '../../ui/MediaThumbnails';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';

const ReportsTab = () => {
  const [reports, setReports] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getUnverifiedReports(page, 12);
      setReports(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError('Hisobotlarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(0); }, []);

  const runAction = async (id, verify, comment) => {
    try {
      await verifyReport(id, verify, comment);
      showToast(verify ? 'Hisobot tasdiqlandi' : 'Hisobot rad etildi');
      fetchData(pageInfo.pageNumber);
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  return (
    <div>
      <div className="p-6 border-b border-gray-100 dark:border-slate-700">
        <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">Kutilayotgan progress hisobotlari</h2>
      </div>

      <DataTable
        loading={loading}
        error={error}
        onRetry={() => fetchData(pageInfo.pageNumber)}
        rows={reports}
        emptyTitle="Tasdiqlanish kutilayotgan hisobotlar yo'q"
        page={{ ...pageInfo, onPageChange: fetchData }}
        columns={[
          { key: 'id', header: 'Hisobot ID', render: (r) => <span className="text-xs font-mono text-gray-400">{r.id.substring(0, 8)}...</span> },
          { key: 'reportType', header: 'Turi', render: (r) => <span className="font-bold text-xs text-yellow-600 dark:text-yellow-400">{r.reportType}</span> },
          { key: 'notes', header: 'Izoh', render: (r) => <span className="text-xs max-w-xs truncate block">{r.notes}</span> },
          { key: 'media', header: 'Media', render: (r) => <MediaThumbnails urls={r.mediaUrls || []} /> },
          {
            key: 'actions',
            header: 'Amallar',
            align: 'right',
            render: (r) => (
              <div className="flex justify-end gap-2">
                <Button variant="danger" size="sm" onClick={() => setRejectTarget(r.id)}>Rad etish</Button>
                <Button variant="primary" size="sm" onClick={() => runAction(r.id, true, null)}>Tasdiqlash</Button>
              </div>
            ),
          },
        ]}
        renderMobileCard={(r) => (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="font-bold text-xs text-yellow-600 dark:text-yellow-400">{r.reportType}</span>
              <span className="text-xs font-mono text-gray-400">{r.id.substring(0, 8)}...</span>
            </div>
            <p className="text-xs text-gray-600 dark:text-slate-300">{r.notes}</p>
            <MediaThumbnails urls={r.mediaUrls || []} />
            <div className="flex gap-2 pt-1">
              <Button variant="danger" size="sm" onClick={() => setRejectTarget(r.id)}>Rad etish</Button>
              <Button variant="primary" size="sm" onClick={() => runAction(r.id, true, null)}>Tasdiqlash</Button>
            </div>
          </div>
        )}
      />

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
