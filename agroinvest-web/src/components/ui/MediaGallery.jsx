import React, { useEffect, useState } from 'react';
import { X, ChevronLeft, ChevronRight } from 'lucide-react';

// Full-screen lightbox for a list of image URLs. Previously report/KYC media was
// just a text link opening the raw URL in a new browser tab.
const MediaGallery = ({ urls = [], initialIndex = 0, onClose }) => {
  const [index, setIndex] = useState(initialIndex);

  useEffect(() => {
    const onKeyDown = (e) => {
      if (e.key === 'Escape') onClose();
      if (e.key === 'ArrowLeft') setIndex((i) => (i - 1 + urls.length) % urls.length);
      if (e.key === 'ArrowRight') setIndex((i) => (i + 1) % urls.length);
    };
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [urls.length, onClose]);

  if (!urls.length) return null;

  const go = (delta) => setIndex((i) => (i + delta + urls.length) % urls.length);

  return (
    <div className="fixed inset-0 bg-black/90 z-[200] flex items-center justify-center p-4" onClick={onClose}>
      <button
        onClick={onClose}
        aria-label="Yopish"
        className="absolute top-4 right-4 p-2 rounded-xl bg-white/10 hover:bg-white/20 text-white transition"
      >
        <X size={22} />
      </button>

      {urls.length > 1 && (
        <button
          onClick={(e) => { e.stopPropagation(); go(-1); }}
          aria-label="Oldingi rasm"
          className="absolute left-4 top-1/2 -translate-y-1/2 p-2 rounded-full bg-white/10 hover:bg-white/20 text-white transition"
        >
          <ChevronLeft size={24} />
        </button>
      )}

      <img
        src={urls[index]}
        alt={`Rasm ${index + 1}/${urls.length}`}
        onClick={(e) => e.stopPropagation()}
        className="max-h-[85vh] max-w-full rounded-xl object-contain shadow-2xl"
      />

      {urls.length > 1 && (
        <>
          <button
            onClick={(e) => { e.stopPropagation(); go(1); }}
            aria-label="Keyingi rasm"
            className="absolute right-4 top-1/2 -translate-y-1/2 p-2 rounded-full bg-white/10 hover:bg-white/20 text-white transition"
          >
            <ChevronRight size={24} />
          </button>
          <span className="absolute bottom-4 left-1/2 -translate-x-1/2 text-white/70 text-xs font-bold">
            {index + 1} / {urls.length}
          </span>
        </>
      )}
    </div>
  );
};

export default MediaGallery;
