import api from './axios';

export const createAdminAccount = (phone, name, password, role) => {
  const params = { phone, name, password, role };
  return api.post('/superadmin/accounts', {}, { params });
};

export const blockAccount = (id, block, reason) => {
  const params = { block };
  if (reason) params.reason = reason;
  return api.patch(`/superadmin/accounts/${id}/block`, {}, { params });
};

export const getAuditLogs = (page = 0, size = 20) => {
  return api.get('/superadmin/audit-logs', { params: { page, size } });
};

export const getPlatformSettings = (page = 0, size = 20) => {
  return api.get('/superadmin/settings', { params: { page, size } });
};

export const updatePlatformSetting = (key, value) => {
  const params = { key, value };
  return api.patch('/superadmin/settings', {}, { params });
};
