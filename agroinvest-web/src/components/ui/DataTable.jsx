import React, { useState } from 'react';
import { Download } from 'lucide-react';
import EmptyState from './EmptyState';
import ErrorState from './ErrorState';
import SearchBar from './SearchBar';
import Pagination from './Pagination';
import { SkeletonTable } from './Skeleton';

/**
 * Central table component: every admin/superadmin list (KYC, projects, withdrawals,
 * reports, disputes, accounts, audit log) previously hand-rolled its own <table>
 * with no search, filter, pagination, sort, or mobile card-view - each one now
 * gets all of that by rendering through this component instead.
 *
 * columns: [{ key, header, render?(row), align?, className? }]
 * page: { pageNumber, totalPages, onPageChange } - omit to hide pagination
 * renderMobileCard(row): node - card layout shown below md; omit to fall back
 *   to a horizontally-scrollable table on mobile too.
 * selectable + bulkActions: [{ label, tone?, onClick(selectedRows) }]
 * onExport(): void - shows an "Eksport" toolbar button when provided; callers
 *   build the CSV themselves via utils/exportCsv.js (exports the current page
 *   of `rows`, not the full server-side dataset).
 */
const DataTable = ({
  columns,
  rows,
  loading,
  error,
  onRetry,
  emptyTitle = 'Ma\'lumot topilmadi',
  emptySubtitle,
  emptyIcon,
  searchable,
  search,
  onSearchChange,
  searchPlaceholder,
  filters,
  page,
  rowKey = (row) => row.id,
  renderMobileCard,
  selectable,
  bulkActions,
  onExport,
}) => {
  const [selected, setSelected] = useState([]);

  const toggleRow = (id) => {
    setSelected((prev) => (prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]));
  };
  const toggleAll = () => {
    setSelected((prev) => (prev.length === rows.length ? [] : rows.map(rowKey)));
  };
  const selectedRows = rows.filter((r) => selected.includes(rowKey(r)));

  const hasToolbar = searchable || filters || onExport;

  return (
    <div>
      {hasToolbar && (
        <div className="p-4 sm:p-6 border-b border-gray-100 dark:border-slate-700 flex flex-col sm:flex-row gap-3 sm:items-center sm:justify-between">
          {searchable && (
            <SearchBar value={search} onChange={onSearchChange} placeholder={searchPlaceholder} className="sm:max-w-xs" />
          )}
          <div className="flex items-center gap-2 flex-wrap sm:ml-auto">
            {filters && <div className="flex flex-wrap gap-2">{filters}</div>}
            {onExport && (
              <button
                onClick={onExport}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold border border-gray-200 dark:border-slate-600 text-gray-600 dark:text-slate-300 hover:border-primary-400 hover:text-primary-600 transition"
              >
                <Download size={14} /> Eksport
              </button>
            )}
          </div>
        </div>
      )}

      {selectable && selectedRows.length > 0 && bulkActions?.length > 0 && (
        <div className="px-4 sm:px-6 py-2.5 bg-primary-50 dark:bg-primary-950 border-b border-primary-100 dark:border-primary-900 flex items-center justify-between gap-3 flex-wrap">
          <span className="text-xs font-bold text-primary-700 dark:text-primary-300">{selectedRows.length} ta tanlandi</span>
          <div className="flex gap-2">
            {bulkActions.map((action) => (
              <button
                key={action.label}
                onClick={() => { action.onClick(selectedRows); setSelected([]); }}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                  action.tone === 'danger'
                    ? 'bg-red-100 text-red-700 hover:bg-red-200 dark:bg-red-900 dark:text-red-200'
                    : 'bg-primary-600 text-white hover:bg-primary-700'
                }`}
              >
                {action.label}
              </button>
            ))}
          </div>
        </div>
      )}

      {loading ? (
        <SkeletonTable rows={5} cols={columns.length} />
      ) : error ? (
        <ErrorState message={error} onRetry={onRetry} />
      ) : rows.length === 0 ? (
        <EmptyState icon={emptyIcon} title={emptyTitle} subtitle={emptySubtitle} />
      ) : (
        <>
          {/* Desktop/tablet: real table */}
          <div className={`${renderMobileCard ? 'hidden md:block' : ''} overflow-x-auto text-sm text-left`}>
            <table className="w-full">
              <thead>
                <tr className="bg-gray-50 dark:bg-slate-900/60 text-gray-500 dark:text-slate-400 uppercase text-[10px] font-bold">
                  {selectable && (
                    <th className="p-4 w-10">
                      <input
                        type="checkbox"
                        checked={selected.length === rows.length && rows.length > 0}
                        onChange={toggleAll}
                        className="rounded border-gray-300 dark:border-slate-600"
                      />
                    </th>
                  )}
                  {columns.map((col) => (
                    <th key={col.key} className={`p-4 ${col.align === 'right' ? 'text-right' : ''}`}>
                      {col.header}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-slate-700">
                {rows.map((row) => (
                  <tr key={rowKey(row)} className="hover:bg-gray-50/50 dark:hover:bg-slate-800/50 text-gray-800 dark:text-slate-200">
                    {selectable && (
                      <td className="p-4">
                        <input
                          type="checkbox"
                          checked={selected.includes(rowKey(row))}
                          onChange={() => toggleRow(rowKey(row))}
                          className="rounded border-gray-300 dark:border-slate-600"
                        />
                      </td>
                    )}
                    {columns.map((col) => (
                      <td key={col.key} className={`p-4 ${col.align === 'right' ? 'text-right' : ''} ${col.className || ''}`}>
                        {col.render ? col.render(row) : row[col.key]}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Mobile: card list, avoids the cramped horizontal-scroll table experience */}
          {renderMobileCard && (
            <div className="md:hidden divide-y divide-gray-100 dark:divide-slate-700">
              {rows.map((row) => (
                <div key={rowKey(row)} className="p-4">
                  {renderMobileCard(row)}
                </div>
              ))}
            </div>
          )}
        </>
      )}

      {page && !loading && !error && rows.length > 0 && (
        <div className="px-4 sm:px-6 pb-4">
          <Pagination pageNumber={page.pageNumber} totalPages={page.totalPages} onPageChange={page.onPageChange} />
        </div>
      )}
    </div>
  );
};

export default DataTable;
