import React, { useEffect, useState } from 'react';
import { getMyInvestments } from '../../api/investments.api';
import { getMyProjects, getProjectById } from '../../api/projects.api';
import { getProjectInvestments } from '../../api/investments.api';
import { fileDispute } from '../../api/disputes.api';
import { useToast } from '../ui/ToastProvider';

const DISPUTE_TYPES = [
  { value: 'PROJECT_ABANDONED', label: "Loyiha e'tiborsiz qoldirilgan" },
  { value: 'NO_REPORTS', label: 'Hisobotlar yuborilmayapti' },
  { value: 'FUNDS_MISUSE', label: "Mablag' noto'g'ri ishlatilgan" },
  { value: 'PAYOUT_DELAY', label: "To'lov kechikmoqda" },
  { value: 'OTHER', label: 'Boshqa' },
];

// Investors dispute against the project's farmer; farmers dispute against a specific
// investor in one of their own projects. Which picker renders depends on role, but the
// submit contract to the backend (projectId + againstUserId) is identical either way.
const DisputeForm = ({ user, onFiled }) => {
  const isInvestor = user?.role === 'INVESTOR';

  const [projects, setProjects] = useState([]);
  const [loadingProjects, setLoadingProjects] = useState(true);
  const [projectId, setProjectId] = useState('');
  const [against, setAgainst] = useState(null); // { id, name }
  const [investorOptions, setInvestorOptions] = useState([]);
  const [disputeType, setDisputeType] = useState(DISPUTE_TYPES[0].value);
  const [description, setDescription] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const { showToast } = useToast();

  useEffect(() => {
    const loadProjects = async () => {
      setLoadingProjects(true);
      try {
        if (isInvestor) {
          const res = await getMyInvestments(0, 100);
          const seen = new Map();
          (res.data.content || []).forEach((inv) => {
            if (!seen.has(inv.projectId)) {
              seen.set(inv.projectId, { id: inv.projectId, title: inv.projectTitle });
            }
          });
          setProjects(Array.from(seen.values()));
        } else {
          const res = await getMyProjects(0, 100);
          setProjects((res.data.content || []).map((p) => ({ id: p.id, title: p.title })));
        }
      } catch (err) {
        showToast(err.error?.message || "Loyihalar ro'yxatini yuklashda xatolik", 'error');
      } finally {
        setLoadingProjects(false);
      }
    };
    loadProjects();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isInvestor]);

  const handleProjectChange = async (id) => {
    setProjectId(id);
    setAgainst(null);
    setInvestorOptions([]);
    if (!id) return;

    try {
      if (isInvestor) {
        const res = await getProjectById(id);
        setAgainst({ id: res.data.farmerId, name: res.data.farmerName });
      } else {
        const res = await getProjectInvestments(id);
        setInvestorOptions((res.data || []).map((inv) => ({ id: inv.investorId, name: inv.investorName })));
      }
    } catch (err) {
      showToast(err.error?.message || "Ma'lumotlarni yuklashda xatolik", 'error');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!projectId || !against?.id || !description.trim()) {
      showToast("Barcha maydonlarni to'ldiring", 'error');
      return;
    }
    setSubmitting(true);
    try {
      await fileDispute(projectId, against.id, disputeType, description.trim());
      showToast('Shikoyatingiz qabul qilindi');
      setDescription('');
      setProjectId('');
      setAgainst(null);
      onFiled?.();
    } catch (err) {
      showToast(err.error?.message || 'Shikoyat yuborishda xatolik yuz berdi', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  if (loadingProjects) {
    return <p className="text-sm text-gray-400 dark:text-slate-500 animate-pulse">Yuklanmoqda...</p>;
  }

  if (projects.length === 0) {
    return (
      <p className="text-sm text-gray-400 dark:text-slate-500">
        {isInvestor
          ? "Shikoyat ochish uchun avval biror loyihaga sarmoya kiritgan bo'lishingiz kerak."
          : "Shikoyat ochish uchun avval tasdiqlangan loyihangiz bo'lishi kerak."}
      </p>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Loyiha</label>
        <select
          value={projectId}
          onChange={(e) => handleProjectChange(e.target.value)}
          className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 rounded-xl text-sm outline-none bg-white dark:bg-slate-900 dark:text-slate-100 focus:ring-1 focus:ring-primary-500"
          required
        >
          <option value="">Loyihani tanlang</option>
          {projects.map((p) => (
            <option key={p.id} value={p.id}>{p.title}</option>
          ))}
        </select>
      </div>

      {!isInvestor && projectId && (
        <div>
          <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Shikoyat qilinayotgan investor</label>
          <select
            value={against?.id || ''}
            onChange={(e) => {
              const found = investorOptions.find((o) => o.id === e.target.value);
              setAgainst(found || null);
            }}
            className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 rounded-xl text-sm outline-none bg-white dark:bg-slate-900 dark:text-slate-100 focus:ring-1 focus:ring-primary-500"
            required
          >
            <option value="">Investorni tanlang</option>
            {investorOptions.map((o) => (
              <option key={o.id} value={o.id}>{o.name}</option>
            ))}
          </select>
        </div>
      )}

      {isInvestor && against && (
        <p className="text-xs text-gray-500 dark:text-slate-400">
          Shikoyat qilinadigan fermer: <span className="font-bold text-gray-700 dark:text-slate-300">{against.name}</span>
        </p>
      )}

      <div>
        <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Shikoyat turi</label>
        <select
          value={disputeType}
          onChange={(e) => setDisputeType(e.target.value)}
          className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 rounded-xl text-sm outline-none bg-white dark:bg-slate-900 dark:text-slate-100 focus:ring-1 focus:ring-primary-500"
        >
          {DISPUTE_TYPES.map((t) => (
            <option key={t.value} value={t.value}>{t.label}</option>
          ))}
        </select>
      </div>

      <div>
        <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Tafsilotlar</label>
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          rows="4"
          placeholder="Vaziyatni batafsil tasvirlab bering"
          className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
          required
        />
      </div>

      <button
        type="submit"
        disabled={submitting || !against}
        className="w-full py-3 bg-red-600 hover:bg-red-700 disabled:bg-red-300 text-white font-bold rounded-xl shadow-sm transition"
      >
        {submitting ? 'Yuborilmoqda...' : 'Shikoyatni yuborish'}
      </button>
    </form>
  );
};

export default DisputeForm;
