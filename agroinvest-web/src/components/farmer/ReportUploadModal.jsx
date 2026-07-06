import React, { useState } from 'react';
import { submitReport } from '../../api/reports.api';
import ImageUploadPicker from '../ui/ImageUploadPicker';
import { useToast } from '../ui/ToastProvider';

// Report type values must match the backend ReportType enum (ROUTINE/EMERGENCY/FINAL
// are the farmer-submittable ones; VERIFICATION/COMPLETION are set by staff).
const REPORT_TYPES = [
  { value: 'ROUTINE', label: 'Muntazam (Routine)' },
  { value: 'EMERGENCY', label: 'Favqulodda (Emergency)' },
  { value: 'FINAL', label: 'Yakuniy (Final)' },
];

const ReportUploadModal = ({ projectId, onClose, onSubmitted }) => {
  const [reportType, setReportType] = useState('ROUTINE');
  const [notes, setNotes] = useState('');
  const [mediaUrls, setMediaUrls] = useState([]);
  const [submitting, setSubmitting] = useState(false);
  const [gps, setGps] = useState(null);
  const [gpsError, setGpsError] = useState(null);
  const { showToast } = useToast();

  const captureGps = () => {
    if (!navigator.geolocation) {
      setGpsError('Brauzeringiz GPS aniqlashni qo\'llab-quvvatlamaydi');
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => setGps({ lat: pos.coords.latitude, lng: pos.coords.longitude, accuracy: pos.coords.accuracy }),
      () => setGpsError('GPS aniqlanmadi - joylashuvga ruxsat bering')
    );
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!notes.trim()) {
      showToast("Hisobot izohini yozish shart", 'error');
      return;
    }

    setSubmitting(true);
    try {
      await submitReport(projectId, {
        reportType,
        mediaUrls,
        notes,
        geoLat: gps?.lat,
        geoLng: gps?.lng,
        geoAccuracy: gps?.accuracy,
      });
      showToast('Hisobot muvaffaqiyatli yuklandi!');
      onSubmitted?.();
    } catch (err) {
      showToast(err.error?.message || 'Hisobot yuklashda xatolik yuz berdi', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-6">
      <div className="bg-white rounded-2xl border border-gray-100 shadow-xl max-w-md w-full p-6 space-y-4">
        <div className="flex justify-between items-center">
          <h3 className="font-bold text-gray-900 text-lg">Yangi progress hisoboti</h3>
          <button onClick={onClose} aria-label="Yopish" className="text-gray-400 hover:text-gray-600 text-lg">
            &times;
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Hisobot turi</label>
            <select
              value={reportType}
              onChange={(e) => setReportType(e.target.value)}
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none bg-white focus:ring-1 focus:ring-green-500"
            >
              {REPORT_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Dalil rasmlari</label>
            <ImageUploadPicker category="report" urls={mediaUrls} onChange={setMediaUrls} />
          </div>

          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="block text-xs font-semibold text-gray-600">Geolokatsiya</label>
              <button type="button" onClick={captureGps} className="text-xs font-bold text-green-600 hover:text-green-700">
                GPS aniqlash
              </button>
            </div>
            {gps && <p className="text-xs text-gray-500">Lat: {gps.lat.toFixed(5)}, Lng: {gps.lng.toFixed(5)}</p>}
            {gpsError && <p className="text-xs text-red-600">{gpsError}</p>}
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-600 mb-1.5">Joriy izohlar (Notes)</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Loyiha joriy holati va parvarish jarayoni"
              rows="3"
              className="w-full px-3.5 py-2.5 border rounded-xl text-sm outline-none focus:ring-1 focus:ring-green-500"
              required
            />
          </div>

          <button
            type="submit"
            disabled={submitting}
            className="w-full py-2.5 bg-green-600 hover:bg-green-700 disabled:bg-green-300 text-white font-bold rounded-xl shadow-sm transition"
          >
            {submitting ? 'Yuborilmoqda...' : 'Hisobotni jo\'natish'}
          </button>
        </form>
      </div>
    </div>
  );
};

export default ReportUploadModal;
