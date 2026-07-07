import api from './axios';

// Role-aware aggregates for the logged-in user (INVESTOR or FARMER home).
export const getMyDashboard = () => {
  return api.get('/dashboard/me');
};
