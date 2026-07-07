import api from './axios';

export const getAdminDashboardStats = () => {
  return api.get('/admin/dashboard');
};

export const getAssetTypeBreakdown = () => {
  return api.get('/admin/dashboard/asset-types');
};

export const getProjectStatusBreakdown = () => {
  return api.get('/admin/dashboard/project-status');
};

export const getWithdrawalRequests = (page = 0, size = 12) => {
  return api.get('/withdrawals', { params: { page, size } });
};

export const approveWithdrawal = (id, approve, adminComment) => {
  const params = { approve };
  if (adminComment) params.adminComment = adminComment;
  return api.patch(`/withdrawals/${id}`, {}, { params });
};

export const getUsers = (page = 0, size = 50, { role, q } = {}) => {
  const params = { page, size };
  if (role) params.role = role;
  if (q) params.q = q;
  return api.get('/users', { params });
};

export const verifyUserKyc = (id, status, rejectedReason) => {
  const params = { status };
  if (rejectedReason) params.rejectedReason = rejectedReason;
  return api.patch(`/users/${id}/kyc`, {}, { params });
};

export const blockUser = (id, block, reason) => {
  const params = { block };
  if (reason) params.reason = reason;
  return api.patch(`/users/${id}/block`, {}, { params });
};

