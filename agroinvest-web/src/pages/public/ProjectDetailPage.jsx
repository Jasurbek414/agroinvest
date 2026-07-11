import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { getProjectById } from '../../api/projects.api';
import { useAuthStore } from '../../store/auth.store';
import { useToast } from '../../components/ui/ToastProvider';
import InvestmentModal from '../../components/projects/InvestmentModal';
import ProjectReportsList from '../../components/projects/ProjectReportsList';
import ProjectInvestorsList from '../../components/projects/ProjectInvestorsList';
import ProjectExpensesList from '../../components/projects/ProjectExpensesList';
import ProjectVetInspectionsList from '../../components/projects/ProjectVetInspectionsList';
import RiskDisclosure from '../../components/projects/RiskDisclosure';
import FarmerReviewsList from '../../components/reviews/FarmerReviewsList';
import Badge from '../../components/ui/Badge';
import { formatAmount } from '../../utils/format';
import { getAnimalTypeMeta } from '../../utils/animalType';

const ProjectDetailPage = () => {
  const { id } = useParams();
  const [project, setProject] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showModal, setShowModal] = useState(false);

  const { user } = useAuthStore();
  const { showToast } = useToast();
  const navigate = useNavigate();

  useEffect(() => {
    fetchProject();
  }, [id]);

  const fetchProject = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await getProjectById(id);
      setProject(response.data);
    } catch (err) {
      setError("Loyihani yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  const handleInvestClick = () => {
    if (!user) {
      navigate('/login');
      return;
    }
    if (user.role !== 'INVESTOR') {
      showToast("Faqat investorlar loyihalarga sarmoya kiritishi mumkin", 'error');
      return;
    }
    setShowModal(true);
  };

  const handleSuccess = () => {
    setShowModal(false);
    fetchProject(); // Reload details (e.g. raised amount)
    showToast('Tabriklaymiz! Sarmoyangiz muvaffaqiyatli qabul qilindi!');
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-slate-900">
        <p className="text-gray-500 dark:text-slate-400 font-semibold animate-pulse">Yuklanmoqda...</p>
      </div>
    );
  }

  if (error || !project) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-slate-900 p-6">
        <div className="text-center py-8 px-6 bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 max-w-sm">
          <p className="text-red-600 dark:text-red-400 font-bold mb-4">{error || "Loyiha topilmadi"}</p>
          <Link to="/projects" className="text-primary-600 dark:text-primary-400 font-bold hover:underline">Loyihalarga qaytish</Link>
        </div>
      </div>
    );
  }

  const {
    title,
    description,
    assetType,
    animalType,
    riskLevel,
    targetAmount,
    raisedAmount,
    expectedReturnPct,
    durationDays,
    status,
    region,
    locationDetails,
    farmerId,
    farmerName,
    mediaUrls,
    investorSharePct,
    farmerSharePct,
    farmerContributionValue,
    farmerContributionVerifiedAt,
    totalInvestors,
  } = project;

  const percent = Math.min(100, Math.round((raisedAmount / targetAmount) * 100));
  const animalMeta = animalType ? getAnimalTypeMeta(animalType) : null;

  const isDocument = (url) => {
    const lower = (url || '').toLowerCase();
    return lower.endsWith('.pdf') || lower.endsWith('.docx') || lower.endsWith('.doc') || lower.endsWith('.xls') || lower.endsWith('.xlsx') || lower.endsWith('.txt');
  };
  const images = (mediaUrls || []).filter(url => !isDocument(url));
  const documents = (mediaUrls || []).filter(url => isDocument(url));

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-slate-900 p-6 md:p-12">
      <div className="max-w-4xl mx-auto bg-white dark:bg-slate-800 rounded-3xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden">
        {/* Banner image or placeholder */}
        <div className="h-64 bg-gradient-to-r from-primary-600 to-primary-800 flex items-center justify-center p-8 text-center text-white">
          <div>
            <span className="text-xs uppercase tracking-widest bg-white/20 px-3 py-1 rounded-full">{assetType}</span>
            {animalMeta && (
              <span className="text-xs uppercase tracking-widest bg-white/20 px-3 py-1 rounded-full ml-2">{animalMeta.label}</span>
            )}
            <h1 className="text-2xl md:text-4xl font-extrabold mt-3">{title}</h1>
            <p className="mt-2 text-primary-100 text-sm">Fermer: {farmerName} | Joylashuv: {region}</p>
          </div>
        </div>

        <div className="p-8 grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Main info */}
          <div className="md:col-span-2 space-y-6">
            {farmerContributionValue > 0 && (
              <div className="bg-primary-50 dark:bg-primary-950 border border-primary-100 dark:border-primary-900 rounded-2xl p-4 flex items-start gap-3">
                <span className="text-lg">🐄</span>
                <div>
                  <p className="text-sm font-bold text-primary-800 dark:text-primary-300">
                    Fermer o'z hissasini qo'shdi: {formatAmount(farmerContributionValue)}
                  </p>
                  {farmerContributionVerifiedAt && (
                    <p className="text-[11px] text-primary-600 dark:text-primary-400 mt-0.5">Admin tomonidan tasdiqlangan ✓</p>
                  )}
                </div>
              </div>
            )}

            <div>
              <h2 className="text-xl font-bold text-gray-900 dark:text-slate-100 mb-3">Loyiha haqida</h2>
              <p className="text-gray-600 dark:text-slate-300 text-sm leading-relaxed whitespace-pre-line">{description}</p>
            </div>

            <RiskDisclosure riskLevel={riskLevel} />

            {investorSharePct != null && (
              <div className="pt-4 border-t border-gray-100 dark:border-slate-700">
                <h2 className="text-xl font-bold text-gray-900 dark:text-slate-100 mb-3">Sof foyda taqsimoti</h2>
                <div className="w-full h-2.5 rounded-full overflow-hidden flex bg-gray-100 dark:bg-slate-700">
                  <div className="bg-primary-600 h-full" style={{ width: `${investorSharePct}%` }} />
                  <div className="bg-amber-500 h-full" style={{ width: `${farmerSharePct}%` }} />
                </div>
                <div className="flex justify-between text-xs font-semibold mt-2">
                  <span className="text-primary-700 dark:text-primary-400">Investorlar {investorSharePct}%</span>
                  <span className="text-amber-600 dark:text-amber-400">Fermer {farmerSharePct}%</span>
                </div>
              </div>
            )}

            {images.length > 0 && (
              <div>
                <h2 className="text-xl font-bold text-gray-900 dark:text-slate-100 mb-3">Foto / Video dalillar</h2>
                <div className="grid grid-cols-2 gap-4">
                  {images.map((url, i) => (
                    <img key={i} src={url} alt={`${title} loyihasi rasmi ${i + 1}`} className="rounded-xl border border-gray-100 dark:border-slate-600 h-36 w-full object-cover" />
                  ))}
                </div>
              </div>
            )}

            {documents.length > 0 && (
              <div className="pt-4 border-t border-gray-100 dark:border-slate-700">
                <h2 className="text-xl font-bold text-gray-900 dark:text-slate-100 mb-3">Loyiha hujjatlari (To'liq ma'lumot)</h2>
                <div className="space-y-2">
                  {documents.map((url, i) => {
                    const filename = url.split('/').pop() || `Loyiha_hujjat_${i + 1}`;
                    return (
                      <a
                        key={i}
                        href={url}
                        target="_blank"
                        rel="noreferrer"
                        className="flex items-center justify-between p-4 bg-gray-50 hover:bg-gray-100 dark:bg-slate-900 dark:hover:bg-slate-950 border border-gray-100 dark:border-slate-800 rounded-2xl transition group"
                      >
                        <div className="flex items-center gap-3">
                          <span className="text-xl">📄</span>
                          <span className="text-xs font-bold text-gray-700 dark:text-slate-200 group-hover:text-primary-600 transition truncate max-w-[240px] md:max-w-md">
                            {decodeURIComponent(filename)}
                          </span>
                        </div>
                        <span className="text-[10px] font-black bg-primary-50 dark:bg-primary-950/40 text-primary-700 dark:text-primary-400 px-2.5 py-1 rounded-lg">
                          Yuklab olish
                        </span>
                      </a>
                    );
                  })}
                </div>
              </div>
            )}

            <div className="pt-4 border-t border-gray-100 dark:border-slate-700 grid grid-cols-2 gap-4 text-sm text-gray-500 dark:text-slate-400">
              <div>
                <p className="font-semibold text-gray-400 dark:text-slate-500">Hudud</p>
                <p className="text-gray-800 dark:text-slate-200 font-bold mt-0.5">{region || "Ko'rsatilmagan"}</p>
              </div>
              <div>
                <p className="font-semibold text-gray-400 dark:text-slate-500">Batafsil manzil</p>
                <p className="text-gray-800 dark:text-slate-200 font-bold mt-0.5">{locationDetails || "Ko'rsatilmagan"}</p>
              </div>
            </div>

            <div className="pt-6 border-t border-gray-100 dark:border-slate-700">
              <h2 className="text-xl font-bold text-gray-900 dark:text-slate-100 mb-4">Fermer hisobotlari</h2>
              <ProjectReportsList projectId={id} />
            </div>

            {totalInvestors > 0 && (
              <div className="pt-6 border-t border-gray-100 dark:border-slate-700">
                <h2 className="text-xl font-bold text-gray-900 dark:text-slate-100 mb-4">Sherik investorlar ({totalInvestors})</h2>
                <ProjectInvestorsList projectId={id} />
              </div>
            )}

            <div className="pt-6 border-t border-gray-100 dark:border-slate-700">
              <h2 className="text-xl font-bold text-gray-900 dark:text-slate-100 mb-4">Harajatlar</h2>
              <ProjectExpensesList projectId={id} />
            </div>

            <div className="pt-6 border-t border-gray-100 dark:border-slate-700">
              <h2 className="text-xl font-bold text-gray-900 dark:text-slate-100 mb-4">Veterinar nazorati</h2>
              <ProjectVetInspectionsList projectId={id} />
            </div>

            <div className="pt-6 border-t border-gray-100 dark:border-slate-700">
              <h2 className="text-xl font-bold text-gray-900 dark:text-slate-100 mb-4">Fermer haqida investorlar fikri</h2>
              <FarmerReviewsList farmerId={farmerId} />
            </div>
          </div>

          {/* Fundraising Box */}
          <div className="bg-gray-50 dark:bg-slate-900/60 p-6 rounded-2xl border border-gray-100 dark:border-slate-700 flex flex-col justify-between h-fit space-y-6">
            <div>
              <span className="text-xs font-bold text-gray-400 dark:text-slate-500 uppercase">Moliyaviy ko'rsatkichlar</span>
              <div className="grid grid-cols-2 gap-4 mt-4 mb-6">
                <div className="bg-white dark:bg-slate-800 p-3 rounded-xl border border-gray-100 dark:border-slate-700 text-center">
                  <p className="text-[10px] text-gray-400 dark:text-slate-500 uppercase font-semibold">Daromadlilik</p>
                  <p className="text-xl font-black text-primary-600 dark:text-primary-400">+{expectedReturnPct}%</p>
                </div>
                <div className="bg-white dark:bg-slate-800 p-3 rounded-xl border border-gray-100 dark:border-slate-700 text-center">
                  <p className="text-[10px] text-gray-400 dark:text-slate-500 uppercase font-semibold">Muddat</p>
                  <p className="text-xl font-bold text-gray-800 dark:text-slate-200">{durationDays} kun</p>
                </div>
              </div>

              {/* Progress */}
              <div className="space-y-2 mb-6">
                <div className="flex justify-between text-xs font-semibold text-gray-500 dark:text-slate-400">
                  <span>Yig'ildi: {percent}%</span>
                  <span className="text-gray-900 dark:text-slate-100 font-bold">{formatAmount(raisedAmount)}</span>
                </div>
                <div className="w-full bg-gray-200 dark:bg-slate-700 h-2 rounded-full overflow-hidden">
                  <div className="bg-primary-600 h-full rounded-full" style={{ width: `${percent}%` }} />
                </div>
                <p className="text-right text-[10px] text-gray-400 dark:text-slate-500">Maqsad: {formatAmount(targetAmount)}</p>
              </div>

              <div className="space-y-3 text-xs text-gray-500 dark:text-slate-400 border-t border-gray-100 dark:border-slate-700 pt-4">
                <div className="flex justify-between items-center">
                  <span>Risk darajasi</span>
                  <Badge status={riskLevel} />
                </div>
                <div className="flex justify-between items-center">
                  <span>Loyiha holati</span>
                  <Badge status={status} />
                </div>
              </div>
            </div>

            {(status === 'FUNDING' || status === 'APPROVED') && (
              <button
                onClick={handleInvestClick}
                className="w-full py-3 bg-primary-600 hover:bg-primary-700 text-white font-bold rounded-xl shadow-lg shadow-primary-600/20 transition"
              >
                Sarmoya kiritish
              </button>
            )}

            <p className="text-[11px] text-gray-400 dark:text-slate-500 leading-relaxed border-t border-gray-100 dark:border-slate-700 pt-4">
              Kafolatlangan daromad yo'q. Barcha investitsiyalar xavf bilan bog'liq va loyiha muvaffaqiyatsiz bo'lsa, mablag'ingizni qisman yoki to'liq yo'qotishingiz mumkin.
            </p>
          </div>
        </div>
      </div>

      {showModal && (
        <InvestmentModal
          project={project}
          onClose={() => setShowModal(false)}
          onSuccess={handleSuccess}
        />
      )}
    </div>
  );
};

export default ProjectDetailPage;
