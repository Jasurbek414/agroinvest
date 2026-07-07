import api from './axios';

export const submitVetInspection = (projectId, inspectionData) => {
  return api.post(`/vet-inspections/project/${projectId}`, inspectionData);
};

// VERIFIED inspections are public; PENDING/REJECTED additionally visible to
// the project owner and staff (server-side filtered).
export const getProjectVetInspections = (projectId) => {
  return api.get(`/vet-inspections/project/${projectId}`);
};

export const getPendingVetInspections = (page = 0, size = 12) => {
  return api.get('/vet-inspections/pending', { params: { page, size } });
};

export const verifyVetInspection = (id, approve, comment) => {
  return api.patch(`/vet-inspections/${id}/verify`, { approve, comment });
};
