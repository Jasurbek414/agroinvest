import React, { useState, useEffect } from 'react';
import { getMyInvestments, cancelInvestment } from '../../api/investments.api';
import { getMyDashboard } from '../../api/dashboard.api';
import ConfirmDialog from '../../components/ui/ConfirmDialog';
import { useToast } from '../../components/ui/ToastProvider';
import ReviewFormModal from '../../components/reviews/ReviewFormModal';
import FarmerProfileModal from '../../components/investor/FarmerProfileModal';
import InvestorStatsBar from '../../components/investor/InvestorStatsBar';
import InvestmentsListTab from '../../components/investor/InvestmentsListTab';
import PortfolioTab from '../../components/investor/PortfolioTab';
import ReportsTimelineTab from '../../components/investor/ReportsTimelineTab';

const TABS = [
  { key: 'list', label: 'Sarmoyalarim' },
  { key: 'portfolio', label: 'Tahlillar' },
  { key: 'reports', label: 'Oxirgi hisobotlar' },
];

// Thin orchestrator for the investor cabinet: owns the shared data
// (investments page + dashboard aggregates) and the cross-tab modals;
// each tab's rendering/fetch details live in components/investor/*.
const MyInvestments = () => {
  const [investments, setInvestments] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [portfolio, setPortfolio] = useState(null);
  const [activeTab, setActiveTab] = useState('list');

  const [cancelTarget, setCancelTarget] = useState(null);
  const [reviewTarget, setReviewTarget] = useState(null);
  const [reviewedIds, setReviewedIds] = useState(() => new Set());
  const [farmerProfileTarget, setFarmerProfileTarget] = useState(null);

  const { showToast } = useToast();

  useEffect(() => {
    fetchInvestments();
    fetchPortfolio();
  }, []);

  const fetchPortfolio = async () => {
    try {
      const res = await getMyDashboard();
      setPortfolio(res.data);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchInvestments = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await getMyInvestments();
      setInvestments(response.data.content || []);
    } catch {
      setError('Investitsiyalarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = async () => {
    const investmentId = cancelTarget;
    setCancelTarget(null);
    try {
      await cancelInvestment(investmentId);
      showToast('Sarmoya muvaffaqiyatli bekor qilindi');
      fetchInvestments();
      fetchPortfolio();
    } catch (err) {
      showToast(err.error?.message || 'Bekor qilishda xatolik yuz berdi', 'error');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50/40 dark:bg-slate-950 p-6 md:p-12 transition-all duration-300">
      <div className="max-w-5xl mx-auto space-y-8 animate-in fade-in duration-300">

        {/* Header title with tab switcher */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-2xl md:text-3xl font-black text-gray-950 dark:text-slate-100 tracking-tight">Investor Kabineti</h1>
            <p className="text-xs sm:text-sm text-gray-550 dark:text-slate-400 mt-1">Sarmoyalaringiz, faol monitoringingiz va daromad tahlillari paneli</p>
          </div>

          <div className="flex bg-white dark:bg-slate-900 p-1.5 rounded-2xl border border-gray-150/40 dark:border-slate-800/80 shadow-sm shrink-0">
            {TABS.map((tab) => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={`px-4 py-2 text-xs font-bold rounded-xl transition-all duration-200 ${
                  activeTab === tab.key ? 'bg-primary-600 text-white shadow-sm' : 'text-gray-500 dark:text-slate-400 hover:text-primary-600 dark:hover:text-primary-400'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        <InvestorStatsBar portfolio={portfolio} />

        {activeTab === 'list' && (
          <InvestmentsListTab
            investments={investments}
            loading={loading}
            error={error}
            onRetry={fetchInvestments}
            reviewedIds={reviewedIds}
            onFarmerProfile={setFarmerProfileTarget}
            onCancel={setCancelTarget}
            onReview={setReviewTarget}
          />
        )}

        {activeTab === 'portfolio' && (
          <PortfolioTab investments={investments} portfolio={portfolio} />
        )}

        {activeTab === 'reports' && (
          <ReportsTimelineTab investments={investments} />
        )}

      </div>

      <ConfirmDialog
        open={!!cancelTarget}
        title="Sarmoyani bekor qilish"
        message="Haqiqatan ham ushbu sarmoyani bekor qilmoqchimisiz? Kiritilgan pul mablag'lari hamyoningiz balansiga qaytariladi."
        confirmLabel="Bekor qilish"
        tone="danger"
        onCancel={() => setCancelTarget(null)}
        onConfirm={handleCancel}
      />

      {reviewTarget && (
        <ReviewFormModal
          investment={reviewTarget}
          onClose={() => setReviewTarget(null)}
          onSubmitted={() => {
            setReviewedIds((prev) => new Set(prev).add(reviewTarget.id));
            setReviewTarget(null);
          }}
        />
      )}

      {farmerProfileTarget && (
        <FarmerProfileModal
          investment={farmerProfileTarget}
          onClose={() => setFarmerProfileTarget(null)}
        />
      )}
    </div>
  );
};

export default MyInvestments;
