import React, { useEffect, useState } from 'react';
import { createProject } from '../../api/projects.api';
import { getPublicSettings } from '../../api/settings.api';
import { ASSET_TYPE_META } from '../../utils/assetType';
import ImageUploadPicker from '../ui/ImageUploadPicker';
import { useToast } from '../ui/ToastProvider';
import AssetTypePicker from './create-project/AssetTypePicker';
import FundingModeSection from './create-project/FundingModeSection';
import ExpensePolicySection from './create-project/ExpensePolicySection';
import ProfitShareSlider from './create-project/ProfitShareSlider';
import ReportFrequencySlider from './create-project/ReportFrequencySlider';

const ASSET_TYPES = Object.entries(ASSET_TYPE_META).map(([value, meta]) => ({ value, label: meta.label }));

const CreateProjectForm = ({ onCreated }) => {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [assetType, setAssetType] = useState('LIVESTOCK');
  const [animalType, setAnimalType] = useState('');
  const [headcount, setHeadcount] = useState('');
  const [pricePerHead, setPricePerHead] = useState('');
  const [region, setRegion] = useState('Qashqadaryo');
  const [targetAmount, setTargetAmount] = useState('');
  const [expectedReturnPct, setExpectedReturnPct] = useState('20');
  const [durationDays, setDurationDays] = useState('90');
  const [riskLevel, setRiskLevel] = useState('MEDIUM');
  const [mediaUrls, setMediaUrls] = useState([]);
  const [docUrls, setDocUrls] = useState([]);
  const [fundingMode, setFundingMode] = useState('INVESTOR_FUNDED');
  const [farmerContributionValue, setFarmerContributionValue] = useState('');
  const [farmerContributionNotes, setFarmerContributionNotes] = useState('');
  const [expensePolicy, setExpensePolicy] = useState('INVESTOR_BUDGET');
  const [investorSharePct, setInvestorSharePct] = useState(70);
  const [reportFrequencyDays, setReportFrequencyDays] = useState(14);
  const [shareBounds, setShareBounds] = useState({ min: 50, max: 90 });
  const [submitting, setSubmitting] = useState(false);
  const { showToast } = useToast();

  const isAnimalProject = assetType === 'LIVESTOCK' || assetType === 'POULTRY';
  const hasContribution = fundingMode === 'FARMER_ASSETS' || fundingMode === 'MIXED';

  useEffect(() => {
    const loadSettings = async () => {
      try {
        const res = await getPublicSettings();
        const min = res.data.minInvestorSharePct ?? 50;
        const max = res.data.maxInvestorSharePct ?? 90;
        setShareBounds({ min, max });
        setInvestorSharePct(Math.min(Math.max(res.data.defaultInvestorSharePct ?? 70, min), max));
      } catch {
        // fall back to hardcoded defaults - slider still works
      }
    };
    loadSettings();
  }, []);

  const handleAssetTypeChange = (value) => {
    setAssetType(value);
    if (value !== 'LIVESTOCK' && value !== 'POULTRY') setAnimalType('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!title || !description || !targetAmount) {
      showToast("Iltimos, barcha majburiy maydonlarni to'ldiring", 'error');
      return;
    }
    if (isAnimalProject && !animalType) {
      showToast("Hayvon turini tanlang", 'error');
      return;
    }
    if (isAnimalProject && !(parseInt(headcount) > 0)) {
      showToast("Hayvonlar sonini (bosh) kiriting", 'error');
      return;
    }
    if (hasContribution && !(parseFloat(farmerContributionValue) > 0)) {
      showToast("Fermer hissasi qiymatini kiriting", 'error');
      return;
    }

    setSubmitting(true);
    try {
      await createProject({
        title,
        description,
        assetType,
        animalType: isAnimalProject ? animalType : null,
        headcount: isAnimalProject && headcount ? parseInt(headcount) : null,
        pricePerHead: isAnimalProject && pricePerHead ? parseFloat(pricePerHead) : null,
        region,
        targetAmount: parseFloat(targetAmount),
        expectedReturnPct: parseFloat(expectedReturnPct),
        durationDays: parseInt(durationDays),
        riskLevel,
        mediaUrls: [...mediaUrls, ...docUrls],
        fundingMode,
        farmerContributionValue: hasContribution ? parseFloat(farmerContributionValue) : 0,
        farmerContributionNotes: hasContribution ? farmerContributionNotes : null,
        expensePolicy,
        proposedInvestorSharePct: investorSharePct,
        reportFrequencyDays,
      });
      showToast('Loyiha arizasi muvaffaqiyatli topshirildi va tekshirilmoqda!');
      setTitle('');
      setDescription('');
      setTargetAmount('');
      setMediaUrls([]);
      setAnimalType('');
      setHeadcount('');
      setPricePerHead('');
      setFarmerContributionValue('');
      setFarmerContributionNotes('');
      onCreated?.();
    } catch (err) {
      showToast(err.error?.message || 'Loyiha yaratishda xatolik yuz berdi', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="bg-white dark:bg-slate-800 p-6 md:p-8 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm max-w-2xl mx-auto">
      <h2 className="text-lg font-bold text-gray-900 dark:text-slate-100 mb-6">Yangi loyiha arizasi</h2>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Loyiha nomi (Title)</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Masalan: 50 ta zotdor qo'ylar"
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              required
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Aktiv turi</label>
            <select
              value={assetType}
              onChange={(e) => handleAssetTypeChange(e.target.value)}
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 rounded-xl text-sm outline-none bg-white dark:bg-slate-900 dark:text-slate-100 focus:ring-1 focus:ring-primary-500"
            >
              {ASSET_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>
          </div>
        </div>

        <AssetTypePicker
          isAnimalProject={isAnimalProject}
          animalType={animalType}
          setAnimalType={setAnimalType}
          headcount={headcount}
          setHeadcount={setHeadcount}
          pricePerHead={pricePerHead}
          setPricePerHead={setPricePerHead}
        />

        <div>
          <label className="block text-xs font-semibold text-gray-600 mb-1.5">Tavsif (Description)</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Loyiha jarayoni va batafsil tushuntirish"
            rows="4"
            className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
            required
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-600 mb-1.5">Loyiha rasmlari</label>
          <ImageUploadPicker category="project" urls={mediaUrls} onChange={setMediaUrls} />
        </div>

        <div className="mt-4">
          <label className="block text-xs font-semibold text-gray-600 mb-1.5">Loyiha hujjatlari (PDF, Word, Excel)</label>
          <ImageUploadPicker
            category="project"
            urls={docUrls}
            onChange={setDocUrls}
            accept="application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            maxImages={3}
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Kerakli summa (UZS)</label>
            <input
              type="number"
              value={targetAmount}
              onChange={(e) => setTargetAmount(e.target.value)}
              placeholder="Masalan: 15000000"
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              required
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Hudud / Viloyat</label>
            <input
              type="text"
              value={region}
              onChange={(e) => setRegion(e.target.value)}
              placeholder="Masalan: Qashqadaryo"
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              required
            />
          </div>
        </div>

        <div className="grid grid-cols-3 gap-4">
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Muddati (Kun)</label>
            <input
              type="number"
              value={durationDays}
              onChange={(e) => setDurationDays(e.target.value)}
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Kutilayotgan foyda (%)</label>
            <input
              type="number"
              value={expectedReturnPct}
              onChange={(e) => setExpectedReturnPct(e.target.value)}
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Xavf darajasi</label>
            <select
              value={riskLevel}
              onChange={(e) => setRiskLevel(e.target.value)}
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 rounded-xl text-sm outline-none bg-white dark:bg-slate-900 dark:text-slate-100 focus:ring-1 focus:ring-primary-500"
            >
              <option value="LOW">Kam xavfli (LOW)</option>
              <option value="MEDIUM">O'rtacha xavfli (MEDIUM)</option>
              <option value="HIGH">Yuqori xavfli (HIGH)</option>
            </select>
          </div>
        </div>

        <FundingModeSection
          fundingMode={fundingMode}
          setFundingMode={setFundingMode}
          hasContribution={hasContribution}
          farmerContributionValue={farmerContributionValue}
          setFarmerContributionValue={setFarmerContributionValue}
          farmerContributionNotes={farmerContributionNotes}
          setFarmerContributionNotes={setFarmerContributionNotes}
        />

        <ProfitShareSlider
          investorSharePct={investorSharePct}
          setInvestorSharePct={setInvestorSharePct}
          shareBounds={shareBounds}
        />

        <ExpensePolicySection expensePolicy={expensePolicy} setExpensePolicy={setExpensePolicy} />

        <ReportFrequencySlider reportFrequencyDays={reportFrequencyDays} setReportFrequencyDays={setReportFrequencyDays} />

        <button
          type="submit"
          disabled={submitting}
          className="w-full py-3 bg-primary-600 hover:bg-primary-700 disabled:bg-primary-300 text-white font-bold rounded-xl shadow-lg shadow-primary-600/10 transition mt-4"
        >
          {submitting ? 'Yuborilmoqda...' : "Arizani jo'natish"}
        </button>
      </form>
    </div>
  );
};

export default CreateProjectForm;
