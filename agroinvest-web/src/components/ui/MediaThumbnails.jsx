import React, { useState } from 'react';
import MediaGallery from './MediaGallery';

// Inline thumbnail grid that opens MediaGallery on click - used by ReportsTab and
// KycDocumentModal so admins can actually preview evidence photos in-app instead
// of following a raw link out to a new tab.
const MediaThumbnails = ({ urls = [], emptyLabel = "Media yo'q" }) => {
  const [openIndex, setOpenIndex] = useState(null);

  if (!urls.length) {
    return <span className="text-xs text-gray-400 dark:text-slate-500">{emptyLabel}</span>;
  }

  return (
    <>
      <div className="flex gap-2 flex-wrap">
        {urls.map((url, i) => (
          <button
            key={url}
            onClick={() => setOpenIndex(i)}
            className="w-14 h-14 rounded-lg overflow-hidden border border-gray-200 dark:border-slate-600 hover:ring-2 hover:ring-primary-500 transition shrink-0"
          >
            <img src={url} alt={`Rasm ${i + 1}`} className="w-full h-full object-cover" />
          </button>
        ))}
      </div>
      {openIndex !== null && (
        <MediaGallery urls={urls} initialIndex={openIndex} onClose={() => setOpenIndex(null)} />
      )}
    </>
  );
};

export default MediaThumbnails;
