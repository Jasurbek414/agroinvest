import api from './axios';

export const getMe = () => {
  return api.get('/users/me');
};

export const updateProfile = (payload) => {
  return api.patch('/users/me', payload);
};

export const submitKyc = (payload) => {
  return api.post('/users/me/kyc', payload);
};
