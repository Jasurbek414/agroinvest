// Client-side CSV download for user-facing exports (investments, supporters).
// Prepends a UTF-8 BOM so Excel opens O'zbek text (o', g', apostrophes) correctly.
const escapeCell = (value) => {
  const s = value === null || value === undefined ? '' : String(value);
  return /[",\n;]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

export const downloadCsv = (filename, headers, rows) => {
  const lines = [headers, ...rows].map((row) => row.map(escapeCell).join(','));
  const blob = new Blob(['﻿' + lines.join('\n')], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
};
