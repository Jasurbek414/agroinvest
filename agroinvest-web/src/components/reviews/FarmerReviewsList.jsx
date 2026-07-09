import React, { useEffect, useState } from 'react';
import { MessageSquareText } from 'lucide-react';
import { getFarmerReviews } from '../../api/reviews.api';
import EmptyState from '../ui/EmptyState';
import StarRating from './StarRating';
import { formatDate } from '../../utils/format';

// Public farmer reputation feed (TZ F-9.2) - previously investors had no way to
// browse a farmer's past reviews anywhere on the web app, only a bare average
// rating number shown inline elsewhere (e.g. ProjectsTab's FarmerBadge).
const FarmerReviewsList = ({ farmerId }) => {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!farmerId) return;
    setLoading(true);
    getFarmerReviews(farmerId)
      .then((res) => setReviews(res.data.content || []))
      .catch(() => setReviews([]))
      .finally(() => setLoading(false));
  }, [farmerId]);

  if (loading) {
    return <p className="text-sm text-gray-400 dark:text-slate-500 animate-pulse">Yuklanmoqda...</p>;
  }

  if (reviews.length === 0) {
    return <EmptyState icon={MessageSquareText} title="Bu fermer uchun hali sharh yo'q" />;
  }

  return (
    <div className="space-y-3">
      {reviews.map((r) => (
        <div key={r.id} className="border border-gray-100 dark:border-slate-700 rounded-2xl p-4">
          <div className="flex items-center justify-between gap-3 mb-1.5">
            <span className="text-xs font-bold text-gray-700 dark:text-slate-300">{r.investorName}</span>
            <StarRating rating={r.rating} />
          </div>
          {r.comment && <p className="text-sm text-gray-600 dark:text-slate-300">{r.comment}</p>}
          <p className="text-[11px] text-gray-400 dark:text-slate-500 mt-1.5">{r.projectTitle} · {formatDate(r.createdAt)}</p>
        </div>
      ))}
    </div>
  );
};

export default FarmerReviewsList;
