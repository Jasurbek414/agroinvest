import React, { useEffect, useState } from 'react';
import { getWithdrawalRequests, approveWithdrawal } from '../../../api/admin.api';
import { formatAmount } from '../../../utils/format';
import Badge from '../../ui/Badge';
import EmptyState from '../../ui/EmptyState';
import ErrorState from '../../ui/ErrorState';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';

const WithdrawalsTab = ({ onActionDone }) => {
  const [withdrawals, setWithdrawals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const { showToast } = useToast();

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await getWithdrawalRequests();
      setWithdrawals(res.data.content || []);
    } catch (err) {
      setError("Yechish so'rovlarini yuklashda xatolik yuz berdi");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);

  const runAction = async (id, approve, comment) => {
    try {
      await approveWithdrawal(id, approve, comment);
      showToast(approve ? "Yechish so'rovi tasdiqlandi" : "Yechish so'rovi rad etildi");
      fetchData();
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  if (loading) return <p className="p-8 text-center text-sm text-gray-400 animate-pulse">Yuklanmoqda...</p>;
  if (error) return <ErrorState message={error} onRetry={fetchData} />;

  return (
    <div>
      <div className="p-6 border-b border-gray-100">
        <h2 className="text-base font-bold text-gray-900">Pul yechib olish so'rovlari</h2>
      </div>
      {withdrawals.length === 0 ? (
        <EmptyState title="Yechib olish so'rovlari yo'q" />
      ) : (
        <div className="overflow-x-auto text-sm text-left">
          <table className="w-full">
            <thead>
              <tr className="bg-gray-50 text-gray-500 uppercase text-[10px] font-bold">
                <th className="p-4">Foydalanuvchi</th>
                <th className="p-4">Karta</th>
                <th className="p-4">Summa</th>
                <th className="p-4">Holat</th>
                <th className="p-4 text-right">Amallar</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {withdrawals.map((w) => (
                <tr key={w.id} className="hover:bg-gray-50/50">
                  <td className="p-4 font-semibold">{w.userName}</td>
                  <td className="p-4 text-xs font-mono text-gray-400">{w.bankName} - {w.cardNumber}</td>
                  <td className="p-4 font-bold">{formatAmount(w.amount)}</td>
                  <td className="p-4"><Badge status={w.status} /></td>
                  <td className="p-4 text-right">
                    {w.status === 'PENDING' && (
                      <div className="flex justify-end gap-2">
                        <button onClick={() => setRejectTarget(w.id)} className="px-2 py-1 bg-red-50 text-red-700 rounded-lg text-xs font-bold">Rad etish</button>
                        <button onClick={() => runAction(w.id, true, null)} className="px-2 py-1 bg-green-50 text-green-700 rounded-lg text-xs font-bold">Tasdiqlash</button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <PromptDialog
        open={!!rejectTarget}
        title="Yechish so'rovini rad etish"
        label="Rad etish sababi"
        required
        tone="danger"
        confirmLabel="Rad etish"
        onCancel={() => setRejectTarget(null)}
        onConfirm={(reason) => { runAction(rejectTarget, false, reason); setRejectTarget(null); }}
      />
    </div>
  );
};

export default WithdrawalsTab;
