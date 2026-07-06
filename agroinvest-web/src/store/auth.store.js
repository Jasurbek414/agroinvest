import { create } from 'zustand';
import api from '../api/axios';

export const useAuthStore = create((set) => ({
  user: JSON.parse(localStorage.getItem('user')) || null,
  accessToken: localStorage.getItem('accessToken') || null,
  refreshToken: localStorage.getItem('refreshToken') || null,
  loading: false,
  error: null,

  login: async (phoneNumber, password) => {
    set({ loading: true, error: null });
    try {
      const response = await api.post('/auth/login', { phoneNumber, password });
      const { accessToken, refreshToken, userId, fullName, role } = response.data;
      
      const userData = { id: userId, fullName, phoneNumber, role };
      
      localStorage.setItem('accessToken', accessToken);
      localStorage.setItem('refreshToken', refreshToken);
      localStorage.setItem('user', JSON.stringify(userData));
      
      set({
        user: userData,
        accessToken,
        refreshToken,
        loading: false,
      });
      return userData;
    } catch (err) {
      const errMsg = err.error?.message || 'Login failed';
      set({ error: errMsg, loading: false });
      throw err;
    }
  },

  register: async (fullName, phoneNumber, email, password, role) => {
    set({ loading: true, error: null });
    try {
      const response = await api.post('/auth/register', {
        fullName,
        phoneNumber,
        email,
        password,
        role,
      });
      const { accessToken, refreshToken, userId, role: userRole } = response.data;
      
      const userData = { id: userId, fullName, phoneNumber, role: userRole };
      
      localStorage.setItem('accessToken', accessToken);
      localStorage.setItem('refreshToken', refreshToken);
      localStorage.setItem('user', JSON.stringify(userData));
      
      set({
        user: userData,
        accessToken,
        refreshToken,
        loading: false,
      });
      return userData;
    } catch (err) {
      const errMsg = err.error?.message || 'Registration failed';
      set({ error: errMsg, loading: false });
      throw err;
    }
  },

  logout: () => {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('user');
    set({
      user: null,
      accessToken: null,
      refreshToken: null,
      error: null,
    });
  },

  clearError: () => set({ error: null }),
}));
