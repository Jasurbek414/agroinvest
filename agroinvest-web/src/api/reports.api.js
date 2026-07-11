import api from './axios';

export const submitReport = (projectId, reportData) => {
  return api.post(`/reports/project/${projectId}`, reportData);
};

export const getProjectReports = (projectId, page = 0, size = 12) => {
  return api.get(`/reports/project/${projectId}`, { params: { page, size } });
};

export const verifyReport = (reportId, verify, adminComment) => {
  const params = { verify };
  if (adminComment) params.adminComment = adminComment;
  return api.patch(`/reports/${reportId}/verify`, {}, { params });
};

export const getUnverifiedReports = (page = 0, size = 12) => {
  return api.get('/reports/unverified', { params: { page, size } });
};

// Full history for the admin/superadmin console: verified reports stay
// visible after review. Optional reportType/verified filters are applied
// server-side so pagination stays correct.
export const getAllReports = (page = 0, size = 12, { reportType, verified } = {}) => {
  const params = { page, size, sort: 'createdAt,desc' };
  if (reportType) params.reportType = reportType;
  if (verified !== undefined && verified !== null && verified !== '') params.verified = verified;
  return api.get('/reports', { params });
};
