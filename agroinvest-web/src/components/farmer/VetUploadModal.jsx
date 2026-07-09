import React, { useState } from 'react';
import { submitVetInspection } from '../../api/vet.api';
import ImageUploadPicker from '../ui/ImageUploadPicker';
import { useToast } from '../ui/ToastProvider';

const HEALTH_STATUSES = [
  { value: 'HEALTHY', label: "Sog'lom" },
  { value: 'TREATED', label: 'Davolangan' },
  { value: 'QUARANTINE', label: 'Karantinda' },
  { value: 'SICK', label: 'Kasal' },
];

// Farmer uploads the vet's conclusion after a check-up (PDF/photo); staff
// verifies it before it shows publicly as a trust signal on the project page.
const VetUploadModal = ({ projectId, onClose, onSubmitted }) => {
  const [vetName, setVetName] = useState('');
  const [vetLicenseNo, setVetLicenseNo] = useState('');
  const [inspectionDate, setInspectionDate] = useState(new Date().toISOString().slice(0, 10));
  const [healthStatus, setHealthStatus] = useState('HEALTHY');
  const [conclusion, setConclusion] = useState('');
  const [documentUrls, setDocumentUrls] = useState([]);
  const [submitting, setSubmitting] = useState(false);
  const { showToast } = useToast();

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!vetName.trim()) {
      showToast("Veterinar ismini kiriting", 'error');
      return;
    }
    if (documentUrls.length === 0) {
      showToast("Kamida bitta hujjat (PDF/foto) yuklang", 'error');
      return;
    }

    setSubmitting(true);
    try {
      await submitVetInspection(projectId, {
        vetName,
        vetLicenseNo: vetLicenseNo || undefined,
        inspectionDate,
        documentUrls,
        conclusion,
        healthStatus,
      });
      showToast('Hujjat yuborildi - admin tekshiradi');
      onSubmitted?.();
    } catch (err) {
      showToast(err.error?.message || 'Hujjat yuborishda xatolik yuz berdi', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-6">
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-xl max-w-md w-full p-6 space-y-4 max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center">
          <h3 className="font-bold text-gray-900 dark:text-slate-100 text-lg">Veterinar hujjati</h3>
          <button onClick={onClose} aria-label="Yopish" className="text-gray-400 hover:text-gray-600 dark:text-slate-500 dark:hover:text-slate-300 text-lg">&times;</button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Veterinar F.I.SH</label>
            <input
              type="text"
              value={vetName}
              onChange={(e) => setVetName(e.target.value)}
              placeholder="Aliyev Vali G'aniyevich"
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Litsenziya raqami</label>
              <input
                type="text"
                value={vetLicenseNo}
                onChange={(e) => setVetLicenseNo(e.target.value)}
                placeholder="VET-12345"
                className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Ko'rik sanasi</label>
              <input
                type="date"
                value={inspectionDate}
                onChange={(e) => setInspectionDate(e.target.value)}
                max={new Date().toISOString().slice(0, 10)}
                className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Hayvonlar holati</label>
            <select
              value={healthStatus}
              onChange={(e) => setHealthStatus(e.target.value)}
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 rounded-xl text-sm outline-none bg-white dark:bg-slate-900 dark:text-slate-100 focus:ring-1 focus:ring-primary-500"
            >
              {HEALTH_STATUSES.map((h) => <option key={h.value} value={h.value}>{h.label}</option>)}
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Xulosa (ixtiyoriy)</label>
            <textarea
              value={conclusion}
              onChange={(e) => setConclusion(e.target.value)}
              placeholder="Veterinar xulosasining qisqacha mazmuni"
              rows="2"
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Hujjatlar (PDF yoki foto)</label>
            <ImageUploadPicker
              category="vet"
              urls={documentUrls}
              onChange={setDocumentUrls}
              accept="image/jpeg,image/png,image/webp,application/pdf"
            />
          </div>

          <button
            type="submit"
            disabled={submitting}
            className="w-full py-2.5 bg-primary-600 hover:bg-primary-700 disabled:bg-primary-300 text-white font-bold rounded-xl shadow-sm transition"
          >
            {submitting ? 'Yuborilmoqda...' : 'Yuborish'}
          </button>
        </form>
      </div>
    </div>
  );
};

export default VetUploadModal;
