import React, { useEffect, useState } from 'react';
import { FileText } from 'lucide-react';
import { getPendingVetInspections, verifyVetInspection } from '../../../api/vet.api';
import { formatDate } from '../../../utils/format';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';

const DocumentChips = ({ urls = [] }) => {
  if (!urls.length) return <span className="text-xs text-gray-400 dark:text-slate-500">Hujjat yo'q</span>;
  return (
    <div className="flex gap-2 flex-wrap">
      {urls.map((url, i) =>
        url.toLowerCase().endsWith('.pdf') ? (
          <a
            key={url}
            href={url}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-1 px-2 py-1 rounded-lg border border-gray-200 dark:border-slate-600 text-[10px] font-bold text-gray-600 dark:text-slate-300 hover:border-primary-400"
          >
            <FileText size={12} /> PDF {i + 1}
          </a>
        ) : (
          <a key={url} href={url} target="_blank" rel="noreferrer" className="w-14 h-14 rounded-lg overflow-hidden border border-gray-200 dark:border-slate-600 shrink-0">
            <img src={url} alt={`Hujjat ${i + 1}`} className="w-full h-full object-cover" />
          </a>
        )
      )}
    </div>
  );
};

// Admin review queue for farmer-uploaded vet conclusions - VERIFIED ones become
// a public trust signal on the project page (see ProjectDetailPage).
const VetInspectionsTab = ({ onActionDone }) => {
  const [inspections, setInspections] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getPendingVetInspections(page, 12);
      setInspections(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError('Veterinar hujjatlarini yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(0); }, []);

  const runAction = async (id, approve, comment) => {
    try {
      await verifyVetInspection(id, approve, comment);
      showToast(approve ? 'Hujjat tasdiqlandi' : 'Hujjat rad etildi');
      fetchData(pageInfo.pageNumber);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  return (
    <div>
      <div className="p-6 border-b border-gray-100 dark:border-slate-700">
        <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">Kutilayotgan veterinar hujjatlari</h2>
        <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">
          Tasdiqlangan hujjatlar loyiha sahifasida investorlarga ochiq ishonch belgisi sifatida ko'rsatiladi
        </p>
      </div>

      <DataTable
        loading={loading}
        error={error}
        onRetry={() => fetchData(pageInfo.pageNumber)}
        rows={inspections}
        emptyTitle="Tasdiqlanish kutilayotgan hujjatlar yo'q"
        page={{ ...pageInfo, onPageChange: fetchData }}
        columns={[
          { key: 'projectTitle', header: 'Loyiha', render: (v) => <span className="font-semibold text-xs">{v.projectTitle}</span> },
          { key: 'vetName', header: 'Veterinar', render: (v) => <span className="text-xs">{v.vetName}{v.vetLicenseNo ? ` (${v.vetLicenseNo})` : ''}</span> },
          { key: 'inspectionDate', header: 'Sana', render: (v) => <span className="text-xs">{formatDate(v.inspectionDate)}</span> },
          { key: 'healthStatus', header: 'Holat', render: (v) => <Badge status={v.healthStatus} /> },
          { key: 'documentUrls', header: 'Hujjatlar', render: (v) => <DocumentChips urls={v.documentUrls || []} /> },
          {
            key: 'actions', header: 'Amallar', align: 'right',
            render: (v) => (
              <div className="flex justify-end gap-2">
                <Button variant="danger" size="sm" onClick={() => setRejectTarget(v.id)}>Rad etish</Button>
                <Button variant="primary" size="sm" onClick={() => runAction(v.id, true, null)}>Tasdiqlash</Button>
              </div>
            ),
          },
        ]}
        renderMobileCard={(v) => (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="font-bold text-xs">{v.projectTitle}</span>
              <Badge status={v.healthStatus} />
            </div>
            <p className="text-xs text-gray-600 dark:text-slate-300">{v.vetName} · {formatDate(v.inspectionDate)}</p>
            {v.conclusion && <p className="text-xs text-gray-500 dark:text-slate-400">{v.conclusion}</p>}
            <DocumentChips urls={v.documentUrls || []} />
            <div className="flex gap-2 pt-1">
              <Button variant="danger" size="sm" onClick={() => setRejectTarget(v.id)}>Rad etish</Button>
              <Button variant="primary" size="sm" onClick={() => runAction(v.id, true, null)}>Tasdiqlash</Button>
            </div>
          </div>
        )}
      />

      <PromptDialog
        open={!!rejectTarget}
        title="Veterinar hujjatini rad etish"
        label="Izoh"
        tone="danger"
        confirmLabel="Rad etish"
        onCancel={() => setRejectTarget(null)}
        onConfirm={(comment) => { runAction(rejectTarget, false, comment); setRejectTarget(null); }}
      />
    </div>
  );
};

export default VetInspectionsTab;
