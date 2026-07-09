import axios from 'axios';

const baseURL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1';

const api = axios.create({
  baseURL,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('accessToken');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

function clearSessionAndRedirect() {
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
  localStorage.removeItem('user');
  window.location.href = '/login';
}

// Guards concurrent refresh attempts: if several requests 401 at once, only the
// first actually calls /auth/refresh - the rest await this same promise instead
// of each firing their own refresh (which, against a backend that rotates
// refresh tokens, would make every refresh after the first fail and force-logout
// the user even though the very first refresh succeeded). Mirrors the mobile
// app's DioClient._tryRefreshToken.
let refreshPromise = null;

function performRefresh() {
  const refreshToken = localStorage.getItem('refreshToken');
  if (!refreshToken) {
    return Promise.resolve(false);
  }

  // Plain axios call (not the `api` instance) so this request never runs
  // through these same interceptors and can't recurse into itself.
  return axios
    .post(`${baseURL}/auth/refresh`, { refreshToken })
    .then((response) => {
      const { accessToken, refreshToken: newRefreshToken } = response.data.data;
      if (!accessToken) return false;
      localStorage.setItem('accessToken', accessToken);
      if (newRefreshToken) {
        localStorage.setItem('refreshToken', newRefreshToken);
      }
      return true;
    })
    .catch(() => false);
}

function tryRefreshToken() {
  if (!refreshPromise) {
    refreshPromise = performRefresh().finally(() => {
      refreshPromise = null;
    });
  }
  return refreshPromise;
}

api.interceptors.response.use(
  (response) => {
    return response.data; // Return only the standard response wrapper data
  },
  async (error) => {
    const { config, response } = error;
    const isAuthEndpoint = config?.url?.includes('/auth/login') || config?.url?.includes('/auth/register') || config?.url?.includes('/auth/refresh');

    if (response && response.status === 401 && !isAuthEndpoint && !config._retried) {
      config._retried = true;
      const refreshed = await tryRefreshToken();
      if (refreshed) {
        const token = localStorage.getItem('accessToken');
        config.headers['Authorization'] = `Bearer ${token}`;
        return api(config);
      }
      clearSessionAndRedirect();
      return Promise.reject(response.data);
    }

    if (response && response.status === 401 && isAuthEndpoint) {
      // A 401 straight out of /auth/refresh means the refresh token itself is
      // dead (expired/rotated/blocked user) - nothing left to retry.
      if (config?.url?.includes('/auth/refresh')) {
        clearSessionAndRedirect();
      }
    }

    return Promise.reject(response ? response.data : error);
  }
);

export default api;
