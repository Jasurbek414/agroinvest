import api from './axios';

export const getActiveCoopOffers = (type = '') => api.get('/coop-offers', { params: { type } });

export const createCoopOffer = (payload) => api.post('/coop-offers', payload);

export const getSuperAdminCoopOffers = () => api.get('/superadmin/coop-offers');

export const updateCoopOfferStatus = (id, status) => api.patch(`/superadmin/coop-offers/${id}/status`, null, { params: { status } });

export const deleteCoopOffer = (id) => api.delete(`/superadmin/coop-offers/${id}`);
