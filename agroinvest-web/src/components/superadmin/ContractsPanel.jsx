import React, { useEffect, useState } from 'react';
import { FileText, Search, UploadCloud, CheckCircle2, AlertCircle, Eye, FileDown, FolderKanban } from 'lucide-react';
import { getPlatformInvestments, updateInvestmentContractUrl } from '../../api/superadmin.api';
import Card from '../ui/Card';
import Badge from '../ui/Badge';
import DataTable from '../ui/DataTable';
import { useToast } from '../ui/ToastProvider';
import { formatAmount, formatDate } from '../../utils/format';
import { useDebounce } from '../../hooks/useDebounce';

const STATUS_LABELS = {
  PENDING: 'Kutilmoqda',
  ACTIVE: 'Faol',
  COMPLETED: 'Yakunlangan',
  CANCELLED: 'Bekor qilingan',
};

const STATUS_VARIANTS = {
  PENDING: 'warning',
  ACTIVE: 'primary',
  COMPLETED: 'success',
  CANCELLED: 'danger',
};

const FILTER_STATUSES = [
  { key: 'ALL', label: 'Barchasi' },
  { key: 'PENDING', label: 'Kutilmoqda' },
  { key: 'ACTIVE', label: 'Faol' },
  { key: 'COMPLETED', label: 'Yakunlangan' },
  { key: 'CANCELLED', label: 'Bekor qilingan' },
];

