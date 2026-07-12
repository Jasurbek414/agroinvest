import api from './axios';

export const getRegions = () => api.get('/regions');
export const createRegion = (payload) => api.post('/superadmin/regions', payload);
export const deleteRegion = (id) => api.delete(`/superadmin/regions/${id}`);
