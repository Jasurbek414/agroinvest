import api from './axios';

export const submitExpense = (projectId, expenseData) => {
  return api.post(`/expenses/project/${projectId}`, expenseData);
};

export const getProjectExpenses = (projectId) => {
  return api.get(`/expenses/project/${projectId}`);
};

export const getPendingExpenses = (page = 0, size = 12) => {
  return api.get('/expenses/pending', { params: { page, size } });
};

export const reviewExpense = (id, approve, comment) => {
  return api.patch(`/expenses/${id}/review`, { approve, comment });
};