const ContractsPanel = () => {
  const [rows, setRows] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('ALL');
  const [uploadingId, setUploadingId] = useState(null);
  const debouncedSearch = useDebounce(search, 350);
  const { showToast } = useToast();

  const fetchRows = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const statusParam = selectedStatus === 'ALL' ? undefined : selectedStatus;
      const res = await getPlatformInvestments(page, 15, debouncedSearch || undefined, statusParam);
      setRows(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError('Shartnomalarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRows(0);
  }, [debouncedSearch, selectedStatus]);

  const handleUploadContract = async (investmentId, file) => {
    setUploadingId(investmentId);
    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('category', 'contract');
      
      const api = (await import('../../api/axios')).default;
      const uploadRes = await api.post('/upload', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      
      const contractUrl = uploadRes.data.url;
      await updateInvestmentContractUrl(investmentId, contractUrl);
      
      showToast('Shartnoma muvaffaqiyatli yuklandi!');
      fetchRows(pageInfo.pageNumber);
    } catch (err) {
      showToast(err.response?.data?.message || 'Yuklashda xatolik yuz berdi', 'error');
    } finally {
      setUploadingId(null);
    }
  };

  const columns = [
    {
      key: 'projectTitle',
      label: 'Loyiha nomi',
      render: (r) => (
        <div className="flex items-center gap-2 max-w-xs md:max-w-sm">
          <span className="p-1.5 bg-primary-50 dark:bg-primary-950/20 text-primary-600 dark:text-primary-400 rounded-lg shrink-0">
            <FolderKanban size={14} />
          </span>
          <div>
            <div className="font-bold text-gray-900 dark:text-slate-100 truncate text-xs" title={r.projectTitle}>
              {r.projectTitle}
            </div>
            <div className="text-[10px] text-gray-400 dark:text-slate-500 font-medium">ID: {r.id.substring(0, 8)}...</div>
          </div>
        </div>
      ),
    },
    {
      key: 'investorName',
      label: 'Sarmoyador',
      render: (r) => (
        <div>
          <span className="text-gray-900 dark:text-slate-200 font-extrabold text-xs block">
            {r.investorName}
          </span>
          <span className="text-[10px] text-gray-400 dark:text-slate-500 font-semibold uppercase tracking-wider">
            Investor
          </span>
        </div>
      ),
    },
    {
      key: 'amount',
      label: 'Sarmoya va Ulush',
      render: (r) => (
        <div>
          <span className="font-black text-gray-900 dark:text-slate-100 text-xs block">
            {formatAmount(r.amount)}
          </span>
          <span className="text-[10px] text-gray-500 dark:text-slate-400 font-bold">
            Ulush: <span className="text-primary-600 dark:text-primary-400">{r.sharePct}%</span>
          </span>
        </div>
      ),
    },
    {
      key: 'status',
      label: 'Shartnoma Holati',
      render: (r) => (
        <Badge variant={STATUS_VARIANTS[r.status] || 'secondary'} className="text-[10px] font-black uppercase px-2 py-0.5 rounded-lg">
          {STATUS_LABELS[r.status] || r.status}
        </Badge>
      ),
    },
    {
      key: 'createdAt',
      label: 'Sana',
      render: (r) => (
        <span className="text-gray-400 dark:text-slate-500 font-semibold text-[10px]">
          {formatDate(r.createdAt)}
        </span>
      ),
    },
    {
      key: 'actions',
      label: 'Amallar',
      render: (r) => (
        <div className="flex items-center gap-2">
          {/* View PDF */}
          <a
            href={`${import.meta.env.VITE_API_BASE_URL || ''}/api/v1/investments/${r.id}/agreement`}
            target="_blank"
            rel="noopener noreferrer"
            className="p-2 bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl text-gray-600 dark:text-slate-300 hover:bg-gray-50 hover:text-primary-600 dark:hover:text-primary-400 transition shadow-sm"
            title="PDF ko'rish"
          >
            <Eye size={13} />
          </a>

          {/* Download Word Document */}
          <a
            href={`${import.meta.env.VITE_API_BASE_URL || ''}/api/v1/investments/${r.id}/agreement/word`}
            className="p-2 bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl text-gray-600 dark:text-slate-300 hover:bg-gray-50 hover:text-emerald-600 dark:hover:text-emerald-400 transition shadow-sm"
            title="Word faylini yuklab olish"
          >
            <FileDown size={13} />
          </a>

          {/* Upload Custom Contract PDF */}
          <label className="p-2 bg-primary-50 dark:bg-primary-950/20 text-primary-600 dark:text-primary-400 hover:bg-primary-100 rounded-xl cursor-pointer transition flex items-center justify-center shadow-sm">
            {uploadingId === r.id ? (
              <span className="animate-spin rounded-full h-3.5 w-3.5 border-b-2 border-primary-600"></span>
            ) : (
              <UploadCloud size={13} />
            )}
            <input
              type="file"
              accept="application/pdf"
              className="hidden"
              disabled={uploadingId === r.id}
              onChange={(e) => {
                if (e.target.files && e.target.files[0]) {
                  handleUploadContract(r.id, e.target.files[0]);
                }
              }}
            />
          </label>

          {r.contractUrl && (
            <span className="text-emerald-600 dark:text-emerald-400 font-bold flex items-center gap-0.5 ml-1 animate-pulse" title="Maxsus yuridik PDF yuklangan">
              <CheckCircle2 size={13} />
              <span className="text-[9px] uppercase tracking-wider font-black">Maxsus</span>
            </span>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header Cards Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="p-5 bg-white dark:bg-slate-800 rounded-3xl border border-gray-100 dark:border-slate-750 shadow-sm flex items-center gap-4">
          <div className="w-10 h-10 rounded-2xl bg-primary-50 dark:bg-primary-950/20 text-primary-600 dark:text-primary-400 flex items-center justify-center">
            <FileText size={20} />
          </div>
          <div>
            <h3 className="text-gray-400 dark:text-slate-400 text-[10px] uppercase tracking-wider font-extrabold">Jami shartnomalar</h3>
            <p className="text-lg font-black text-gray-900 dark:text-slate-100 mt-0.5">
              {rows.length || 0} ta
            </p>
          </div>
        </div>

        <div className="p-5 bg-white dark:bg-slate-800 rounded-3xl border border-gray-100 dark:border-slate-750 shadow-sm flex items-center gap-4">
          <div className="w-10 h-10 rounded-2xl bg-emerald-50 dark:bg-emerald-950/20 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
            <CheckCircle2 size={20} />
          </div>
          <div>
            <h3 className="text-gray-400 dark:text-slate-400 text-[10px] uppercase tracking-wider font-extrabold">Maxsus yuridik PDF yuklanganlar</h3>
            <p className="text-lg font-black text-gray-900 dark:text-slate-100 mt-0.5">
              {rows.filter(r => r.contractUrl).length || 0} ta
            </p>
          </div>
        </div>

        <div className="p-5 bg-white dark:bg-slate-800 rounded-3xl border border-gray-100 dark:border-slate-750 shadow-sm flex items-center gap-4">
          <div className="w-10 h-10 rounded-2xl bg-amber-50 dark:bg-amber-950/20 text-amber-600 dark:text-amber-400 flex items-center justify-center">
            <AlertCircle size={20} />
          </div>
          <div>
            <h3 className="text-gray-400 dark:text-slate-400 text-[10px] uppercase tracking-wider font-extrabold">Kutilayotgan shartnomalar</h3>
            <p className="text-lg font-black text-gray-900 dark:text-slate-100 mt-0.5">
              {rows.filter(r => r.status === 'PENDING').length || 0} ta
            </p>
          </div>
        </div>
      </div>

      {/* Main Filter & Table Card */}
      <Card padded={false} className="overflow-hidden">
        {/* Title Header */}
        <div className="p-6 border-b border-gray-100 dark:border-slate-700 space-y-4">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h2 className="text-base font-bold text-gray-900 dark:text-slate-100">Investitsiya Bitimlari va Shartnomalar</h2>
              <p className="text-[11px] text-gray-500 dark:text-slate-400 mt-0.5">Shartnomalarni yuklab olish, ko'rish hamda maxsus PDF variantlarini yuklash oynasi</p>
            </div>

            {/* Search Field */}
            <div className="relative w-full md:w-80">
              <span className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400">
                <Search size={14} />
              </span>
              <input
                type="text"
                placeholder="Loyiha yoki investor bo'yicha qidirish..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-10 pr-4 py-2 text-xs font-semibold border border-gray-200 dark:border-slate-750 bg-gray-50/50 dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-2xl outline-none focus:border-primary-500 transition"
              />
            </div>
          </div>

          {/* Status Tabs/Chips filters */}
          <div className="flex flex-wrap items-center gap-1.5">
            {FILTER_STATUSES.map((status) => (
              <button
                key={status.key}
                onClick={() => setSelectedStatus(status.key)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
                  selectedStatus === status.key
                    ? 'bg-primary-600 text-white shadow-sm shadow-primary-600/10'
                    : 'bg-gray-50 dark:bg-slate-900 text-gray-500 dark:text-slate-400 hover:bg-gray-100 dark:hover:bg-slate-800'
                }`}
              >
                {status.label}
              </button>
            ))}
          </div>
        </div>

        {/* Main Table */}
        {rows.length === 0 && !loading ? (
          <div className="flex flex-col items-center justify-center py-20 text-center space-y-3">
            <div className="w-12 h-12 rounded-full bg-gray-50 dark:bg-slate-900 text-gray-400 flex items-center justify-center">
              <FileText size={20} />
            </div>
            <div>
              <p className="text-xs font-black text-gray-900 dark:text-slate-100">Shartnomalar topilmadi</p>
              <p className="text-[10px] text-gray-400 dark:text-slate-500 mt-0.5">Tanlangan filtr bo'yicha hech qanday ma'lumot topilmadi.</p>
            </div>
          </div>
        ) : (
          <DataTable
            loading={loading}
            error={error}
            onRetry={() => fetchRows(pageInfo.pageNumber)}
            rows={rows}
            columns={columns}
            pageNumber={pageInfo.pageNumber}
            totalPages={pageInfo.totalPages}
            onPageChange={fetchRows}
          />
        )}
      </Card>
    </div>
  );
};

export default ContractsPanel;
