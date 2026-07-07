export const formatAmount = (num) => {
  if (num === null || num === undefined) return '0 UZS';
  return new Intl.NumberFormat('uz-UZ').format(num) + ' UZS';
};

export const formatDate = (isoString) => {
  if (!isoString) return '-';
  return new Date(isoString).toLocaleString('uz-UZ');
};
