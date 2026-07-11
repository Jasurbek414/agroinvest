import React, { useEffect, useState } from 'react';
import { getProjects, changeProjectStatus } from '../../../api/projects.api';
import { formatAmount } from '../../../utils/format';
import { ASSET_TYPE_META, getAssetTypeMeta } from '../../../utils/assetType';
import { 
  BadgeCheck, Star, Eye, Calendar, Compass, 
  LayoutGrid, List, CheckCircle2, DollarSign, FolderKanban, ShieldCheck, 
  HelpCircle, Sparkles, Filter, X, ArrowUpRight, Percent, Clock, MapPin
} from 'lucide-react';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';
import { useDebounce } from '../../../hooks/useDebounce';

// Rating/"Verified" badge for a project's farmer (TZ F-9.1/9.3) - reused in both
// the desktop column and the mobile card so the two stay visually consistent.
const FarmerBadge = ({ project }) => (
  <div className="flex items-center gap-1.5 min-w-0">
    <span className="text-xs font-semibold text-gray-700 dark:text-slate-300 truncate">{project.farmerName}</span>
    {project.farmerVerified && (
      <BadgeCheck size={13} className="text-primary-600 dark:text-primary-400 shrink-0" aria-label="Tasdiqlangan fermer" />
    )}
    {project.farmerRating > 0 && (
      <span className="flex items-center gap-0.5 text-[11px] font-bold text-amber-600 dark:text-amber-400 shrink-0">
        <Star size={11} fill="currentColor" />
        {Number(project.farmerRating).toFixed(1)}
      </span>
    )}
  </div>
);

