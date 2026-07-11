import React, { useEffect, useState } from 'react';
import { getUnverifiedReports, getAllReports, verifyReport } from '../../../api/reports.api';
import { ClipboardCheck, ClipboardList, CalendarCheck, Eye, MapPin, BadgeCheck, Clock } from 'lucide-react';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import MediaThumbnails from '../../ui/MediaThumbnails';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';
import { formatDate } from '../../../utils/format';

// Real backend ReportType values (the old PROGRESS/VET/EXPENSE options never
// matched anything).
const REPORT_TYPE_META = {
  DAILY: { label: 'Kunlik', className: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-400' },
  ROUTINE: { label: 'Muntazam', className: 'bg-sky-50 text-sky-700 dark:bg-sky-950 dark:text-sky-400' },
  EMERGENCY: { label: 'Favqulodda', className: 'bg-red-50 text-red-700 dark:bg-red-950 dark:text-red-400' },
  VERIFICATION: { label: 'Tekshiruv', className: 'bg-purple-50 text-purple-700 dark:bg-purple-950 dark:text-purple-400' },
  FINAL: { label: 'Yakuniy', className: 'bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-400' },
  COMPLETION: { label: 'Tugatish', className: 'bg-gray-100 text-gray-600 dark:bg-slate-700 dark:text-slate-300' },
};

const METRIC_LABELS = {
  headcount: 'Bosh soni',
  deaths: "O'lim",
  feedKg: 'Yem (kg)',
  avgWeightKg: "O'rtacha vazn (kg)",
};

const TypeBadge = ({ type }) => {
  const meta = REPORT_TYPE_META[type] || { label: type, className: 'bg-gray-100 text-gray-600' };
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold ${meta.className}`}>
      {meta.label}
    </span>
  );
};

const VerifiedBadge = ({ verified }) => (
  verified ? (
    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-400">
      <BadgeCheck size={12} /> Tasdiqlangan
    </span>
  ) : (
    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-bold bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-400">
      <Clock size={12} /> Kutilmoqda
    </span>
  )
);

// Compact daily-log metrics (headcount, deaths, feed, weight) for table rows.
const MetricsInline = ({ metrics }) => {
  if (!metrics) return <span className="text-xs text-gray-400">—</span>;
  return (
    <div className="flex flex-wrap gap-x-3 gap-y-0.5">
      {metrics.headcount != null && <span className="text-xs font-bold text-gray-700 dark:text-slate-200">{metrics.headcount} bosh</span>}
      {metrics.deaths != null && metrics.deaths > 0 && <span className="text-xs font-bold text-red-600 dark:text-red-400">{metrics.deaths} o'lim</span>}
      {metrics.feedKg != null && <span className="text-xs text-gray-500 dark:text-slate-400">{metrics.feedKg} kg yem</span>}
      {metrics.avgWeightKg != null && <span className="text-xs text-gray-500 dark:text-slate-400">~{metrics.avgWeightKg} kg</span>}
    </div>
  );
};

const ReportsTab = () => {
  const [view, setView] = useState('PENDING'); // PENDING = verification queue, ALL = full history
  const [reports, setReports] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1, totalElements: 0 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const [selectedReport, setSelectedReport] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [reportTypeFilter, setReportTypeFilter] = useState('');
  const [verifiedFilter, setVerifiedFilter] = useState('');
  const { showToast } = useToast();

  const fetchData = async (page = 0, opts = {}) => {
    const activeView = opts.view ?? view;
    const typeFilter = opts.reportType ?? reportTypeFilter;
    const verFilter = opts.verified ?? verifiedFilter;
    setLoading(true);
    setError(null);
    try {
      const res = activeView === 'PENDING'
        ? await getUnverifiedReports(page, 15)
        : await getAllReports(page, 15, { reportType: typeFilter, verified: verFilter });
      setReports(res.data.content || []);
      setPageInfo({
        pageNumber: res.data.pageNumber,
        totalPages: res.data.totalPages,
        totalElements: res.data.totalElements ?? (res.data.content || []).length,
      });
    } catch (err) {
      setError('Hisobotlarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(0); }, []);

  const switchView = (nextView) => {
    if (nextView === view) return;
    setView(nextView);
    setReportTypeFilter('');
    setVerifiedFilter('');
    setSearchQuery('');
    fetchData(0, { view: nextView, reportType: '', verified: '' });
  };

  const runAction = async (id, verify, comment) => {
    try {
      await verifyReport(id, verify, comment);
      showToast(verify ? 'Hisobot tasdiqlandi' : 'Hisobot rad etildi');
      fetchData(pageInfo.pageNumber);
      setSelectedReport(null);
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  // In PENDING view the type filter is client-side (the queue endpoint has no
  // filters); in ALL view type/verified are already applied server-side.
  const filteredReports = reports.filter(r => {
    const q = searchQuery.toLowerCase();
    const matchesSearch = !q
      || r.notes?.toLowerCase().includes(q)
      || r.projectTitle?.toLowerCase().includes(q)
      || r.submittedByName?.toLowerCase().includes(q)
      || r.id?.toLowerCase().includes(q);
    const matchesType = view === 'PENDING' && reportTypeFilter ? r.reportType === reportTypeFilter : true;
    return matchesSearch && matchesType;
  });

  const dailyCount = reports.filter(r => r.reportType === 'DAILY').length;
  const verifiedCount = reports.filter(r => r.isVerified || r.verified).length;

  const isVerified = (r) => r.isVerified === true || r.verified === true;

  return (
    <div className="space-y-6 p-6">
      {/* View toggle */}
      <div className="inline-flex bg-gray-100 dark:bg-slate-900 rounded-2xl p-1 gap-1">
        <button
          onClick={() => switchView('PENDING')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition ${view === 'PENDING'
            ? 'bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 shadow-sm'
            : 'text-gray-500 dark:text-slate-400 hover:text-gray-700'}`}
        >
          Tasdiqlash navbati
        </button>
        <button
          onClick={() => switchView('ALL')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition ${view === 'ALL'
            ? 'bg-white dark:bg-slate-700 text-gray-900 dark:text-slate-100 shadow-sm'
            : 'text-gray-500 dark:text-slate-400 hover:text-gray-700'}`}
        >
          Barcha hisobotlar
        </button>
      </div>

      {/* Stats bar */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-amber-50/50 dark:bg-amber-950/10 border border-amber-100 dark:border-amber-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-amber-500/10 text-amber-600 dark:text-amber-400 rounded-xl shrink-0">
            <ClipboardCheck size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">
              {view === 'PENDING' ? 'Tasdiqlanishi kutilmoqda' : 'Jami hisobotlar'}
            </p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{pageInfo.totalElements} ta</p>
          </div>
        </div>

        <div className="bg-emerald-50/50 dark:bg-emerald-950/10 border border-emerald-100 dark:border-emerald-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 rounded-xl shrink-0">
            <CalendarCheck size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Kunlik hisobotlar (sahifada)</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{dailyCount} ta</p>
          </div>
        </div>

        <div className="bg-sky-50/50 dark:bg-sky-950/10 border border-sky-100 dark:border-sky-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-sky-500/10 text-sky-600 dark:text-sky-400 rounded-xl shrink-0">
            <ClipboardList size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Tasdiqlangan (sahifada)</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{verifiedCount} ta</p>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden">
        <DataTable
          loading={loading}
          error={error}
          onRetry={() => fetchData(pageInfo.pageNumber)}
          rows={filteredReports}
          emptyTitle={view === 'PENDING' ? "Tasdiqlanish kutilayotgan hisobotlar yo'q" : "Hisobotlar topilmadi"}
          searchable
          search={searchQuery}
          onSearchChange={setSearchQuery}
          searchPlaceholder="Loyiha, fermer yoki izoh bo'yicha qidirish..."
          filters={
            <>
              <select
                value={reportTypeFilter}
                onChange={(e) => {
                  const val = e.target.value;
                  setReportTypeFilter(val);
                  if (view === 'ALL') fetchData(0, { reportType: val });
                }}
                className="px-3 py-2 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500"
              >
                <option value="">Barcha turlar</option>
                {Object.entries(REPORT_TYPE_META).map(([value, meta]) => (
                  <option key={value} value={value}>{meta.label}</option>
                ))}
              </select>
              {view === 'ALL' && (
                <select
                  value={verifiedFilter}
                  onChange={(e) => {
                    const val = e.target.value;
                    setVerifiedFilter(val);
                    fetchData(0, { verified: val });
                  }}
                  className="px-3 py-2 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500"
                >
                  <option value="">Barcha holatlar</option>
                  <option value="true">Tasdiqlangan</option>
                  <option value="false">Kutilmoqda</option>
                </select>
              )}
            </>
          }
          page={{ ...pageInfo, onPageChange: fetchData }}
          columns={[
            { key: 'reportType', header: 'Turi', render: (r) => <TypeBadge type={r.reportType} /> },
            { key: 'project', header: 'Loyiha / Fermer', render: (r) => (
              <div>
                <p className="text-xs font-bold text-gray-800 dark:text-slate-200 max-w-[180px] truncate">{r.projectTitle || '—'}</p>
                <p className="text-[11px] text-gray-500 dark:text-slate-400">{r.submittedByName || '—'}</p>
              </div>
            )},
            { key: 'metrics', header: "Ko'rsatkichlar", render: (r) => <MetricsInline metrics={r.metrics} /> },
            { key: 'notes', header: 'Izoh', render: (r) => <span className="text-xs max-w-[160px] truncate block text-gray-700 dark:text-slate-300 font-semibold">{r.notes}</span> },
            { key: 'media', header: 'Media', render: (r) => <MediaThumbnails urls={r.mediaUrls || []} /> },
            { key: 'createdAt', header: 'Sana', render: (r) => <span className="text-xs text-gray-500 dark:text-slate-400">{formatDate(r.createdAt)}</span> },
            { key: 'status', header: 'Holat', render: (r) => <VerifiedBadge verified={isVerified(r)} /> },
            {
              key: 'actions',
              header: 'Amallar',
              align: 'right',
              render: (r) => (
                <div className="flex justify-end gap-1.5">
                  <Button variant="ghost" size="sm" icon={Eye} onClick={() => setSelectedReport(r)}>Batafsil</Button>
                  {!isVerified(r) && (
                    <>
                      <Button variant="danger" size="sm" onClick={() => setRejectTarget(r.id)}>Rad etish</Button>
                      <Button variant="primary" size="sm" onClick={() => runAction(r.id, true, null)}>Tasdiqlash</Button>
                    </>
                  )}
                </div>
              ),
            },
          ]}
          renderMobileCard={(r) => (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <TypeBadge type={r.reportType} />
                <VerifiedBadge verified={isVerified(r)} />
              </div>
              <p className="text-xs font-bold text-gray-800 dark:text-slate-200">{r.projectTitle || '—'}</p>
              <p className="text-[11px] text-gray-500 dark:text-slate-400">{r.submittedByName || '—'} · {formatDate(r.createdAt)}</p>
              <MetricsInline metrics={r.metrics} />
              {r.notes && <p className="text-xs text-gray-600 dark:text-slate-300 font-semibold leading-relaxed line-clamp-2">{r.notes}</p>}
              <MediaThumbnails urls={r.mediaUrls || []} />
              <div className="flex gap-2 pt-1">
                <Button variant="secondary" size="sm" className="flex-1" onClick={() => setSelectedReport(r)}>Batafsil</Button>
                {!isVerified(r) && (
                  <>
                    <Button variant="danger" size="sm" className="flex-1" onClick={() => setRejectTarget(r.id)}>Rad etish</Button>
                    <Button variant="primary" size="sm" className="flex-1" onClick={() => runAction(r.id, true, null)}>Tasdiqlash</Button>
                  </>
                )}
              </div>
            </div>
          )}
        />
      </div>

      {/* Details modal */}
      {selectedReport && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm transition-opacity">
          <div className="relative w-full max-w-lg bg-white dark:bg-slate-800 rounded-3xl shadow-xl overflow-hidden animate-in fade-in zoom-in duration-200 border border-gray-100 dark:border-slate-700">
            <div className="px-6 py-5 border-b border-gray-100 dark:border-slate-700 flex justify-between items-center bg-gray-50/50 dark:bg-slate-900/30">
              <div>
                <h3 className="text-lg font-bold text-gray-900 dark:text-slate-100">Hisobot batafsil</h3>
                <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">Sana: {formatDate(selectedReport.createdAt)}</p>
              </div>
              <button onClick={() => setSelectedReport(null)} className="p-2 rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 hover:text-gray-600">&times;</button>
            </div>

            <div className="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
              <div className="flex items-center justify-between pb-4 border-b border-gray-100 dark:border-slate-700">
                <div>
                  <p className="text-sm font-bold text-gray-900 dark:text-slate-100">{selectedReport.projectTitle || '—'}</p>
                  <p className="text-xs text-gray-500 dark:text-slate-400">Topshirdi: {selectedReport.submittedByName || '—'}</p>
                  <p className="text-[11px] text-gray-400 font-mono mt-0.5">ID: {selectedReport.id}</p>
                </div>
                <div className="flex flex-col items-end gap-1.5">
                  <TypeBadge type={selectedReport.reportType} />
                  <VerifiedBadge verified={isVerified(selectedReport)} />
                </div>
              </div>

              {selectedReport.metrics && (
                <div className="space-y-2">
                  <p className="text-xs text-gray-400 font-bold uppercase">Kunlik ko'rsatkichlar</p>
                  <div className="grid grid-cols-2 gap-2">
                    {Object.entries(METRIC_LABELS).map(([key, label]) => (
                      selectedReport.metrics[key] != null && (
                        <div key={key} className="bg-gray-50 dark:bg-slate-900/40 border border-gray-100 dark:border-slate-800 rounded-xl p-3">
                          <p className="text-[11px] text-gray-400 font-bold uppercase">{label}</p>
                          <p className={`text-lg font-black mt-0.5 ${key === 'deaths' && selectedReport.metrics[key] > 0 ? 'text-red-600 dark:text-red-400' : 'text-gray-900 dark:text-slate-100'}`}>
                            {selectedReport.metrics[key]}
                          </p>
                        </div>
                      )
                    ))}
                  </div>
                  {selectedReport.metrics.healthNote && (
                    <p className="text-sm text-gray-700 dark:text-slate-200 bg-gray-50 dark:bg-slate-900/40 p-3 rounded-xl border border-gray-100 dark:border-slate-800">
                      {selectedReport.metrics.healthNote}
                    </p>
                  )}
                </div>
              )}

              <div className="space-y-1">
                <p className="text-xs text-gray-400 font-bold uppercase">Hisobot izohi (Tavsif)</p>
                <p className="text-sm text-gray-700 dark:text-slate-200 leading-relaxed bg-gray-50 dark:bg-slate-900/40 p-4 rounded-xl border border-gray-100 dark:border-slate-800 whitespace-pre-line">
                  {selectedReport.notes || "Izoh yo'q"}
                </p>
              </div>

              {selectedReport.geoLat != null && (
                <div className="flex items-center gap-2 text-xs text-gray-500 dark:text-slate-400">
                  <MapPin size={14} className="text-emerald-600" />
                  <span>GPS: {selectedReport.geoLat}, {selectedReport.geoLng}</span>
                  <a
                    href={`https://maps.google.com/?q=${selectedReport.geoLat},${selectedReport.geoLng}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-emerald-600 font-bold hover:underline"
                  >
                    Xaritada ochish
                  </a>
                </div>
              )}

              {selectedReport.adminComment && (
                <div className="space-y-1">
                  <p className="text-xs text-gray-400 font-bold uppercase">Admin izohi</p>
                  <p className="text-sm text-gray-700 dark:text-slate-200 bg-amber-50/50 dark:bg-amber-950/20 p-3 rounded-xl border border-amber-100 dark:border-amber-900/30">
                    {selectedReport.adminComment}
                  </p>
                </div>
              )}

              {selectedReport.mediaUrls && selectedReport.mediaUrls.length > 0 && (
                <div className="space-y-2">
                  <p className="text-xs text-gray-400 font-bold uppercase">Yuklangan media va kvitansiyalar</p>
                  <div className="grid grid-cols-2 gap-2">
                    {selectedReport.mediaUrls.map((url, index) => {
                      const isVideo = url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.webm');
                      return (
                        <div key={index} className="border border-gray-100 dark:border-slate-700 rounded-xl overflow-hidden bg-gray-55/20 max-h-60 flex items-center justify-center relative group min-h-28">
                          {isVideo ? (
                            <video src={url} className="h-28 w-full object-cover" controls />
                          ) : (
                            <img src={url} alt="Media" className="h-28 w-full object-cover" />
                          )}
                          <a
                            href={url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-xs font-bold transition gap-1"
                          >
                            <Eye size={14} /> Ochish
                          </a>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>

            <div className="px-6 py-4 border-t border-gray-100 dark:border-slate-700 bg-gray-50/50 dark:bg-slate-900/30 flex justify-end gap-2">
              <Button variant="secondary" onClick={() => setSelectedReport(null)}>Yopish</Button>
              {!isVerified(selectedReport) && (
                <>
                  <Button variant="danger" onClick={() => setRejectTarget(selectedReport.id)}>Rad etish</Button>
                  <Button variant="primary" onClick={() => runAction(selectedReport.id, true, null)}>Tasdiqlash</Button>
                </>
              )}
            </div>
          </div>
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
