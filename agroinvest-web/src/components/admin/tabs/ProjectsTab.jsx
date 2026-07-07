import React, { useEffect, useState } from 'react';
import { getProjects, changeProjectStatus } from '../../../api/projects.api';
import { formatAmount } from '../../../utils/format';
import { ASSET_TYPE_META, getAssetTypeMeta } from '../../../utils/assetType';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';
import { useDebounce } from '../../../hooks/useDebounce';

const STATUS_OPTIONS = [
  { value: '', label: 'Barchasi' },
  { value: 'PENDING', label: 'Kutilmoqda' },
  { value: 'APPROVED', label: 'Tasdiqlangan' },
  { value: 'FUNDING', label: "Yig'ilmoqda" },
  { value: 'ACTIVE', label: 'Faol' },
  { value: 'COMPLETED', label: 'Yakunlangan' },
  { value: 'CANCELLED', label: 'Bekor qilingan' },
];

// Previously this tab only ever fetched status=PENDING, hardcoded, so admins had
// no way to browse any other status from here. Status is now a real filter.
const ProjectsTab = ({ onActionDone }) => {
  const [projects, setProjects] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const [status, setStatus] = useState('PENDING');
  const [assetType, setAssetType] = useState('');
  const [search, setSearch] = useState('');
  const debouncedSearch = useDebounce(search, 350);
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getProjects(status || undefined, page, 12, { assetType: assetType || undefined, q: debouncedSearch || undefined });
      setProjects(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError('Loyihalarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(0); }, [status, assetType, debouncedSearch]);

  const runAction = async (id, approved, reason) => {
    try {
      await changeProjectStatus(id, approved ? 'FUNDING' : 'CANCELLED', reason);
      showToast(approved ? "Loyiha tasdiqlandi va mablag' yig'ishga o'tdi" : 'Loyiha rad etildi');
      fetchData(pageInfo.pageNumber);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  return (
    <div>
      <div className="p-6 border-b border-gray-100 dark:border-slate-700 space-y-3">
        <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">Loyihalar</h2>
        <div className="flex gap-2 overflow-x-auto pb-1">
          {STATUS_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              onClick={() => setStatus(opt.value)}
              className={`px-3.5 py-1.5 text-xs font-bold rounded-full border transition whitespace-nowrap ${
                status === opt.value
                  ? 'bg-primary-600 border-transparent text-white'
                  : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-600 text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700'
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>
      </div>

      <DataTable
        loading={loading}
        error={error}
        onRetry={() => fetchData(pageInfo.pageNumber)}
        rows={projects}
        emptyTitle="Loyihalar topilmadi"
        searchable
        search={search}
        onSearchChange={setSearch}
        searchPlaceholder="Nomi yoki viloyat bo'yicha qidirish..."
        filters={
          <select
            value={assetType}
            onChange={(e) => setAssetType(e.target.value)}
            className="px-3 py-2 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500"
          >
            <option value="">Barcha turlar</option>
            {Object.entries(ASSET_TYPE_META).map(([key, meta]) => (
              <option key={key} value={key}>{meta.label}</option>
            ))}
          </select>
        }
        page={{ ...pageInfo, onPageChange: fetchData }}
        columns={[
          {
            key: 'title',
            header: 'Loyiha nomi',
            render: (p) => {
              const meta = getAssetTypeMeta(p.assetType);
              const Icon = meta.icon;
              return (
                <div className="flex items-center gap-2">
                  <Icon size={15} style={{ color: meta.color }} className="shrink-0" />
                  <span className="font-semibold">{p.title}</span>
                </div>
              );
            },
          },
          { key: 'region', header: 'Viloyat', render: (p) => <span className="text-xs font-bold text-gray-400">{p.region}</span> },
          { key: 'targetAmount', header: 'Maqsad summa', render: (p) => <span className="font-bold">{formatAmount(p.targetAmount)}</span> },
          { key: 'status', header: 'Holat', render: (p) => <Badge status={p.status} /> },
          { key: 'returns', header: 'Foyda / Muddat', render: (p) => <span className="text-xs font-bold text-green-600 dark:text-green-400">+{p.expectedReturnPct}% / {p.durationDays} kun</span> },
          {
            key: 'actions',
            header: 'Amallar',
            align: 'right',
            render: (p) => p.status === 'PENDING' ? (
              <div className="flex justify-end gap-2">
                <Button variant="danger" size="sm" onClick={() => setRejectTarget(p.id)}>Rad etish</Button>
                <Button variant="primary" size="sm" onClick={() => runAction(p.id, true, null)}>Tasdiqlash</Button>
              </div>
            ) : null,
          },
        ]}
        renderMobileCard={(p) => {
          const meta = getAssetTypeMeta(p.assetType);
          const Icon = meta.icon;
          return (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 min-w-0">
                  <Icon size={15} style={{ color: meta.color }} className="shrink-0" />
                  <p className="font-semibold text-gray-900 dark:text-slate-100 truncate">{p.title}</p>
                </div>
                <Badge status={p.status} />
              </div>
              <p className="text-xs text-gray-500 dark:text-slate-400">{p.region} · {formatAmount(p.targetAmount)} · +{p.expectedReturnPct}%</p>
              {p.status === 'PENDING' && (
                <div className="flex gap-2 pt-1">
                  <Button variant="danger" size="sm" onClick={() => setRejectTarget(p.id)}>Rad etish</Button>
                  <Button variant="primary" size="sm" onClick={() => runAction(p.id, true, null)}>Tasdiqlash</Button>
                </div>
              )}
            </div>
          );
        }}
      />

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
