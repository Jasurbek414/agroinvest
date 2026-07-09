import api from './axios';

export const getCategoryTree = () => api.get('/categories');

export const getAllCategoriesTree = () => api.get('/categories/all');

export const createCategory = (payload) => api.post('/categories', payload);

export const updateCategory = (id, payload) => api.patch(`/categories/${id}`, payload);
