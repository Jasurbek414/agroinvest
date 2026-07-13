import api from './axios';

export const createAdminAccount = (phone, name, password, role) => {
  const params = { phone, name, password, role };
  return api.post('/superadmin/accounts', {}, { params });
};

export const getAccounts = (page = 0, size = 20, { role, blocked, q, sort = 'createdAt,desc' } = {}) => {
  const params = { page, size };
  if (role) params.role = role;
  if (blocked !== undefined) params.blocked = blocked;
  if (q) params.q = q;
  if (sort) params.sort = sort;
  return api.get('/superadmin/accounts', { params });
};

export const blockAccount = (id, block, reason) => {
  const params = { block };
  if (reason) params.reason = reason;
  return api.patch(`/superadmin/accounts/${id}/block`, {}, { params });
};

export const resetStaffPassword = (id, newPassword) => {
  return api.patch(`/superadmin/accounts/${id}/password`, {}, { params: { newPassword } });
};

export const changeStaffRole = (id, role) => {
  return api.patch(`/superadmin/accounts/${id}/role`, {}, { params: { role } });
};

export const getPlatformOverview = () => api.get('/superadmin/overview');

export const broadcastNotification = ({ title, message, role, channel }) => {
  const params = { title, message };
  if (role) params.role = role;
  if (channel) params.channel = channel;
  return api.post('/superadmin/broadcast', {}, { params });
};

export const getPlatformTransactions = (page = 0, size = 20, { type, status, from, to } = {}) => {
  const params = { page, size, sort: 'createdAt,desc' };
  if (type) params.type = type;
  if (status) params.status = status;
  if (from) params.from = from;
  if (to) params.to = to;
  return api.get('/superadmin/transactions', { params });
};

export const exportPlatformTransactionsCsv = ({ type, status, from, to } = {}) => {
  const params = {};
  if (type) params.type = type;
  if (status) params.status = status;
  if (from) params.from = from;
  if (to) params.to = to;
  return api.get('/superadmin/transactions/export', { params, responseType: 'blob' });
};

export const getAuditLogs = (page = 0, size = 20, { action, entityType, from, to } = {}) => {
  const params = { page, size };
  if (action) params.action = action;
  if (entityType) params.entityType = entityType;
  if (from) params.from = from;
  if (to) params.to = to;
  return api.get('/superadmin/audit-logs', { params });
};

export const getPlatformSettings = (page = 0, size = 20) => {
  return api.get('/superadmin/settings', { params: { page, size } });
};

export const updatePlatformSetting = (key, value) => {
  const params = { key, value };
  return api.patch('/superadmin/settings', {}, { params });
};

export const updateInvestorFarmerShares = (investorSharePct, farmerSharePct) => {
  const params = { investorSharePct, farmerSharePct };
  return api.patch('/superadmin/settings/shares', {}, { params });
};

export const updateInvestmentContractUrl = (id, contractUrl) => {
  return api.put(`/superadmin/investments/${id}/contract`, {}, { params: { contractUrl } });
};

export const getPlatformInvestments = (page = 0, size = 20, q, status) => {
  const params = { page, size, sort: 'createdAt,desc' };
  if (q) params.q = q;
  if (status) params.status = status;
  return api.get('/superadmin/investments', { params });
};

export const topUpWallet = (userId, amount) => {
  return api.post(`/superadmin/accounts/${userId}/topup`, {}, { params: { amount } });
};
