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
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <p className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase mb-1">Pasport raqami</p>
                <p className="font-semibold text-gray-900 dark:text-slate-100">{detail?.passportNumber || '—'}</p>
              </div>
              <div>
                <p className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase mb-1">JSHSHIR</p>
                <p className="font-semibold text-gray-900 dark:text-slate-100">{detail?.pinfl || '—'}</p>
              </div>
              <div>
                <p className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase mb-1">Tug'ilgan sana</p>
                <p className="font-semibold text-gray-900 dark:text-slate-100">{detail?.birthDate || '—'}</p>
              </div>
            </div>
            <div>
              <p className="text-xs font-bold text-gray-500 dark:text-slate-400 uppercase mb-2">Yuklangan hujjatlar</p>
              <MediaThumbnails urls={detail?.documentUrls || []} emptyLabel="Hujjat yuklanmagan" />
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default KycDocumentModal;
