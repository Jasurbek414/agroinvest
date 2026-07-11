import React from 'react';
import { Star } from 'lucide-react';
import { useAuthStore } from '../../store/auth.store';
import FarmerReviewsList from '../reviews/FarmerReviewsList';

// The farmer's own reputation feed - the same public reviews investors see on
// FarmerProfileModal, surfaced in the cabinet so the farmer can track feedback.
const ReviewsTab = () => {
  const { user } = useAuthStore();

  return (
    <div className="bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/50 dark:border-slate-800/80 shadow-sm space-y-6 animate-in fade-in duration-300">
      <div className="flex items-center gap-2">
        <Star size={16} className="text-amber-500 fill-current" />
        <div>
          <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base">Reyting va sharhlar</h3>
          <p className="text-xs text-gray-450 dark:text-slate-500 mt-0.5">Investorlar yakunlangan loyihalaringiz bo'yicha qoldirgan fikrlari</p>
        </div>
      </div>

      <FarmerReviewsList farmerId={user?.id} />
    </div>
  );
};

export default ReviewsTab;
