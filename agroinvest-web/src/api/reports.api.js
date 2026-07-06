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
