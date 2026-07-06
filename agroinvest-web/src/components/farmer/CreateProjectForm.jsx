import React, { useState } from 'react';
import { createProject } from '../../api/projects.api';
import ImageUploadPicker from '../ui/ImageUploadPicker';
import { useToast } from '../ui/ToastProvider';

const ASSET_TYPES = [
  { value: 'LIVESTOCK', label: 'Chorvachilik' },
  { value: 'CROP', label: 'Dehqonchilik' },
  { value: 'GREENHOUSE', label: 'Issiqxona' },
  { value: 'POULTRY', label: 'Parrandachilik' },
  { value: 'BEEKEEPING', label: 'Asalarchilik' },
  { value: 'OTHER', label: 'Boshqa' },
];

const CreateProjectForm = ({ onCreated }) => {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [assetType, setAssetType] = useState('LIVESTOCK');
  const [region, setRegion] = useState('Qashqadaryo');
  const [targetAmount, setTargetAmount] = useState('');
  const [expectedReturnPct, setExpectedReturnPct] = useState('20');
  const [durationDays, setDurationDays] = useState('90');
  const [riskLevel, setRiskLevel] = useState('MEDIUM');
  const [mediaUrls, setMediaUrls] = useState([]);
  const [submitting, setSubmitting] = useState(false);
  const { showToast } = useToast();

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!title || !description || !targetAmount) {
      showToast("Iltimos, barcha majburiy maydonlarni to'ldiring", 'error');
      return;
    }

    setSubmitting(true);
    try {
      await createProject({
        title,
        description,
        assetType,
        region,
        targetAmount: parseFloat(targetAmount),
        expectedReturnPct: parseFloat(expectedReturnPct),
        durationDays: parseInt(durationDays),
        riskLevel,
        mediaUrls,
      });
      showToast('Loyiha arizasi muvaffaqiyatli topshirildi va tekshirilmoqda!');
      setTitle('');
      setDescription('');
      setTargetAmount('');
      setMediaUrls([]);
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
              onChange={(e) => setAssetType(e.target.value)}
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none bg-white focus:ring-1 focus:ring-green-500"
            >
              {ASSET_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>
          </div>
        </div>

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
