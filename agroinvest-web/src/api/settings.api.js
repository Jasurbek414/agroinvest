import api from './axios';

// Public (unauthenticated) platform settings: negotiated-split slider bounds,
// min investment, commission. Used by CreateProjectForm and public project pages.
export const getPublicSettings = () => {
  return api.get('/settings/public');
};

// Coarse, non-sensitive platform-wide counters for the public landing page's
// trust stat tiles (total investors/farmers/funded projects/invested amount).
export const getPublicStats = () => {
  return api.get('/settings/public-stats');
};

export const getAppVersion = () => {
  return api.get('/settings/app-version');
};
