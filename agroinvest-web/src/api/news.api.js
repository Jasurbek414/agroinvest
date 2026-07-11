import api from './axios';

export const getAllNews = (page = 0, size = 20) => api.get('/superadmin/news', { params: { page, size } });

export const createNews = (payload) => api.post('/superadmin/news', payload);

export const updateNews = (id, payload) => api.patch(`/superadmin/news/${id}`, payload);

export const deleteNews = (id) => api.delete(`/superadmin/news/${id}`);
