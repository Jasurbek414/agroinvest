import React, { useEffect, useState } from 'react';
import { Scale } from 'lucide-react';
import { getMyDisputes } from '../../api/disputes.api';
import { useAuthStore } from '../../store/auth.store';
import Card from '../../components/ui/Card';
import ErrorState from '../../components/ui/ErrorState';
import DisputeForm from '../../components/disputes/DisputeForm';
import DisputeList from '../../components/disputes/DisputeList';

const DisputesPage = () => {
  const { user } = useAuthStore();
  const [disputes, setDisputes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchDisputes = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await getMyDisputes();
      setDisputes(res.data.content || []);
    } catch (err) {
      setError('Shikoyatlarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchDisputes(); }, []);

  return (
    <div className="min-h-screen bg-gray-50/50 dark:bg-slate-900 p-6 md:p-12">
      <div className="max-w-3xl mx-auto space-y-8">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-red-50 dark:bg-red-950 flex items-center justify-center text-red-600 dark:text-red-400">
            <Scale size={22} />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-slate-100">Shikoyatlar</h1>
            <p className="text-sm text-gray-500 dark:text-slate-400 mt-0.5">Loyiha bo'yicha muammo yuzaga kelsa, shu yerdan shikoyat oching</p>
          </div>
        </div>

        <Card>
          <h2 className="text-base font-bold text-gray-900 dark:text-slate-100 mb-4">Yangi shikoyat</h2>
          <DisputeForm user={user} onFiled={fetchDisputes} />
        </Card>

        <div>
          <h2 className="text-base font-bold text-gray-900 dark:text-slate-100 mb-4">Mening shikoyatlarim</h2>
          {loading ? (
            <p className="text-sm text-gray-400 dark:text-slate-500 animate-pulse">Yuklanmoqda...</p>
          ) : error ? (
            <ErrorState message={error} onRetry={fetchDisputes} />
          ) : (
            <DisputeList disputes={disputes} />
          )}
        </div>
      </div>
    </div>
  );
};

export default DisputesPage;
