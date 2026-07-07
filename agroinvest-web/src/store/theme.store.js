import { create } from 'zustand';

const STORAGE_KEY = 'theme';

function applyThemeClass(theme) {
  document.documentElement.classList.toggle('dark', theme === 'dark');
}

function resolveInitialTheme() {
  const stored = localStorage.getItem(STORAGE_KEY);
  if (stored === 'dark' || stored === 'light') return stored;
  return window.matchMedia?.('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

export const useThemeStore = create((set, get) => ({
  theme: 'light',

  // Reads the saved/OS preference and stamps the <html> class - call once at app
  // startup so the very first paint already matches the user's chosen theme.
  initTheme: () => {
    const theme = resolveInitialTheme();
    applyThemeClass(theme);
    set({ theme });
  },

  toggleTheme: () => {
    const next = get().theme === 'dark' ? 'light' : 'dark';
    localStorage.setItem(STORAGE_KEY, next);
    applyThemeClass(next);
    set({ theme: next });
  },
}));
