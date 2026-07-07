import api from './axios';

export const createAdminAccount = (phone, name, password, role) => {
  const params = { phone, name, password, role };
  return api.post('/superadmin/accounts', {}, { params });
};

export const getAccounts = (page = 0, size = 20, { role, q } = {}) => {
  const params = { page, size };
  if (role) params.role = role;
  if (q) params.q = q;
  return api.get('/superadmin/accounts', { params });
};

export const blockAccount = (id, block, reason) => {
  const params = { block };
  if (reason) params.reason = reason;
  return api.patch(`/superadmin/accounts/${id}/block`, {}, { params });
};

export const getAuditLogs = (page = 0, size = 20, { action } = {}) => {
  const params = { page, size };
  if (action) params.action = action;
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
