// Generic CSV export used by admin DataTable instances. columns: [{ header, value(row) }]
// - a plain-text accessor, deliberately separate from DataTable's JSX `render`.
function escapeCsvField(value) {
  const str = value === null || value === undefined ? '' : String(value);
  if (/[",\n]/.test(str)) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

export function exportToCsv(rows, columns, filename) {
  const header = columns.map((c) => escapeCsvField(c.header)).join(',');
  const lines = rows.map((row) => columns.map((c) => escapeCsvField(c.value(row))).join(','));
  const csv = [header, ...lines].join('\r\n');

  // BOM so Excel (still common for UZ back-office staff) renders Cyrillic/Uzbek
  // diacritics correctly instead of mangling them as another codepage.
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
