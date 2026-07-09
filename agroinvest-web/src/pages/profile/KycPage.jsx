import React, { useEffect, useState } from 'react';
import { ShieldCheck } from 'lucide-react';
import { getMe } from '../../api/users.api';
import Card from '../../components/ui/Card';
import Badge from '../../components/ui/Badge';
import KycForm from '../../components/kyc/KycForm';

const KycPage = () => {
  const [me, setMe] = useState(null);
  const [loading, setLoading] = useState(true);

  const fetchMe = async () => {
    setLoading(true);
    try {
      const res = await getMe();
      setMe(res.data);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchMe(); }, []);

  if (loading) {
    return <p className="p-12 text-center text-gray-400 dark:text-slate-500 animate-pulse">Yuklanmoqda...</p>;
  }

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-slate-900 p-6 md:p-12">
      <div className="max-w-2xl mx-auto space-y-8">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-primary-50 dark:bg-primary-950 flex items-center justify-center text-primary-600 dark:text-primary-400">
            <ShieldCheck size={22} />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-slate-100">Shaxsni tasdiqlash (KYC)</h1>
            <p className="text-sm text-gray-500 dark:text-slate-400 mt-0.5">Loyiha yaratish yoki sarmoya kiritish uchun hisobingiz tasdiqlangan bo'lishi kerak</p>
          </div>
        </div>

        <Card className="flex items-center justify-between">
          <span className="text-sm font-semibold text-gray-600 dark:text-slate-300">Joriy holat</span>
          <Badge status={me?.kycStatus} />
        </Card>

        {me?.kycStatus === 'VERIFIED' ? (
          <Card className="text-center py-10">
            <p className="text-primary-700 dark:text-primary-400 font-bold">Hisobingiz allaqachon tasdiqlangan!</p>
          </Card>
        ) : (
          <Card>
            {me?.kycStatus === 'REJECTED' && me?.kycRejectedReason && (
              <div className="mb-4 p-3 bg-red-50 dark:bg-red-950 border border-red-100 dark:border-red-900 rounded-xl text-sm text-red-700 dark:text-red-300">
                <span className="font-bold">Rad etilish sababi: </span>{me.kycRejectedReason}
              </div>
            )}
            {me?.kycStatus === 'PENDING' && me?.kycRejectedReason === undefined && (
              <p className="text-xs text-gray-400 dark:text-slate-500 mb-4">Hujjatlaringiz allaqachon topshirilgan bo'lsa, tekshiruv natijasini shu yerda ko'rasiz.</p>
            )}
            <KycForm onSubmitted={fetchMe} />
          </Card>
        )}
      </div>
    </div>
  );
};

export default KycPage;
