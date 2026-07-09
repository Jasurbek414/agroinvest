import api from './axios';

export const getAllBanners = () => api.get('/superadmin/banners');

export const createBanner = (payload) => api.post('/superadmin/banners', payload);

export const updateBanner = (id, payload) => api.patch(`/superadmin/banners/${id}`, payload);

export const deleteBanner = (id) => api.delete(`/superadmin/banners/${id}`);
