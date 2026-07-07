import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

// Consumes the backend's PageResponse shape directly (pageNumber is 0-indexed,
// totalPages from the same payload) - previously every admin list fetched
// page/size but had no UI to ever request a page other than the first.
const Pagination = ({ pageNumber = 0, totalPages = 1, onPageChange }) => {
  if (totalPages <= 1) return null;

  const start = Math.max(0, pageNumber - 2);
  const end = Math.min(totalPages - 1, pageNumber + 2);
  const pages = [];
  for (let i = start; i <= end; i++) pages.push(i);

  return (
    <div className="flex items-center justify-center gap-1.5 pt-4 flex-wrap">
      <button
        onClick={() => onPageChange(pageNumber - 1)}
        disabled={pageNumber === 0}
        aria-label="Oldingi sahifa"
        className="p-2 rounded-lg text-gray-500 dark:text-slate-400 hover:bg-gray-100 dark:hover:bg-slate-800 disabled:opacity-30 disabled:cursor-not-allowed transition"
      >
        <ChevronLeft size={16} />
      </button>

      {start > 0 && (
        <>
          <PageButton page={0} current={pageNumber} onClick={onPageChange} />
          {start > 1 && <span className="px-1 text-gray-400 dark:text-slate-500 text-xs">...</span>}
        </>
      )}

      {pages.map((p) => (
        <PageButton key={p} page={p} current={pageNumber} onClick={onPageChange} />
      ))}

      {end < totalPages - 1 && (
        <>
          {end < totalPages - 2 && <span className="px-1 text-gray-400 dark:text-slate-500 text-xs">...</span>}
          <PageButton page={totalPages - 1} current={pageNumber} onClick={onPageChange} />
        </>
      )}

      <button
        onClick={() => onPageChange(pageNumber + 1)}
        disabled={pageNumber >= totalPages - 1}
        aria-label="Keyingi sahifa"
        className="p-2 rounded-lg text-gray-500 dark:text-slate-400 hover:bg-gray-100 dark:hover:bg-slate-800 disabled:opacity-30 disabled:cursor-not-allowed transition"
      >
        <ChevronRight size={16} />
      </button>
    </div>
  );
};

const PageButton = ({ page, current, onClick }) => (
  <button
    onClick={() => onClick(page)}
    className={`min-w-[32px] h-8 px-2 rounded-lg text-xs font-bold transition ${
      page === current
        ? 'bg-primary-600 text-white'
        : 'text-gray-600 dark:text-slate-300 hover:bg-gray-100 dark:hover:bg-slate-800'
    }`}
  >
    {page + 1}
  </button>
);

export default Pagination;
