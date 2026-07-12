import React, { useEffect, useState } from 'react';
import { 
  FileText, Search, UploadCloud, CheckCircle2, AlertCircle, Eye, 
  FileDown, FolderKanban, Download, RotateCcw, SlidersHorizontal 
} from 'lucide-react';
import { getPlatformInvestments, updateInvestmentContractUrl } from '../../api/superadmin.api';
import Card from '../ui/Card';
import Badge from '../ui/Badge';
import DataTable from '../ui/DataTable';
import { useToast } from '../ui/ToastProvider';
import { formatAmount, formatDate } from '../../utils/format';
import { useDebounce } from '../../hooks/useDebounce';
import { useAuthStore } from '../../store/auth.store';

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
  { key: 'ALL', label: 'Barcha shartnomalar' },
  { key: 'PENDING', label: 'Kutilayotganlar' },
  { key: 'ACTIVE', label: 'Faol kelishuvlar' },
  { key: 'COMPLETED', label: 'Yakunlanganlar' },
  { key: 'CANCELLED', label: 'Bekor qilinganlar' },
];

const ContractsPanel = () => {
  const { accessToken } = useAuthStore();
  const [rows, setRows] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  // Search and Primary Filters
  const [search, setSearch] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('ALL');
  const debouncedSearch = useDebounce(search, 350);
  const { showToast } = useToast();

  // Advanced Filters
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [minAmount, setMinAmount] = useState('');
  const [maxAmount, setMaxAmount] = useState('');
  const [customPdfFilter, setCustomPdfFilter] = useState('all'); // all, custom, standard
  
  const [uploadingId, setUploadingId] = useState(null);

  const fetchRows = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const statusParam = selectedStatus === 'ALL' ? undefined : selectedStatus;
      const res = await getPlatformInvestments(page, 50, debouncedSearch || undefined, statusParam);
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

  const handleExportCSV = () => {
    const finalRows = getFilteredRows();
    if (finalRows.length === 0) {
      showToast('Eksport qilish uchun ma\'lumotlar mavjud emas', 'warning');
      return;
    }

    const headers = [
      'Loyiha nomi', 
      'Sarmoyador nomi', 
      'Sarmoya summasi (UZS)', 
      'Investor ulushi (%)', 
      'Status', 
      'Shartnoma turi', 
      'Sana'
    ];

    const csvRows = [
      headers.join(','),
      ...finalRows.map(r => [
        `"${r.projectTitle.replace(/"/g, '""')}"`,
        `"${r.investorName.replace(/"/g, '""')}"`,
        r.amount,
        r.sharePct,
        STATUS_LABELS[r.status] || r.status,
        r.contractUrl ? 'Maxsus PDF' : 'Standart shablon',
        formatDate(r.createdAt)
      ].join(','))
    ];

    const blob = new Blob([new Uint8Array([0xEF, 0xBB, 0xBF]), csvRows.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `agroinvest_shartnomalar_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    showToast('Fayl Excel formatida muvaffaqiyatli yuklab olindi!');
  };

  const handleResetFilters = () => {
    setMinAmount('');
    setMaxAmount('');
    setCustomPdfFilter('all');
    showToast('Filtrlar tozalandi');
  };

  const getFilteredRows = () => {
    return rows.filter(r => {
      if (minAmount && Number(r.amount) < Number(minAmount)) return false;
      if (maxAmount && Number(r.amount) > Number(maxAmount)) return false;
      if (customPdfFilter === 'custom' && !r.contractUrl) return false;
      if (customPdfFilter === 'standard' && r.contractUrl) return false;
      return true;
    });
  };

  const displayedRows = getFilteredRows();

  const columns = [
    {
      key: 'projectTitle',
      label: 'Loyiha nomi',
      render: (r) => (
        <div className="flex items-center gap-3 max-w-xs md:max-w-sm">
          <span className="p-2.5 bg-gradient-to-tr from-primary-500 to-indigo-600 text-white rounded-xl shrink-0 shadow-md shadow-primary-500/10">
            <FolderKanban size={14} />
          </span>
          <div>
            <div className="font-extrabold text-gray-900 dark:text-slate-100 hover:text-primary-650 transition cursor-pointer truncate text-xs" title={r.projectTitle}>
              {r.projectTitle}
            </div>
            <div className="text-[9px] text-gray-400 dark:text-slate-500 font-bold tracking-wide mt-0.5">Shartnoma ID: #{r.id.substring(0, 8).toUpperCase()}</div>
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
          <span className="text-[9px] text-primary-600 dark:text-primary-400 font-black uppercase tracking-wider">
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
            Ulush: <span className="text-indigo-600 dark:text-indigo-400 font-black">{r.sharePct}%</span>
          </span>
        </div>
      ),
    },
    {
      key: 'status',
      label: 'Shartnoma Holati',
      render: (r) => (
        <div className="flex items-center gap-1.5">
          <span className={`w-1.5 h-1.5 rounded-full ${
            r.status === 'ACTIVE' ? 'bg-emerald-500 animate-pulse' :
            r.status === 'PENDING' ? 'bg-amber-500 animate-pulse' : 'bg-red-500'
          }`} />
          <Badge variant={STATUS_VARIANTS[r.status] || 'secondary'} className="text-[9px] font-black uppercase px-2 py-0.5 rounded-lg tracking-wider">
            {STATUS_LABELS[r.status] || r.status}
          </Badge>
        </div>
      ),
    },
    {
      key: 'createdAt',
      label: 'Imzolangan Sana',
      render: (r) => (
        <span className="text-gray-400 dark:text-slate-500 font-bold text-[10px]">
          {formatDate(r.createdAt)}
        </span>
      ),
    },
    {
      key: 'actions',
      label: 'Hujjatlar / Boshqaruv',
      render: (r) => (
        <div className="flex items-center gap-1.5">
          {/* View PDF */}
          <a
            href={`${import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1'}/investments/${r.id}/agreement?token=${accessToken}`}
            target="_blank"
            rel="noopener noreferrer"
            className="p-2 bg-white dark:bg-slate-800 border border-gray-150 dark:border-slate-700 rounded-xl text-gray-600 dark:text-slate-300 hover:bg-primary-50 hover:text-primary-600 dark:hover:bg-primary-950/20 dark:hover:text-primary-400 transition-all duration-200 shadow-sm"
            title="PDF ko'rish"
          >
            <Eye size={13} />
          </a>

          {/* Download Word Document */}
          <a
            href={`${import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1'}/investments/${r.id}/agreement/word?token=${accessToken}`}
            className="p-2 bg-white dark:bg-slate-800 border border-gray-150 dark:border-slate-700 rounded-xl text-gray-600 dark:text-slate-300 hover:bg-emerald-50 hover:text-emerald-600 dark:hover:bg-emerald-950/20 dark:hover:text-emerald-400 transition-all duration-200 shadow-sm"
            title="Word faylini yuklab olish"
          >
            <FileDown size={13} />
          </a>

          {/* Upload Custom Contract PDF */}
          <label className="p-2 bg-indigo-50 dark:bg-indigo-950/20 text-indigo-600 dark:text-indigo-400 hover:bg-indigo-100 rounded-xl cursor-pointer transition-all duration-200 flex items-center justify-center shadow-sm">
            {uploadingId === r.id ? (
              <span className="animate-spin rounded-full h-3.5 w-3.5 border-b-2 border-indigo-600"></span>
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
            <span className="bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 font-bold flex items-center gap-1 px-2 py-1 rounded-xl text-[9px] uppercase tracking-wider font-black border border-emerald-100/50 dark:border-emerald-950/50" title="Maxsus yuridik PDF yuklangan">
              <CheckCircle2 size={11} className="animate-pulse" />
              <span>Maxsus</span>
            </span>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-2 duration-300">
      {/* Header Cards Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="p-6 bg-gradient-to-tr from-white to-gray-50/20 dark:from-slate-800 dark:to-slate-850 rounded-3xl border border-gray-150/40 dark:border-slate-750 shadow-sm flex items-center gap-5 hover:scale-[1.02] hover:shadow-md transition-all duration-300">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-primary-500 to-indigo-600 text-white flex items-center justify-center shadow-md shadow-primary-500/20">
            <FileText size={20} />
          </div>
          <div>
            <h3 className="text-gray-400 dark:text-slate-400 text-[10px] uppercase tracking-wider font-extrabold">Jami kelishuvlar</h3>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">
              {rows.length || 0} ta
            </p>
          </div>
        </div>

        <div className="p-6 bg-gradient-to-tr from-white to-gray-50/20 dark:from-slate-800 dark:to-slate-850 rounded-3xl border border-gray-150/40 dark:border-slate-750 shadow-sm flex items-center gap-5 hover:scale-[1.02] hover:shadow-md transition-all duration-300">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-emerald-400 to-teal-600 text-white flex items-center justify-center shadow-md shadow-emerald-500/20">
            <CheckCircle2 size={20} />
          </div>
          <div>
            <h3 className="text-gray-400 dark:text-slate-400 text-[10px] uppercase tracking-wider font-extrabold">Maxsus yuridik PDFlar</h3>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">
              {rows.filter(r => r.contractUrl).length || 0} ta
            </p>
          </div>
        </div>

        <div className="p-6 bg-gradient-to-tr from-white to-gray-50/20 dark:from-slate-800 dark:to-slate-850 rounded-3xl border border-gray-150/40 dark:border-slate-750 shadow-sm flex items-center gap-5 hover:scale-[1.02] hover:shadow-md transition-all duration-300">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-amber-400 to-orange-500 text-white flex items-center justify-center shadow-md shadow-amber-500/20">
            <AlertCircle size={20} />
          </div>
          <div>
            <h3 className="text-gray-400 dark:text-slate-400 text-[10px] uppercase tracking-wider font-extrabold">Tasdiqlanmagan shartnomalar</h3>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">
              {rows.filter(r => r.status === 'PENDING').length || 0} ta
            </p>
          </div>
        </div>
      </div>

      {/* Main Filter & Table Card */}
      <Card padded={false} className="overflow-hidden border border-gray-150/30 dark:border-slate-750 rounded-3xl shadow-sm bg-white dark:bg-slate-800">
        {/* Title Header */}
        <div className="p-6 border-b border-gray-100 dark:border-slate-700/60 space-y-5">
          <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
            <div>
              <h2 className="text-base font-black text-gray-900 dark:text-slate-100 tracking-tight flex items-center gap-2">
                <FileText className="text-primary-600 dark:text-primary-400" size={18} />
                Investitsiya Shartnomalari Tizimi
              </h2>
              <p className="text-[11px] text-gray-400 dark:text-slate-400 font-medium">Barcha yuridik shartnomalarni yuklash, ko'rish va Excel formatiga eksport qilish boshqaruvi</p>
            </div>

            {/* Quick Actions */}
            <div className="flex items-center gap-2 w-full lg:w-auto">
              <button
                onClick={() => setShowAdvanced(!showAdvanced)}
                className={`p-2 border rounded-xl flex items-center justify-center transition-all duration-200 ${
                  showAdvanced 
                    ? 'bg-primary-50 border-primary-300 text-primary-600 dark:bg-primary-950/30 dark:border-primary-800' 
                    : 'bg-white border-gray-200 text-gray-600 dark:bg-slate-900 dark:border-slate-700 dark:text-slate-350 hover:bg-gray-50'
                }`}
                title="Kengaytirilgan filtrlar"
              >
                <SlidersHorizontal size={14} />
              </button>

              <button
                onClick={handleExportCSV}
                className="px-4 py-2 bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-600 hover:to-teal-700 text-white rounded-xl text-xs font-black transition-all duration-200 flex items-center gap-1.5 shadow-sm shadow-emerald-500/10"
                title="Excelga eksport qilish"
              >
                <Download size={13} />
                <span>Excelga yuklash</span>
              </button>

              <div className="relative w-full lg:w-64">
                <span className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400">
                  <Search size={13} />
                </span>
                <input
                  type="text"
                  placeholder="Qidirish (Loyiha, investor)..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 text-xs font-semibold border border-gray-200 dark:border-slate-750 bg-gray-50/50 dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl outline-none focus:border-primary-500 transition"
                />
              </div>
            </div>
          </div>

          {/* Advanced Filters Panel */}
          {showAdvanced && (
            <div className="p-5 bg-gray-50/40 dark:bg-slate-900/50 border border-gray-150/40 dark:border-slate-800 rounded-2xl grid grid-cols-1 md:grid-cols-4 gap-4 animate-in slide-in-from-top-2 duration-200">
              <div>
                <label className="block text-[9px] font-black uppercase text-gray-400 mb-1.5 tracking-wider">Sarmoya summasi (Min)</label>
                <input
                  type="number"
                  placeholder="Masalan: 1,000,000 UZS"
                  value={minAmount}
                  onChange={(e) => setMinAmount(e.target.value)}
                  className="w-full px-3 py-1.5 text-xs font-semibold border border-gray-200 dark:border-slate-750 bg-white dark:bg-slate-950 text-gray-700 dark:text-slate-200 rounded-xl outline-none"
                />
              </div>
              
              <div>
                <label className="block text-[9px] font-black uppercase text-gray-400 mb-1.5 tracking-wider">Sarmoya summasi (Max)</label>
                <input
                  type="number"
                  placeholder="Masalan: 10,000,000 UZS"
                  value={maxAmount}
                  onChange={(e) => setMaxAmount(e.target.value)}
                  className="w-full px-3 py-1.5 text-xs font-semibold border border-gray-200 dark:border-slate-750 bg-white dark:bg-slate-950 text-gray-700 dark:text-slate-200 rounded-xl outline-none"
                />
              </div>

              <div>
                <label className="block text-[9px] font-black uppercase text-gray-400 mb-1.5 tracking-wider">Shartnoma Turi</label>
                <select
                  value={customPdfFilter}
                  onChange={(e) => setCustomPdfFilter(e.target.value)}
                  className="w-full px-3 py-1.5 text-xs font-semibold border border-gray-200 dark:border-slate-750 bg-white dark:bg-slate-950 text-gray-750 dark:text-slate-200 rounded-xl outline-none"
                >
                  <option value="all">Barchasi (Maxsus va Standart)</option>
                  <option value="custom">Faqat Maxsus PDF yuklanganlar</option>
                  <option value="standard">Faqat Standart shablonlar</option>
                </select>
              </div>

              <div className="flex items-end justify-end gap-2">
                <button
                  onClick={handleResetFilters}
                  className="px-4 py-1.5 border border-gray-200 dark:border-slate-700 text-gray-500 dark:text-slate-400 hover:bg-white dark:hover:bg-slate-950 rounded-xl text-xs font-bold transition flex items-center gap-1.5"
                >
                  <RotateCcw size={12} />
                  <span>Filtrlarni tozalash</span>
                </button>
              </div>
            </div>
          )}

          {/* Status Tabs/Chips filters */}
          <div className="flex flex-wrap items-center gap-1.5 border-b border-gray-50 dark:border-slate-700/30 pb-3">
            {FILTER_STATUSES.map((status) => (
              <button
                key={status.key}
                onClick={() => setSelectedStatus(status.key)}
                className={`px-4 py-2 rounded-xl text-xs font-black transition-all duration-200 flex items-center gap-1.5 ${
                  selectedStatus === status.key
                    ? 'bg-gradient-to-r from-primary-600 to-indigo-600 text-white shadow-md shadow-primary-500/10 scale-[1.02]'
                    : 'bg-gray-50 dark:bg-slate-900 text-gray-500 dark:text-slate-400 hover:bg-gray-100 dark:hover:bg-slate-800'
                }`}
              >
                {status.label}
              </button>
            ))}
          </div>
        </div>

        {/* Main Table */}
        {displayedRows.length === 0 && !loading ? (
          <div className="flex flex-col items-center justify-center py-24 text-center space-y-3">
            <div className="w-14 h-14 rounded-full bg-gray-50 dark:bg-slate-900 text-gray-400 flex items-center justify-center shadow-inner">
              <FileText size={22} />
            </div>
            <div>
              <p className="text-xs font-black text-gray-900 dark:text-slate-100">Hech qanday shartnoma topilmadi</p>
              <p className="text-[10px] text-gray-400 dark:text-slate-500 mt-1 max-w-xs">Kiritilgan qidiruv yoki filtr mezonlari bo'yicha ma'lumot topilmadi.</p>
            </div>
          </div>
        ) : (
          <DataTable
            loading={loading}
            error={error}
            onRetry={() => fetchRows(pageInfo.pageNumber)}
            rows={displayedRows}
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
