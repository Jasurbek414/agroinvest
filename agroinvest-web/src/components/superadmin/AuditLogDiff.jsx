import React from 'react';

function parseJson(value) {
  if (!value) return null;
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
}

// Renders an audit log entry's oldValue/newValue as a labeled before/after table
// instead of a raw unformatted JSON <pre> block with no oldValue shown at all.
const AuditLogDiff = ({ oldValue, newValue }) => {
  const oldObj = parseJson(oldValue);
  const newObj = parseJson(newValue);
  if (!oldObj && !newObj) return null;

  const keys = Array.from(new Set([...(oldObj ? Object.keys(oldObj) : []), ...(newObj ? Object.keys(newObj) : [])]));
  if (keys.length === 0) return null;

  return (
    <div className="mt-2 rounded-lg border border-gray-100 dark:border-slate-700 overflow-hidden text-[11px]">
      {keys.map((key) => {
        const before = oldObj?.[key];
        const after = newObj?.[key];
        const changed = before !== undefined && after !== undefined && String(before) !== String(after);
        return (
          <div
            key={key}
            className="grid grid-cols-3 divide-x divide-gray-100 dark:divide-slate-700 border-b border-gray-100 dark:border-slate-700 last:border-0"
          >
            <div className="p-2 font-bold text-gray-500 dark:text-slate-400 bg-gray-50 dark:bg-slate-900/60">{key}</div>
            <div className={`p-2 ${changed ? 'bg-red-50 dark:bg-red-950/40 text-red-700 dark:text-red-300' : 'text-gray-400 dark:text-slate-500'}`}>
              {before !== undefined ? String(before) : '—'}
            </div>
            <div className={`p-2 ${changed ? 'bg-green-50 dark:bg-green-950/40 text-green-700 dark:text-green-300' : 'text-gray-500 dark:text-slate-400'}`}>
              {after !== undefined ? String(after) : '—'}
            </div>
          </div>
        );
      })}
    </div>
  );
};

export default AuditLogDiff;
