import api from './axios';

export const fileDispute = (projectId, againstUserId, disputeType, description) => {
  return api.post('/disputes', { projectId, againstUserId, disputeType, description });
};

export const getMyDisputes = (page = 0, size = 10) => {
  return api.get('/disputes/my', { params: { page, size } });
};

export const getAllDisputes = (page = 0, size = 10) => {
  return api.get('/disputes', { params: { page, size } });
};

export const resolveDispute = (id, resolution) => {
  return api.patch(`/disputes/${id}`, null, { params: { resolution } });
};
