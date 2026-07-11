// Single source of truth for ExpenseCategory labels - used by the farmer's
// expense form (select options) and the finance tab (history rows).
export const EXPENSE_CATEGORIES = [
  { value: 'FEED', label: 'Yem-xashak' },
  { value: 'MEDICINE', label: 'Dori-darmon' },
  { value: 'VET_SERVICE', label: 'Veterinar xizmati' },
  { value: 'TRANSPORT', label: 'Transport' },
  { value: 'LABOR', label: 'Ish haqi' },
  { value: 'EQUIPMENT', label: 'Jihozlar' },
  { value: 'OTHER', label: 'Boshqa' },
];

export const getExpenseCategoryLabel = (value) =>
  EXPENSE_CATEGORIES.find((c) => c.value === value)?.label || value;
