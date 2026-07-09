import React, { useEffect, useState } from 'react';
import { getProjects } from '../../api/projects.api';
import { formatAmount } from '../../utils/format';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import DataTable from '../../components/ui/DataTable';
import ReportUploadModal from '../../components/reports/ReportUploadModal';
import { useDebounce } from '../../hooks/useDebounce';

const STATUS_OPTIONS = [
  { value: 'ACTIVE', label: 'Faol' },
  { value: 'FUNDING', label: "Yig'ilmoqda" },
];

const VERIFIER_REPORT_TYPES = [{ value: 'VERIFICATION', label: 'Dala tashrifi xulosasi' }];

// VERIFIER's entire job (TZ F-4.4): visit a project in person and file a
// VERIFICATION-type report - the same submission form farmers use for their
// own reports (ReportUploadModal), just restricted to the one report type and
// scoped to any ACTIVE/FUNDING project rather than only the farmer's own.
const VerifierDashboard = () => {
  const [projects, setProjects] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [status, setStatus] = useState('ACTIVE');
  const [search, setSearch] = useState('');
  const [reportTarget, setReportTarget] = useState(null);
  const debouncedSearch = useDebounce(search, 350);

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getProjects(status, page, 12, { q: debouncedSearch || undefined });
      setProjects(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError('Loyihalarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(0); }, [status, debouncedSearch]);

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-slate-900 p-6 md:p-12">
      <div className="max-w-5xl mx-auto space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-slate-100">Dala hisobotlari (Verifikator)</h1>
          <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">
            Tashrif buyurgan loyihangiz uchun dala tashrifi xulosasini kiriting
          </p>
        </div>

        <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm">
          <div className="p-6 border-b border-gray-100 dark:border-slate-700 flex gap-2">
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
            page={{ ...pageInfo, onPageChange: fetchData }}
            columns={[
              { key: 'title', header: 'Loyiha nomi', render: (p) => <span className="font-semibold text-xs">{p.title}</span> },
              { key: 'farmerName', header: 'Fermer', render: (p) => <span className="text-xs">{p.farmerName}</span> },
              { key: 'region', header: 'Viloyat', render: (p) => <span className="text-xs font-bold text-gray-400">{p.region}</span> },
              { key: 'targetAmount', header: 'Maqsad summa', render: (p) => <span className="font-bold text-xs">{formatAmount(p.targetAmount)}</span> },
              { key: 'status', header: 'Holat', render: (p) => <Badge status={p.status} /> },
              {
                key: 'actions', header: 'Amallar', align: 'right',
                render: (p) => (
                  <div className="flex justify-end">
                    <Button variant="primary" size="sm" onClick={() => setReportTarget(p.id)}>Xulosa kiritish</Button>
                  </div>
                ),
              },
            ]}
            renderMobileCard={(p) => (
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-xs">{p.title}</span>
                  <Badge status={p.status} />
                </div>
                <p className="text-xs text-gray-600 dark:text-slate-300">{p.farmerName} · {p.region} · {formatAmount(p.targetAmount)}</p>
                <div className="pt-1">
                  <Button variant="primary" size="sm" onClick={() => setReportTarget(p.id)}>Xulosa kiritish</Button>
                </div>
              </div>
            )}
          />
        </div>
      </div>

      {reportTarget && (
        <ReportUploadModal
          projectId={reportTarget}
          reportTypes={VERIFIER_REPORT_TYPES}
          onClose={() => setReportTarget(null)}
          onSubmitted={() => setReportTarget(null)}
        />
      )}
    </div>
  );
};

export default VerifierDashboard;
