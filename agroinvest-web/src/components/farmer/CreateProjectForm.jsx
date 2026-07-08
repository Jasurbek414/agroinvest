import React, { useEffect, useState } from 'react';
import { createProject } from '../../api/projects.api';
import { getPublicSettings } from '../../api/settings.api';
import { ASSET_TYPE_META } from '../../utils/assetType';
import { ANIMAL_TYPE_META } from '../../utils/animalType';
import ImageUploadPicker from '../ui/ImageUploadPicker';
import { useToast } from '../ui/ToastProvider';

const ASSET_TYPES = Object.entries(ASSET_TYPE_META).map(([value, meta]) => ({ value, label: meta.label }));
const ANIMAL_TYPES = Object.entries(ANIMAL_TYPE_META).map(([value, meta]) => ({ value, label: meta.label }));

const FUNDING_MODES = [
  { value: 'INVESTOR_FUNDED', label: 'To\'liq investor puliga', hint: 'Barcha hayvonlar yig\'ilgan mablag\'ga sotib olinadi' },
  { value: 'FARMER_ASSETS', label: 'O\'z hayvonlarim bilan', hint: 'Mavjud hayvonlarni loyihaga qo\'shaman (admin tasdiqlaydi)' },
  { value: 'MIXED', label: 'Aralash', hint: 'Qisman o\'zim, qisman investor mablag\'i' },
];

