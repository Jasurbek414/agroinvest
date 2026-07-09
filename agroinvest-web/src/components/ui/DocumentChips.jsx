import React from 'react';
import { FileText } from 'lucide-react';

// Same "click a thumbnail to view" idea as MediaThumbnails, but these documents
// may be PDFs (FileStorageService accepts them for receipts/vet docs/deposit
// proofs) which <img> can't render - so PDFs get a labeled link chip instead of
// a broken thumbnail. Shared by ExpensesTab, VetInspectionsTab, DepositRequestsTab.
const DocumentChips = ({ urls = [], emptyLabel = "Hujjat yo'q", altPrefix = 'Hujjat' }) => {
  if (!urls.length) return <span className="text-xs text-gray-400 dark:text-slate-500">{emptyLabel}</span>;
  return (
    <div className="flex gap-2 flex-wrap">
      {urls.map((url, i) =>
        url.toLowerCase().endsWith('.pdf') ? (
          <a
            key={url}
            href={url}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-1 px-2 py-1 rounded-lg border border-gray-200 dark:border-slate-600 text-[10px] font-bold text-gray-600 dark:text-slate-300 hover:border-primary-400"
          >
            <FileText size={12} /> PDF {i + 1}
          </a>
        ) : (
          <a key={url} href={url} target="_blank" rel="noreferrer" className="w-14 h-14 rounded-lg overflow-hidden border border-gray-200 dark:border-slate-600 shrink-0">
            <img src={url} alt={`${altPrefix} ${i + 1}`} className="w-full h-full object-cover" />
          </a>
        )
      )}
    </div>
  );
};

export default DocumentChips;
