import React, { useState } from 'react';
import { UploadCloud, CheckCircle2 } from 'lucide-react';
import { uploadFile } from '../../api/uploads.api';
import { submitKyc } from '../../api/users.api';
import { useToast } from '../ui/ToastProvider';

const KycForm = ({ onSubmitted }) => {
  const [passportNumber, setPassportNumber] = useState('');
  const [pinfl, setPinfl] = useState('');
  const [birthDate, setBirthDate] = useState('');
  const [documentUrls, setDocumentUrls] = useState([]);
  const [uploading, setUploading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const { showToast } = useToast();

  const handleFileChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    try {
      const res = await uploadFile(file, 'kyc');
      setDocumentUrls((prev) => [...prev, res.data.url]);
      showToast('Hujjat yuklandi');
    } catch (err) {
      showToast(err.error?.message || 'Faylni yuklashda xatolik yuz berdi', 'error');
    } finally {
      setUploading(false);
      e.target.value = '';
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!passportNumber.trim() || !pinfl.trim()) {
      showToast("Pasport raqami va JSHSHIR to'ldirilishi shart", 'error');
      return;
    }
    if (documentUrls.length === 0) {
      showToast('Kamida bitta hujjat rasmi yuklang', 'error');
      return;
    }
    setSubmitting(true);
    try {
      await submitKyc({ passportNumber: passportNumber.trim(), pinfl: pinfl.trim(), birthDate, documentUrls });
      showToast('Hujjatlaringiz tekshiruvga yuborildi');
      onSubmitted?.();
    } catch (err) {
      showToast(err.error?.message || 'Yuborishda xatolik yuz berdi', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Pasport seriya va raqami</label>
          <input
            type="text"
            value={passportNumber}
            onChange={(e) => setPassportNumber(e.target.value)}
            placeholder="AB1234567"
            className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
            required
          />
        </div>
        <div>
          <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">JSHSHIR (PINFL)</label>
          <input
            type="text"
            value={pinfl}
            onChange={(e) => setPinfl(e.target.value)}
            placeholder="12345678901234"
            className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
            required
          />
        </div>
      </div>

      <div>
        <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Tug'ilgan sana</label>
        <input
          type="date"
          value={birthDate}
          onChange={(e) => setBirthDate(e.target.value)}
          className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
        />
      </div>

      <div>
        <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Pasport rasmi</label>
        <label className="flex items-center justify-center gap-2 border-2 border-dashed border-gray-200 dark:border-slate-600 rounded-xl py-6 cursor-pointer hover:border-primary-400 transition text-sm text-gray-500 dark:text-slate-400">
          <UploadCloud size={18} />
          {uploading ? 'Yuklanmoqda...' : 'Rasm tanlash uchun bosing'}
          <input type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={handleFileChange} disabled={uploading} />
        </label>
        {documentUrls.length > 0 && (
          <ul className="mt-2 space-y-1">
            {documentUrls.map((url) => (
              <li key={url} className="flex items-center gap-2 text-xs text-primary-700 dark:text-primary-400">
                <CheckCircle2 size={14} /> Hujjat yuklandi
              </li>
            ))}
          </ul>
        )}
      </div>

      <button
        type="submit"
        disabled={submitting || uploading}
        className="w-full py-3 bg-primary-600 hover:bg-primary-700 disabled:bg-primary-300 text-white font-bold rounded-xl shadow-sm transition"
      >
        {submitting ? 'Yuborilmoqda...' : 'Tasdiqlashga yuborish'}
      </button>
    </form>
  );
};

export default KycForm;
