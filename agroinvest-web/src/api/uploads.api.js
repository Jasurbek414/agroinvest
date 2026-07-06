import api from './axios';

// category: 'kyc' | 'project' | 'report'. Returns { url }.
export const uploadFile = (file, category = 'general') => {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('category', category);
  return api.post('/uploads', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
};
