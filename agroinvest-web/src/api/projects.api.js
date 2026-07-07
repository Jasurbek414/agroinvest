import api from './axios';

export const getProjects = (status, page = 0, size = 12, { assetType, q } = {}) => {
  const params = { page, size };
  if (status) params.status = status;
  if (assetType) params.assetType = assetType;
  if (q) params.q = q;
  return api.get('/projects', { params });
};

export const getProjectById = (id) => {
  return api.get(`/projects/${id}`);
};

export const createProject = (projectData) => {
  return api.post('/projects', projectData);
};

export const updateProject = (id, projectData) => {
  return api.patch(`/projects/${id}`, projectData);
};

export const deleteProject = (id) => {
  return api.delete(`/projects/${id}`);
};

export const changeProjectStatus = (id, status, rejectionReason) => {
  const params = { status };
  if (rejectionReason) params.rejectionReason = rejectionReason;
  return api.patch(`/projects/${id}/status`, {}, { params });
};

export const getMyProjects = (page = 0, size = 12) => {
  return api.get('/projects/my', { params: { page, size } });
};

// Masked co-investor transparency list (name + share %) for a project.
export const getProjectInvestors = (id) => {
  return api.get(`/projects/${id}/investors`);
};
