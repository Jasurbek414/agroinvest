import React from 'react';
import { Star } from 'lucide-react';

// Read-only star display (0-5). Shared by FarmerReviewsList and anywhere else
// a rating needs to render the same way instead of each screen reinventing it.
const StarRating = ({ rating = 0, size = 14 }) => (
  <div className="flex items-center gap-0.5">
    {[1, 2, 3, 4, 5].map((n) => (
      <Star
        key={n}
        size={size}
        className={n <= Math.round(rating) ? 'text-amber-500 fill-amber-500' : 'text-gray-200 dark:text-slate-600 fill-gray-200 dark:fill-slate-600'}
      />
    ))}
  </div>
);

export default StarRating;