const EXPENSE_POLICIES = [
  { value: 'INVESTOR_BUDGET', label: 'Loyiha byudjetidan', hint: 'Yig\'ilgan mablag\' ichidan, shaffof hisobda' },
  { value: 'FARMER_REIMBURSED', label: 'O\'zim to\'layman', hint: 'Sotuvdan keyin, foyda bo\'linishidan OLDIN qaytariladi' },
  { value: 'MIXED', label: 'Aralash', hint: 'Har bir harajatda alohida belgilayman' },
];

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
        mediaUrls,
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
    <div className="bg-white p-6 md:p-8 rounded-2xl border border-gray-100 shadow-sm max-w-2xl mx-auto">
      <h2 className="text-lg font-bold text-gray-900 mb-6">Yangi loyiha arizasi</h2>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Loyiha nomi (Title)</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Masalan: 50 ta zotdor qo'ylar"
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
              required
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Aktiv turi</label>
            <select
              value={assetType}
              onChange={(e) => { setAssetType(e.target.value); if (e.target.value !== 'LIVESTOCK' && e.target.value !== 'POULTRY') setAnimalType(''); }}
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none bg-white focus:ring-1 focus:ring-green-500"
            >
              {ASSET_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>
          </div>
        </div>

        {isAnimalProject && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5">Hayvon turi</label>
              <select
                value={animalType}
                onChange={(e) => setAnimalType(e.target.value)}
                className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none bg-white focus:ring-1 focus:ring-green-500"
                required={isAnimalProject}
              >
                <option value="">Tanlang</option>
                {ANIMAL_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>{t.label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5">Bosh soni</label>
              <input
                type="number"
                value={headcount}
                onChange={(e) => setHeadcount(e.target.value)}
                placeholder="50"
                className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
                required={isAnimalProject}
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5">Bir bosh narxi (so'm)</label>
              <input
                type="number"
                value={pricePerHead}
                onChange={(e) => setPricePerHead(e.target.value)}
                placeholder="1500000"
                className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
              />
            </div>
          </div>
        )}

        <div>
          <label className="block text-xs font-semibold text-gray-600 mb-1.5">Tavsif (Description)</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Loyiha jarayoni va batafsil tushuntirish"
            rows="4"
            className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
            required
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-600 mb-1.5">Loyiha rasmlari</label>
          <ImageUploadPicker category="project" urls={mediaUrls} onChange={setMediaUrls} />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Kerakli summa (UZS)</label>
            <input
              type="number"
              value={targetAmount}
              onChange={(e) => setTargetAmount(e.target.value)}
              placeholder="Masalan: 15000000"
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
              required
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Hudud / Viloyat</label>
            <input
              type="text"
              value={region}
              onChange={(e) => setRegion(e.target.value)}
              placeholder="Masalan: Qashqadaryo"
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
              required
            />
          </div>
        </div>

        <div className="grid grid-cols-3 gap-4">
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Muddati (Kun)</label>
            <input
              type="number"
              value={durationDays}
              onChange={(e) => setDurationDays(e.target.value)}
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Kutilayotgan foyda (%)</label>
            <input
              type="number"
              value={expectedReturnPct}
              onChange={(e) => setExpectedReturnPct(e.target.value)}
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Xavf darajasi</label>
            <select
              value={riskLevel}
              onChange={(e) => setRiskLevel(e.target.value)}
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none bg-white focus:ring-1 focus:ring-green-500"
            >
              <option value="LOW">Kam xavfli (LOW)</option>
              <option value="MEDIUM">O'rtacha xavfli (MEDIUM)</option>
              <option value="HIGH">Yuqori xavfli (HIGH)</option>
            </select>
          </div>
        </div>

        {/* --- Funding mode --- */}
        <div className="pt-2 border-t border-gray-100">
          <label className="block text-xs font-semibold text-gray-600 mb-2 mt-4">Moliyalashtirish usuli</label>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-2">
            {FUNDING_MODES.map((m) => (
              <button
                key={m.value}
                type="button"
                onClick={() => setFundingMode(m.value)}
                className={`text-left p-3 rounded-xl border text-xs transition ${
                  fundingMode === m.value ? 'border-green-500 bg-green-50' : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <p className="font-bold text-gray-800">{m.label}</p>
                <p className="text-gray-500 mt-0.5">{m.hint}</p>
              </button>
            ))}
          </div>

          {hasContribution && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-3">
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5">Mening hissam qiymati (so'm)</label>
                <input
                  type="number"
                  value={farmerContributionValue}
                  onChange={(e) => setFarmerContributionValue(e.target.value)}
                  placeholder="5000000"
                  className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
                  required={hasContribution}
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5">Izoh (necha bosh, qanday holatda)</label>
                <input
                  type="text"
                  value={farmerContributionNotes}
                  onChange={(e) => setFarmerContributionNotes(e.target.value)}
                  placeholder="Masalan: 10 ta sog'lom qo'y, 8 oylik"
                  className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
                />
              </div>
            </div>
          )}
        </div>

        {/* --- Negotiated profit split --- */}
        <div className="pt-2 border-t border-gray-100">
          <label className="block text-xs font-semibold text-gray-600 mb-1 mt-4">
            Sof foyda taqsimoti ({shareBounds.min}%–{shareBounds.max}%)
          </label>
          <p className="text-[11px] text-gray-400 mb-2">Investorlar jamoasiga qancha ulush taklif qilasiz?</p>
          <div className="flex items-center gap-4">
            <span className="text-xs font-bold text-green-700 w-24">Investor {investorSharePct}%</span>
            <input
              type="range"
              min={shareBounds.min}
              max={shareBounds.max}
              value={investorSharePct}
              onChange={(e) => setInvestorSharePct(parseInt(e.target.value))}
              className="flex-1 accent-green-600"
            />
            <span className="text-xs font-bold text-amber-600 w-24 text-right">Fermer {100 - investorSharePct}%</span>
          </div>
        </div>

        {/* --- Expense policy --- */}
        <div className="pt-2 border-t border-gray-100">
          <label className="block text-xs font-semibold text-gray-600 mb-2 mt-4">Joriy harajatlar siyosati</label>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-2">
            {EXPENSE_POLICIES.map((p) => (
              <button
                key={p.value}
                type="button"
                onClick={() => setExpensePolicy(p.value)}
                className={`text-left p-3 rounded-xl border text-xs transition ${
                  expensePolicy === p.value ? 'border-green-500 bg-green-50' : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <p className="font-bold text-gray-800">{p.label}</p>
                <p className="text-gray-500 mt-0.5">{p.hint}</p>
              </button>
            ))}
          </div>
        </div>

        {/* --- Report frequency --- */}
        <div className="pt-2 border-t border-gray-100">
          <label className="block text-xs font-semibold text-gray-600 mb-1 mt-4">
            Hisobot chastotasi ({reportFrequencyDays === 1 ? 'kunlik' : `har ${reportFrequencyDays} kunda`})
          </label>
          <input
            type="range"
            min={1}
            max={14}
            value={reportFrequencyDays}
            onChange={(e) => setReportFrequencyDays(parseInt(e.target.value))}
            className="w-full accent-green-600"
          />
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full py-3 bg-green-600 hover:bg-green-700 disabled:bg-green-300 text-white font-bold rounded-xl shadow-lg shadow-green-600/10 transition mt-4"
        >
          {submitting ? 'Yuborilmoqda...' : "Arizani jo'natish"}
        </button>
      </form>
    </div>
  );
};

export default CreateProjectForm;
