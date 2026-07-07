import api from './axios';

export const sendOtp = (phoneNumber, purpose) => {
  return api.post('/auth/send-otp', { phoneNumber, purpose });
};

export const verifyOtp = (phoneNumber, purpose, code) => {
  return api.post('/auth/verify-otp', { phoneNumber, purpose, code });
};
