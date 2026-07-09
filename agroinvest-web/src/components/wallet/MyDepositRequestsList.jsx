import React, { useEffect, useState } from 'react';
import { getMyDepositRequests } from '../../api/wallet.api';
import { formatAmount, formatDate } from '../../utils/format';
import Badge from '../ui/Badge';
import { SkeletonTable } from '../ui/Skeleton';

const MyDepositRequestsList = ({ refreshKey }) => {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    getMyDepositRequests()
      .then((res) => setRequests(res.data.content || []))
      .finally(() => setLoading(false));
  }, [refreshKey]);

  if (loading) return <SkeletonTable rows={3} cols={3} />;
  if (requests.length === 0) return <p className="text-sm text-gray-400 text-center py-6">Hali to'ldirish so'rovi yo'q</p>;

  return (
    <div className="divide-y divide-gray-100 dark:divide-slate-700">
      {requests.map((r) => (
        <div key={r.id} className="py-3 flex items-center justify-between gap-3">
          <div>
            <p className="font-bold text-sm text-gray-900 dark:text-slate-100">{formatAmount(r.amount)}</p>
            <p className="text-xs text-gray-400">{formatDate(r.createdAt)}</p>
            {r.adminComment && <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">{r.adminComment}</p>}
          </div>
          <Badge status={r.status} />
        </div>
      ))}
    </div>
  );
};

export default MyDepositRequestsList;