const STATUS_OPTIONS = [
  { value: '', label: 'Barchasi', color: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300' },
  { value: 'PENDING', label: 'Kutilmoqda', color: 'bg-amber-100 text-amber-700 dark:bg-amber-950/40 dark:text-amber-400' },
  { value: 'APPROVED', label: 'Tasdiqlangan', color: 'bg-blue-100 text-blue-700 dark:bg-blue-950/40 dark:text-blue-400' },
  { value: 'FUNDING', label: "Yig'ilmoqda", color: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400' },
  { value: 'ACTIVE', label: 'Faol', color: 'bg-purple-100 text-purple-700 dark:bg-purple-950/40 dark:text-purple-400' },
  { value: 'COMPLETED', label: 'Yakunlangan', color: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300' },
  { value: 'CANCELLED', label: 'Rad etilgan', color: 'bg-rose-100 text-rose-700 dark:bg-rose-950/40 dark:text-rose-400' },
];

const ProjectsTab = ({ onActionDone }) => {
  const [projects, setProjects] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const [selectedProject, setSelectedProject] = useState(null);
  const [modalTab, setModalTab] = useState('details'); // 'details' | 'vetting'
  const [status, setStatus] = useState('PENDING');
  const [assetType, setAssetType] = useState('');
  const [search, setSearch] = useState('');
  const [viewMode, setViewMode] = useState('grid'); // Default to grid for premium view
  const debouncedSearch = useDebounce(search, 350);
  const { showToast } = useToast();

  // Simulated vetting checklist state for the currently selected project
  const [vettingState, setVettingState] = useState({
    kycPassed: false,
    financialsPassed: false,
    documentsPassed: false,
    vetCheckPassed: false
  });

  // Reset vetting checkboxes when project changes
  useEffect(() => {
    if (selectedProject) {
      setVettingState({
        kycPassed: selectedProject.farmerVerified || false,
        financialsPassed: false,
        documentsPassed: false,
        vetCheckPassed: false
      });
    }
  }, [selectedProject]);

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
      setSelectedProject(null);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const runBulkApprove = async (rows) => {
    try {
      await Promise.all(rows.map((p) => changeProjectStatus(p.id, 'FUNDING', null)));
      showToast(`${rows.length} ta loyiha tasdiqlandi`);
      fetchData(pageInfo.pageNumber);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  // Metrics derived from active/pending statuses
  const pendingCount = projects.filter(p => p.status === 'PENDING').length;
  const fundingCount = projects.filter(p => p.status === 'FUNDING').length;
  const totalPendingAmount = projects.filter(p => p.status === 'PENDING').reduce((sum, p) => sum + Number(p.targetAmount), 0);

  const allChecksPassed = vettingState.kycPassed && vettingState.financialsPassed && vettingState.documentsPassed && vettingState.vetCheckPassed;

  return (
    <div className="space-y-6">
      {/* Header Panel with Premium Gradient and Icon accents */}
      <div className="relative overflow-hidden p-6 md:p-8 border-b border-gray-100 dark:border-slate-800 bg-gradient-to-br from-slate-900 via-slate-950 to-primary-950 text-white rounded-t-2xl">
        <div className="absolute top-0 right-0 w-96 h-96 bg-primary-500/10 rounded-full blur-3xl -z-10" />
        <div className="absolute -bottom-10 left-1/3 w-72 h-72 bg-amber-500/5 rounded-full blur-3xl -z-10" />

        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 relative z-10">
          <div>
            <div className="flex items-center gap-2">
              <span className="px-2.5 py-0.5 rounded-full bg-primary-500/20 text-primary-300 text-[10px] font-bold tracking-wider uppercase">Operatsiyalar</span>
              <Sparkles size={12} className="text-amber-400 animate-pulse" />
            </div>
            <h2 className="text-xl md:text-2xl font-extrabold tracking-tight mt-1">Loyiha Arizalari Boshqaruvi</h2>
            <p className="text-xs text-gray-300 mt-1 max-w-xl">
              Fermerlar tomonidan kiritilgan investitsiya arizalarini to'liq tekshirish, audit hisobotlarini baholash hamda mablag' yig'ishga ruxsat berish.
            </p>
          </div>
        </div>

        {/* High Fidelity Stats Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mt-6">
          <div className="p-4 bg-white/5 backdrop-blur-md border border-white/10 rounded-2xl flex items-center gap-3.5 hover:bg-white/10 transition duration-200">
            <span className="w-10 h-10 rounded-xl bg-amber-500/20 text-amber-400 flex items-center justify-center shrink-0 shadow-inner">
              <FolderKanban size={20} />
            </span>
            <div>
              <p className="text-[10px] font-bold text-amber-400 uppercase tracking-wider">Tasdiq Kutilmoqda</p>
              <p className="text-xl font-black text-white mt-0.5">{pendingCount} ta ariza</p>
            </div>
          </div>
          <div className="p-4 bg-white/5 backdrop-blur-md border border-white/10 rounded-2xl flex items-center gap-3.5 hover:bg-white/10 transition duration-200">
            <span className="w-10 h-10 rounded-xl bg-primary-500/20 text-primary-300 flex items-center justify-center shrink-0 shadow-inner">
              <CheckCircle2 size={20} />
            </span>
            <div>
              <p className="text-[10px] font-bold text-primary-300 uppercase tracking-wider">Mablag' Yig'ilmoqda</p>
              <p className="text-xl font-black text-white mt-0.5">{fundingCount} ta loyiha</p>
            </div>
          </div>
          <div className="p-4 bg-white/5 backdrop-blur-md border border-white/10 rounded-2xl flex items-center gap-3.5 hover:bg-white/10 transition duration-200">
            <span className="w-10 h-10 rounded-xl bg-emerald-500/20 text-emerald-300 flex items-center justify-center shrink-0 shadow-inner">
              <DollarSign size={20} />
            </span>
            <div>
              <p className="text-[10px] font-bold text-emerald-300 uppercase tracking-wider">Jami Kutilayotgan Summa</p>
              <p className="text-xl font-black text-white mt-0.5">{formatAmount(totalPendingAmount)}</p>
            </div>
          </div>
        </div>

        {/* Filter and Tab switcher Bar */}
        <div className="flex flex-col sm:flex-row gap-4 mt-6 pt-4 border-t border-white/5 justify-between items-stretch sm:items-center">
          {/* Status Capsule Filters */}
          <div className="flex gap-1.5 overflow-x-auto pb-1 scrollbar-none">
            {STATUS_OPTIONS.map((opt) => (
              <button
                key={opt.value}
                onClick={() => setStatus(opt.value)}
                className={`px-3.5 py-1.5 rounded-full text-xs font-bold transition whitespace-nowrap flex items-center gap-1.5 ${
                  status === opt.value
                    ? 'bg-white text-slate-950 shadow-lg scale-105'
                    : 'bg-white/5 text-gray-300 hover:bg-white/10 border border-white/5'
                }`}
              >
                {status === opt.value && <span className="w-1.5 h-1.5 rounded-full bg-primary-600" />}
                {opt.label}
              </button>
            ))}
          </div>

          {/* View mode switcher */}
          <div className="flex items-center gap-1.5 border border-white/10 rounded-xl p-1 bg-white/5 self-end sm:self-auto">
            <button
              onClick={() => setViewMode('table')}
              className={`p-2 rounded-lg transition ${viewMode === 'table' ? 'bg-white text-slate-900 shadow-sm' : 'text-gray-400 hover:text-gray-200'}`}
              title="Jadval shaklida"
            >
              <List size={15} />
            </button>
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 rounded-lg transition ${viewMode === 'grid' ? 'bg-white text-slate-900 shadow-sm' : 'text-gray-400 hover:text-gray-200'}`}
              title="Karta shaklida"
            >
              <LayoutGrid size={15} />
            </button>
          </div>
        </div>
      </div>

      <div className="px-6 pb-6">
        {viewMode === 'table' ? (
          <div className="bg-white dark:bg-slate-900 rounded-2xl border border-gray-100 dark:border-slate-800/80 overflow-hidden shadow-sm">
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
                  className="px-3.5 py-2 border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-2 focus:ring-primary-500"
                >
                  <option value="">Barcha turlar</option>
                  {Object.entries(ASSET_TYPE_META).map(([key, meta]) => (
                    <option key={key} value={key}>{meta.label}</option>
                  ))}
                </select>
              }
              page={{ ...pageInfo, onPageChange: fetchData }}
              selectable={status === 'PENDING'}
              bulkActions={[
                { label: 'Tanlanganlarni tasdiqlash', onClick: runBulkApprove },
              ]}
              columns={[
                {
                  key: 'title',
                  header: 'Loyiha nomi',
                  render: (p) => {
                    const meta = getAssetTypeMeta(p.assetType);
                    const Icon = meta.icon;
                    return (
                      <div className="flex items-center gap-3">
                        <span className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0 shadow-sm border border-gray-100 dark:border-slate-800" style={{ backgroundColor: meta.color + '12', color: meta.color }}>
                          <Icon size={16} />
                        </span>
                        <div>
                          <p className="font-semibold text-gray-900 dark:text-slate-100 text-sm">{p.title}</p>
                          <p className="text-[10px] text-gray-400 mt-0.5">{meta.label}</p>
                        </div>
                      </div>
                    );
                  },
                },
                { key: 'farmer', header: 'Fermer', render: (p) => <FarmerBadge project={p} /> },
                { key: 'region', header: 'Viloyat', render: (p) => <span className="text-xs font-bold text-gray-500 dark:text-slate-400"><MapPin size={11} className="inline mr-1" />{p.region}</span> },
                { key: 'targetAmount', header: 'Maqsad summa', render: (p) => <span className="font-extrabold text-sm text-gray-950 dark:text-slate-100">{formatAmount(p.targetAmount)}</span> },
                { key: 'status', header: 'Holat', render: (p) => <Badge status={p.status} /> },
                { key: 'returns', header: 'Foyda / Muddat', render: (p) => <span className="text-xs font-bold text-emerald-600 dark:text-emerald-400">+{p.expectedReturnPct}% / {p.durationDays} kun</span> },
                {
                  key: 'actions',
                  header: 'Amallar',
                  align: 'right',
                  render: (p) => (
                    <div className="flex justify-end gap-1.5">
                      <Button variant="ghost" size="sm" icon={Eye} onClick={() => { setSelectedProject(p); setModalTab('details'); }}>Batafsil</Button>
                      {p.status === 'PENDING' && (
                        <>
                          <Button variant="danger" size="sm" onClick={() => setRejectTarget(p.id)}>Rad etish</Button>
                          <Button variant="primary" size="sm" onClick={() => runAction(p.id, true, null)}>Tasdiqlash</Button>
                        </>
                      )}
                    </div>
                  ),
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
                    <FarmerBadge project={p} />
                    <p className="text-xs text-gray-500 dark:text-slate-400">{p.region} · {formatAmount(p.targetAmount)} · +{p.expectedReturnPct}%</p>
                    <div className="flex gap-2 pt-1">
                      <Button variant="secondary" size="sm" className="flex-1" onClick={() => { setSelectedProject(p); setModalTab('details'); }}>Batafsil</Button>
                      {p.status === 'PENDING' && (
                        <>
                          <Button variant="danger" size="sm" className="flex-1" onClick={() => setRejectTarget(p.id)}>Rad etish</Button>
                          <Button variant="primary" size="sm" className="flex-1" onClick={() => runAction(p.id, true, null)}>Tasdiqlash</Button>
                        </>
                      )}
                    </div>
                  </div>
                );
              }}
            />
          </div>
        ) : (
          /* Grid View Mode Layout */
          <div className="space-y-6">
            <div className="flex flex-col sm:flex-row gap-3 justify-between items-center bg-white dark:bg-slate-900 p-4 rounded-2xl border border-gray-100 dark:border-slate-800/80 shadow-sm">
              <div className="relative w-full sm:w-80">
                <input
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Loyiha nomi bo'yicha qidirish..."
                  className="w-full pl-4 pr-10 py-2 border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-950 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-2 focus:ring-primary-500"
                />
                {search && (
                  <button onClick={() => setSearch('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                    <X size={14} />
                  </button>
                )}
              </div>
              <div className="flex items-center gap-2 w-full sm:w-auto">
                <Filter size={14} className="text-gray-400 shrink-0 hidden sm:inline" />
                <select
                  value={assetType}
                  onChange={(e) => setAssetType(e.target.value)}
                  className="w-full sm:w-44 px-3 py-2 border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-950 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-2 focus:ring-primary-500"
                >
                  <option value="">Barcha turlar</option>
                  {Object.entries(ASSET_TYPE_META).map(([key, meta]) => (
                    <option key={key} value={key}>{meta.label}</option>
                  ))}
                </select>
              </div>
            </div>

            {loading ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {[1, 2, 3].map((n) => (
                  <div key={n} className="h-[360px] rounded-3xl bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 animate-pulse p-6 space-y-4 shadow-sm">
                    <div className="flex justify-between"><div className="w-24 h-6 bg-gray-200 dark:bg-slate-800 rounded-lg" /><div className="w-16 h-6 bg-gray-200 dark:bg-slate-800 rounded-full" /></div>
                    <div className="w-full h-8 bg-gray-200 dark:bg-slate-800 rounded-lg" />
                    <div className="w-1/2 h-4 bg-gray-200 dark:bg-slate-800 rounded-lg animate-pulse" />
                    <div className="h-16 bg-gray-100 dark:bg-slate-800/50 rounded-xl" />
                    <div className="flex gap-3 pt-4"><div className="flex-1 h-10 bg-gray-200 dark:bg-slate-800 rounded-xl" /><div className="flex-1 h-10 bg-gray-200 dark:bg-slate-805 rounded-xl" /></div>
                  </div>
                ))}
              </div>
            ) : projects.length === 0 ? (
              <div className="text-center py-20 bg-white dark:bg-slate-900 rounded-3xl border border-gray-100 dark:border-slate-800 shadow-sm">
                <HelpCircle className="mx-auto text-gray-300 dark:text-slate-700" size={56} />
                <h3 className="text-lg font-bold text-gray-800 dark:text-slate-200 mt-4">Loyihalar topilmadi</h3>
                <p className="text-xs text-gray-500 dark:text-slate-500 mt-1">Ushbu holat bo'yicha ayni vaqtda hech qanday loyihalar mavjud emas</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 animate-in fade-in duration-300">
                {projects.map((p) => {
                  const meta = getAssetTypeMeta(p.assetType);
                  const Icon = meta.icon;
                  const raised = p.raisedAmount || 0;
                  const target = p.targetAmount || 1;
                  const percent = Math.min(100, Math.round((raised / target) * 100));

                  return (
                    <div key={p.id} className="bg-white dark:bg-slate-900 rounded-3xl border border-gray-100 dark:border-slate-800/80 shadow-sm overflow-hidden flex flex-col justify-between hover:shadow-md dark:hover:border-slate-700 transition-all duration-300 group">
                      
                      {/* Top Header Card */}
                      <div className="p-6 space-y-4">
                        <div className="flex justify-between items-start">
                          <span className="w-10 h-10 rounded-xl flex items-center justify-center shadow-sm border border-gray-50 dark:border-slate-800 group-hover:scale-105 transition-transform" style={{ backgroundColor: meta.color + '12', color: meta.color }}>
                            <Icon size={18} />
                          </span>
                          <Badge status={p.status} />
                        </div>

                        <div>
                          <h4 className="font-extrabold text-base text-gray-900 dark:text-slate-100 line-clamp-1 group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">{p.title}</h4>
                          <p className="text-[11px] text-gray-400 dark:text-slate-500 flex items-center gap-1 mt-1"><MapPin size={12} />{p.region} viloyati</p>
                        </div>

                        {/* Farmer badge */}
                        <div className="pt-2.5 border-t border-gray-50 dark:border-slate-800/50">
                          <FarmerBadge project={p} />
                        </div>

                        {/* Financial Metrics in Box */}
                        <div className="grid grid-cols-2 gap-3.5 p-3 rounded-2xl bg-gray-50 dark:bg-slate-950/60 border border-gray-100/50 dark:border-slate-950 text-xs">
                          <div>
                            <span className="text-[10px] text-gray-400 font-semibold uppercase tracking-wider block">Kerakli Summa</span>
                            <p className="font-black text-[13px] text-gray-900 dark:text-slate-100 mt-0.5">{formatAmount(p.targetAmount)}</p>
                          </div>
                          <div>
                            <span className="text-[10px] text-gray-400 font-semibold uppercase tracking-wider block">Kutilayotgan Foyda</span>
                            <p className="font-black text-[13px] text-emerald-600 dark:text-emerald-400 mt-0.5 flex items-center gap-0.5">
                              <ArrowUpRight size={14} />+{p.expectedReturnPct}%
                            </p>
                          </div>
                        </div>

                        {/* Progress Bar (Visible for Funding / Active / Completed states) */}
                        {['FUNDING', 'ACTIVE', 'COMPLETED'].includes(p.status) && (
                          <div className="space-y-1.5 pt-1">
                            <div className="flex justify-between text-[11px] font-bold text-gray-500 dark:text-slate-400">
                              <span>{percent}% yig'ildi</span>
                              <span>{formatAmount(raised)}</span>
                            </div>
                            <div className="w-full bg-gray-100 dark:bg-slate-800 h-1.5 rounded-full overflow-hidden">
                              <div className="bg-primary-600 h-full rounded-full transition-all duration-300" style={{ width: `${percent}%` }} />
                            </div>
                          </div>
                        )}
                      </div>

                      {/* Bottom action panel */}
                      <div className="px-5 py-4 bg-gray-50/50 dark:bg-slate-950/20 border-t border-gray-100 dark:border-slate-800/50 flex gap-2">
                        <Button variant="secondary" size="sm" className="flex-1 gap-1" onClick={() => { setSelectedProject(p); setModalTab('details'); }}>
                          <Eye size={13} />
                          Batafsil
                        </Button>
                        {p.status === 'PENDING' && (
                          <>
                            <Button variant="danger" size="sm" className="flex-1" onClick={() => setRejectTarget(p.id)}>Rad etish</Button>
                            <Button variant="primary" size="sm" className="flex-1" onClick={() => runAction(p.id, true, null)}>Tasdiqlash</Button>
                          </>
                        )}
                      </div>

                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}
      </div>

      {/* High Fidelity Project Details Tabbed Modal */}
      {selectedProject && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm transition-opacity">
          <div className="relative w-full max-w-2xl bg-white dark:bg-slate-900 rounded-[32px] shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-200 border border-gray-100 dark:border-slate-800">
            
            {/* Header info */}
            <div className="px-6 py-5 border-b border-gray-100 dark:border-slate-800 flex justify-between items-center bg-gray-50/50 dark:bg-slate-950/20">
              <div className="flex items-center gap-3">
                <span className="w-10 h-10 rounded-2xl flex items-center justify-center border border-gray-100 dark:border-slate-800 shadow-sm" style={{ backgroundColor: getAssetTypeMeta(selectedProject.assetType)?.color + '12', color: getAssetTypeMeta(selectedProject.assetType)?.color }}>
                  {React.createElement(getAssetTypeMeta(selectedProject.assetType)?.icon || Compass, { size: 20 })}
                </span>
                <div>
                  <h3 className="text-base font-bold text-gray-900 dark:text-slate-100">Loyiha Arizasi Tafsilotlari</h3>
                  <p className="text-[11px] text-gray-400 mt-0.5">Turi: {getAssetTypeMeta(selectedProject.assetType)?.label}</p>
                </div>
              </div>
              <button onClick={() => setSelectedProject(null)} className="p-2 rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-800 hover:text-gray-600 font-bold">&times;</button>
            </div>

            {/* Modal Tabs switcher */}
            <div className="flex border-b border-gray-100 dark:border-slate-800 px-6 bg-gray-50/20 dark:bg-slate-950/10">
              <button
                onClick={() => setModalTab('details')}
                className={`py-3.5 text-xs font-bold border-b-2 px-4 transition ${modalTab === 'details' ? 'border-primary-600 text-primary-600 dark:text-primary-400' : 'border-transparent text-gray-400 hover:text-gray-600'}`}
              >
                Loyiha ma'lumotlari
              </button>
              <button
                onClick={() => setModalTab('vetting')}
                className={`py-3.5 text-xs font-bold border-b-2 px-4 transition ${modalTab === 'vetting' ? 'border-primary-600 text-primary-600 dark:text-primary-400' : 'border-transparent text-gray-400 hover:text-gray-600'}`}
              >
                Vetting va Hujjatlar
              </button>
            </div>

            <div className="p-6 space-y-5 max-h-[55vh] overflow-y-auto">
              {modalTab === 'details' ? (
                <>
                  <div className="space-y-1">
                    <h4 className="text-lg font-black text-gray-900 dark:text-slate-100">{selectedProject.title}</h4>
                    <p className="text-xs text-gray-400 flex items-center gap-1"><MapPin size={12} />{selectedProject.region} viloyati</p>
                  </div>

                  {/* Grid key details */}
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-xs">
                    <div className="bg-gray-50 dark:bg-slate-950 p-3.5 rounded-2xl border border-gray-100 dark:border-slate-800/80">
                      <p className="text-gray-400 font-semibold flex items-center gap-1"><DollarSign size={13} />Maqsad</p>
                      <p className="text-sm font-black text-gray-900 dark:text-slate-100 mt-1">{formatAmount(selectedProject.targetAmount)}</p>
                    </div>
                    <div className="bg-gray-50 dark:bg-slate-950 p-3.5 rounded-2xl border border-gray-100 dark:border-slate-800/80">
                      <p className="text-gray-400 font-semibold flex items-center gap-1"><Percent size={13} />Daromadlik</p>
                      <p className="text-sm font-black text-green-600 dark:text-green-400 mt-1">+{selectedProject.expectedReturnPct}%</p>
                    </div>
                    <div className="bg-gray-50 dark:bg-slate-950 p-3.5 rounded-2xl border border-gray-100 dark:border-slate-800/80">
                      <p className="text-gray-400 font-semibold flex items-center gap-1"><Clock size={13} />Muddati</p>
                      <p className="text-sm font-black text-gray-900 dark:text-slate-100 mt-1">{selectedProject.durationDays} kun</p>
                    </div>
                    <div className="bg-gray-50 dark:bg-slate-950 p-3.5 rounded-2xl border border-gray-100 dark:border-slate-800/80">
                      <p className="text-gray-400 font-semibold flex items-center gap-1"><ShieldCheck size={13} />Xavf darajasi</p>
                      <p className="text-sm font-black text-gray-900 dark:text-slate-100 mt-1 uppercase">{selectedProject.riskLevel || 'O\'rta'}</p>
                    </div>
                  </div>

                  {/* Farmer Profile Card */}
                  <div className="p-4 bg-primary-50/20 dark:bg-primary-950/10 border border-primary-100/60 dark:border-primary-950 rounded-2xl flex items-center justify-between">
                    <div>
                      <p className="text-[10px] font-bold text-primary-600 dark:text-primary-400 uppercase tracking-wider">Loyiha egasi (Fermer)</p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="font-extrabold text-slate-805 dark:text-slate-100">{selectedProject.farmerName}</span>
                        {selectedProject.farmerVerified && <BadgeCheck size={14} className="text-primary-600 dark:text-primary-400" />}
                      </div>
                    </div>
                    {selectedProject.farmerRating > 0 && (
                      <div className="flex flex-col items-end">
                        <span className="text-[9px] font-bold text-gray-400 uppercase">Reytingi</span>
                        <span className="flex items-center gap-0.5 text-sm font-black text-amber-500 mt-0.5">
                          <Star size={14} fill="currentColor" /> {Number(selectedProject.farmerRating).toFixed(1)}
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Description */}
                  <div className="space-y-2">
                    <h5 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Loyiha tavsifi</h5>
                    <p className="text-sm text-gray-600 dark:text-slate-350 leading-relaxed bg-gray-50 dark:bg-slate-950/40 p-4 rounded-2xl border border-gray-100 dark:border-slate-850 whitespace-pre-line">
                      {selectedProject.description || 'Tavsif kiritilmagan.'}
                    </p>
                  </div>

                  {selectedProject.imageUrl && (
                    <div className="space-y-2">
                      <h5 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Rasmgalereya</h5>
                      <div className="border border-gray-100 dark:border-slate-800 rounded-3xl overflow-hidden bg-gray-50">
                        <img src={selectedProject.imageUrl} alt="Loyiha rasmi" className="w-full max-h-60 object-cover" />
                      </div>
                    </div>
                  )}
                </>
              ) : (
                /* Tab 2: Interactive Vetting Voids Checks */
                <div className="space-y-5 animate-in fade-in duration-200">
                  <div className="p-4 bg-amber-50/20 dark:bg-amber-950/10 border border-amber-100/60 dark:border-amber-950 rounded-2xl flex gap-3 text-xs text-amber-700 dark:text-amber-500">
                    <ShieldCheck size={20} className="shrink-0" />
                    <div>
                      <p className="font-bold">Tasdiqlashdan Oldin Vetting Nazorati</p>
                      <p className="mt-0.5">Loyiha qonuniy va xavfsiz ekanini tasdiqlash uchun quyidagi 4 ta asosiy majburiyatlarni tasdiqlab chiqing:</p>
                    </div>
                  </div>

                  {/* Checkbox fields */}
                  <div className="space-y-3.5">
                    <label className="flex items-start gap-3.5 p-4 rounded-2xl bg-gray-50 dark:bg-slate-950/50 border border-gray-100 dark:border-slate-850 hover:bg-gray-100/50 dark:hover:bg-slate-950 transition cursor-pointer select-none">
                      <input
                        type="checkbox"
                        checked={vettingState.kycPassed}
                        onChange={(e) => setVettingState({ ...vettingState, kycPassed: e.target.checked })}
                        className="mt-0.5 rounded border-gray-300 dark:border-slate-700 text-primary-600 focus:ring-primary-500 w-4 h-4"
                      />
                      <div>
                        <p className="text-xs font-bold text-gray-900 dark:text-slate-200">Fermer shaxsi tekshirildi (KYC)</p>
                        <p className="text-[10px] text-gray-400 mt-0.5">Passport, rasm va yuz qiyofasi tekshirilib, tasdiq belgisi olingan.</p>
                      </div>
                    </label>

                    <label className="flex items-start gap-3.5 p-4 rounded-2xl bg-gray-50 dark:bg-slate-950/50 border border-gray-100 dark:border-slate-850 hover:bg-gray-100/50 dark:hover:bg-slate-950 transition cursor-pointer select-none">
                      <input
                        type="checkbox"
                        checked={vettingState.financialsPassed}
                        onChange={(e) => setVettingState({ ...vettingState, financialsPassed: e.target.checked })}
                        className="mt-0.5 rounded border-gray-300 dark:border-slate-700 text-primary-600 focus:ring-primary-500 w-4 h-4"
                      />
                      <div>
                        <p className="text-xs font-bold text-gray-900 dark:text-slate-200">Biznes reja va rentabellik tahlili</p>
                        <p className="text-[10px] text-gray-400 mt-0.5">Kutilayotgan foyda koeffitsiyenti (+{selectedProject.expectedReturnPct}%) va xarajatlar auditi haqiqatga mos.</p>
                      </div>
                    </label>

                    <label className="flex items-start gap-3.5 p-4 rounded-2xl bg-gray-50 dark:bg-slate-950/50 border border-gray-100 dark:border-slate-850 hover:bg-gray-100/50 dark:hover:bg-slate-950 transition cursor-pointer select-none">
                      <input
                        type="checkbox"
                        checked={vettingState.documentsPassed}
                        onChange={(e) => setVettingState({ ...vettingState, documentsPassed: e.target.checked })}
                        className="mt-0.5 rounded border-gray-300 dark:border-slate-700 text-primary-600 focus:ring-primary-500 w-4 h-4"
                      />
                      <div>
                        <p className="text-xs font-bold text-gray-900 dark:text-slate-200">Yer maydoni yoki chorvachilik hujjatlari</p>
                        <p className="text-[10px] text-gray-400 mt-0.5">Ijara yoki mulkdorlik shartnomalari, hokimiyat qarorlari va kadastr hujjatlari tekshirildi.</p>
                      </div>
                    </label>

                    <label className="flex items-start gap-3.5 p-4 rounded-2xl bg-gray-50 dark:bg-slate-950/50 border border-gray-100 dark:border-slate-850 hover:bg-gray-100/50 dark:hover:bg-slate-950 transition cursor-pointer select-none">
                      <input
                        type="checkbox"
                        checked={vettingState.vetCheckPassed}
                        onChange={(e) => setVettingState({ ...vettingState, vetCheckPassed: e.target.checked })}
                        className="mt-0.5 rounded border-gray-300 dark:border-slate-700 text-primary-600 focus:ring-primary-500 w-4 h-4"
                      />
                      <div>
                        <p className="text-xs font-bold text-gray-900 dark:text-slate-200">Veterinariya / Sanitariya sertifikatlari</p>
                        <p className="text-[10px] text-gray-400 mt-0.5">Chorva va parvarish obyektlarining sanitariya qoidalari va emlash kartalari tasdiqlangan.</p>
                      </div>
                    </label>
                  </div>
                </div>
              )}
            </div>

            {/* Actions panel */}
            <div className="px-6 py-5 border-t border-gray-100 dark:border-slate-800 bg-gray-50/50 dark:bg-slate-950/20 flex justify-between items-center">
              <span className="text-[11px] font-bold text-gray-400 uppercase">
                {selectedProject.status === 'PENDING' ? (
                  allChecksPassed ? (
                    <span className="text-emerald-600">Barcha nazoratlar o'tgan</span>
                  ) : (
                    <span className="text-amber-500">Tekshiruvlar yakunlanmagan</span>
                  )
                ) : (
                  <span>Loyiha tasdiqlangan</span>
                )}
              </span>
              <div className="flex gap-2">
                <Button variant="secondary" onClick={() => setSelectedProject(null)}>Yopish</Button>
                {selectedProject.status === 'PENDING' && (
                  <>
                    <Button variant="danger" onClick={() => setRejectTarget(selectedProject.id)}>Rad etish</Button>
                    <Button variant="primary" disabled={!allChecksPassed} onClick={() => runAction(selectedProject.id, true, null)}>
                      Tasdiqlash
                    </Button>
                  </>
                )}
              </div>
            </div>
          </div>
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
