import React from 'react';
import EmptyState from '../ui/EmptyState';
import { formatAmount, formatDate } from '../../utils/format';

const isCredit = (type) => type === 'DEPOSIT' || type === 'PAYOUT';

const TransactionHistoryList = ({ transactions, loading }) => {
  if (loading) {
    return <p className="p-6 text-gray-500 animate-pulse text-center">Yuklanmoqda...</p>;
  }
  if (!transactions || transactions.length === 0) {
    return <EmptyState title="Hali tranzaksiyalar yozilmagan" />;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-left text-sm">
        <thead>
          <tr className="bg-gray-50 text-gray-500 uppercase text-[10px] tracking-wider font-bold">
            <th className="p-4">Sana</th>
            <th className="p-4">Tur</th>
            <th className="p-4">To'lov tizimi</th>
            <th className="p-4 text-right">Summa</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {transactions.map((t) => (
            <tr key={t.id}>
              <td className="p-4 text-gray-500">{formatDate(t.createdAt)}</td>
              <td className="p-4 font-semibold text-gray-800">
                <span className={`px-2 py-0.5 text-xs rounded-full ${isCredit(t.type) ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
                  {t.type}
                </span>
              </td>
              <td className="p-4 font-bold text-gray-400">{t.paymentProvider || 'INTERNAL'}</td>
              <td className={`p-4 text-right font-extrabold ${isCredit(t.type) ? 'text-green-600' : 'text-red-600'}`}>
                {isCredit(t.type) ? '+' : '-'} {formatAmount(t.amount)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default TransactionHistoryList;
