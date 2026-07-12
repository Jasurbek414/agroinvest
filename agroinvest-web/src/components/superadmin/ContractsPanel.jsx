import React, { useEffect, useState } from 'react';
import { FileText, Search, UploadCloud, CheckCircle2, AlertCircle, Eye } from 'lucide-react';
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

const ContractsPanel = () => {
  const [rows, setRows] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState('');
  const [uploadingId, setUploadingId] = useState(null);
  const debouncedSearch = useDebounce(search, 350);
  const { showToast } = useToast();

  const fetchRows = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getPlatformInvestments(page, 15, debouncedSearch || undefined);
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
  }, [debouncedSearch]);

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
      label: 'Loyiha',
      render: (r) => (
        <div className="font-semibold text-gray-900 dark:text-slate-100 max-w-xs truncate">
          {r.projectTitle}
        </div>
      ),
    },
    {
      key: 'investorName',
      label: 'Sarmoyador',
      render: (r) => (
        <span className="text-gray-600 dark:text-slate-300 font-medium">
          {r.investorName}
        </span>
      ),
    },
    {
      key: 'amount',
      label: 'Sarmoya summasi',
      render: (r) => (
        <span className="font-extrabold text-gray-900 dark:text-slate-100">
          {formatAmount(r.amount)}
        </span>
      ),
    },
    {
      key: 'sharePct',
      label: 'Ulush',
      render: (r) => (
        <span className="font-bold text-gray-700 dark:text-slate-400">
          {r.sharePct}%
        </span>
      ),
    },
    {
      key: 'status',
      label: 'Holati',
      render: (r) => (
        <Badge variant={STATUS_VARIANTS[r.status] || 'secondary'}>
          {STATUS_LABELS[r.status] || r.status}
        </Badge>
      ),
    },
    {
      key: 'createdAt',
      label: 'Sana',
      render: (r) => (
        <span className="text-gray-400 dark:text-slate-500 font-semibold text-[11px]">
          {formatDate(r.createdAt)}
        </span>
      ),
    },
    {
      key: 'actions',
      label: 'Shartnoma (PDF)',
      render: (r) => (
        <div className="flex items-center gap-2">
          {/* Download/View Link */}
          <a
            href={`${import.meta.env.VITE_API_BASE_URL || ''}/api/v1/investments/${r.id}/agreement`}
            target="_blank"
            rel="noopener noreferrer"
            className="p-1.5 bg-gray-50 dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl text-gray-600 dark:text-slate-300 hover:bg-gray-100 transition tooltip"
            title="Shartnomani ko'rish"
          >
            <Eye size={14} />
          </a>

          {/* Upload Button */}
          <label className="p-1.5 bg-primary-50 dark:bg-primary-950/20 text-primary-600 dark:text-primary-400 hover:bg-primary-100 rounded-xl cursor-pointer transition flex items-center justify-center">
            {uploadingId === r.id ? (
              <span className="animate-spin rounded-full h-3.5 w-3.5 border-b-2 border-primary-600"></span>
            ) : (
              <UploadCloud size={14} />
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
            <span className="text-emerald-600 dark:text-emerald-400 tooltip" title="Maxsus shartnoma yuklangan">
              <CheckCircle2 size={14} />
            </span>
          )}
        </div>
      ),
    },
  ];

  return (
    <Card padded={false} className="overflow-hidden">
      {/* Title Header */}
      <div className="p-6 border-b border-gray-100 dark:border-slate-700 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-lg font-bold text-gray-900 dark:text-slate-100">Investitsiya Shartnomalari Boshqaruvi</h2>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">Tomonlar o'rtasidagi yuridik bitimlarni nazorat qilish va maxsus PDF yuklash</p>
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

      {/* Main Table */}
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
    </Card>
  );
};

export default ContractsPanel;
