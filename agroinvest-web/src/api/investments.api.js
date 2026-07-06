import api from './axios';

export const createInvestment = (projectId, amount, idempotencyKey) => {
  return api.post('/investments', {
    projectId,
    amount,
    idempotencyKey: idempotencyKey || Math.random().toString(36).substring(7),
  });
};

export const cancelInvestment = (id) => {
  return api.post(`/investments/${id}/cancel`);
};

export const getMyInvestments = (page = 0, size = 12) => {
  return api.get('/investments/my', { params: { page, size } });
};

export const getProjectInvestments = (projectId) => {
  return api.get(`/investments/project/${projectId}`);
};
