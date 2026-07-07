import api from './axios';

// Public (unauthenticated) platform settings: negotiated-split slider bounds,
// min investment, commission. Used by CreateProjectForm and public project pages.
export const getPublicSettings = () => {
  return api.get('/settings/public');
};
