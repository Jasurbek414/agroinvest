import React, { useEffect, useState } from 'react';
import { X } from 'lucide-react';
import { getKycDetail } from '../../api/users.api';
import MediaThumbnails from '../ui/MediaThumbnails';
import { SkeletonCard } from '../ui/Skeleton';
import ErrorState from '../ui/ErrorState';

// Previously KycTab had no way to view the passport/selfie the user actually
// uploaded - admins were asked to approve/reject KYC blind. This fetches and
// displays the decrypted passport number/PINFL plus the uploaded documents.
const KycDocumentModal = ({ user, onClose }) => {
  const [detail, setDetail] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!user) return;
    let cancelled = false;
    setLoading(true);
    setError(null);
    getKycDetail(user.id)
      .then((res) => { if (!cancelled) setDetail(res.data); })
      .catch(() => { if (!cancelled) setError("KYC ma'lumotlarini yuklashda xatolik yuz berdi"); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [user]);

  if (!user) return null;

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-6">
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-xl max-w-lg w-full p-6 space-y-4 max-h-[85vh] overflow-y-auto">
        <div className="flex items-start justify-between">
          <div className="min-w-0">
            <h3 className="font-bold text-gray-900 dark:text-slate-100 text-lg truncate">{user.fullName}</h3>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-mono">{user.phoneNumber}</p>
          </div>
          <button
            onClick={onClose}
            aria-label="Yopish"
            className="p-2 -mt-1 -mr-1 rounded-xl hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-500 dark:text-slate-400 shrink-0"
          >
            <X size={18} />
          </button>
        </div>

        {loading ? (
          <SkeletonCard />
        ) : error ? (
          <ErrorState message={error} />
        ) : (
          <div className="space-y-5 text-sm">
            {/* Selfie and Passport Photos */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase mb-2">Selfie (Rasm)</p>
                {detail?.selfieUrl ? (
                  <a href={detail.selfieUrl} target="_blank" rel="noreferrer">
                    <img src={detail.selfieUrl} alt="Selfie" className="w-full h-32 object-cover rounded-xl border border-gray-200 dark:border-slate-700 hover:opacity-90 transition" />
                  </a>
                ) : (
                  <p className="text-gray-400 text-xs italic">Yuklanmagan</p>
                )}
              </div>
              <div>
                <p className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase mb-2">Pasport Rasmi</p>
                {detail?.passportPhotoUrl ? (
                  <a href={detail.passportPhotoUrl} target="_blank" rel="noreferrer">
                    <img src={detail.passportPhotoUrl} alt="Pasport" className="w-full h-32 object-cover rounded-xl border border-gray-200 dark:border-slate-700 hover:opacity-90 transition" />
                  </a>
                ) : (
                  <p className="text-gray-400 text-xs italic">Yuklanmagan</p>
                )}
              </div>
            </div>

            {/* Passport Data */}
            <div className="bg-gray-50 dark:bg-slate-900/50 p-4 rounded-xl space-y-3">
              <h4 className="text-xs font-bold text-primary-600 uppercase tracking-wider">Pasport ma'lumotlari</h4>
              <div className="grid grid-cols-2 gap-x-4 gap-y-2">
                <div>
                  <p className="text-[10px] font-bold text-gray-400 uppercase">Pasport raqami</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100">{detail?.passportNumber || '—'}</p>
                </div>
                <div>
                  <p className="text-[10px] font-bold text-gray-400 uppercase">JSHSHIR</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100">{detail?.pinfl || '—'}</p>
                </div>
                <div>
                  <p className="text-[10px] font-bold text-gray-400 uppercase">Tug'ilgan sana</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100">{detail?.birthDate || '—'}</p>
                </div>
                <div>
                  <p className="text-[10px] font-bold text-gray-400 uppercase">Otasing ismi/familiyasi</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100">{detail?.fatherName || '—'}</p>
                </div>
              </div>
            </div>

            {/* Address Info */}
            <div className="bg-gray-50 dark:bg-slate-900/50 p-4 rounded-xl space-y-3">
              <h4 className="text-xs font-bold text-primary-600 uppercase tracking-wider">Manzillar & Kontakt</h4>
              <div className="space-y-2">
                <div>
                  <p className="text-[10px] font-bold text-gray-400 uppercase">Ro'yxatdan o'tgan manzil</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 text-xs">{detail?.registrationAddress || '—'}</p>
                </div>
                <div>
                  <p className="text-[10px] font-bold text-gray-400 uppercase">Hozirgi yashash manzili</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 text-xs">{detail?.currentAddress || '—'}</p>
                </div>
                <div>
                  <p className="text-[10px] font-bold text-gray-400 uppercase">Qo'shimcha telefon raqami</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100">{detail?.additionalPhone || '—'}</p>
                </div>
              </div>
            </div>

            {/* Work & Education */}
            <div className="bg-gray-50 dark:bg-slate-900/50 p-4 rounded-xl space-y-3">
              <h4 className="text-xs font-bold text-primary-600 uppercase tracking-wider">Faoliyat & Ma'lumot</h4>
              <div className="space-y-2">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-[10px] font-bold text-gray-400 uppercase">Hozirgi kasbi/ish turi</p>
                    <p className="font-semibold text-gray-900 dark:text-slate-100">{detail?.occupation || '—'}</p>
                  </div>
                  <div>
                    <p className="text-[10px] font-bold text-gray-400 uppercase">Ma'lumoti</p>
                    <p className="font-semibold text-gray-900 dark:text-slate-100">{detail?.education || '—'}</p>
                  </div>
                </div>
                <div>
                  <p className="text-[10px] font-bold text-gray-400 uppercase">Ish tajribasi</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 text-xs whitespace-pre-line">{detail?.workExperience || '—'}</p>
                </div>
              </div>
            </div>

            {/* Additional Documents */}
            <div>
              <p className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase mb-2">Qo'shimcha yuklangan hujjatlar</p>
              <MediaThumbnails urls={detail?.documentUrls || []} emptyLabel="Hujjat yuklanmagan" />
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default KycDocumentModal;
