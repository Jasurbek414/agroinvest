import React, { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { LogOut, Moon, Sun, Languages } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { useAuthStore } from '../../store/auth.store';
import { useThemeStore } from '../../store/theme.store';

// Only 'uz' exists today (PLATFORM_ROADMAP.md Phase 0.5 is mechanism-only;
// Phase 3 adds ru/en) - listed here so the selector below needs no rewiring
// when a second language is added, just a new entry in this array.
const LANGUAGES = [{ code: 'uz', label: "O'zbek" }];

const ROLE_LABEL = {
  INVESTOR: 'Investor',
  FARMER: 'Fermer',
  ADMIN: 'Admin',
  MODERATOR: 'Moderator',
  SUPERADMIN: 'SuperAdmin',
  VERIFIER: 'Verifikator',
};

const UserMenu = () => {
  const { user, logout } = useAuthStore();
  const { theme, toggleTheme } = useThemeStore();
  const { t, i18n } = useTranslation();
  const [open, setOpen] = useState(false);
  const containerRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (containerRef.current && !containerRef.current.contains(e.target)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  if (!user) {
    return (
      <Link
        to="/login"
        className="px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white text-sm font-bold rounded-xl transition"
      >
        {t('common.login')}
      </Link>
    );
  }

  const initials = (user.fullName || '?')
    .split(' ')
    .filter(Boolean)
    .map((part) => part[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();

  return (
    <div className="relative" ref={containerRef}>
      <button
        onClick={() => setOpen((o) => !o)}
        className="flex items-center gap-2 pl-1 pr-2 py-1 rounded-full hover:bg-gray-100 dark:hover:bg-slate-800 transition"
      >
        <span className="w-8 h-8 rounded-full bg-primary-100 dark:bg-primary-900 text-primary-700 dark:text-primary-300 flex items-center justify-center text-xs font-bold shrink-0">
          {initials}
        </span>
        <span className="hidden sm:inline text-sm font-bold text-gray-700 dark:text-slate-200">{user.fullName}</span>
      </button>

      {open && (
        <div className="absolute right-0 mt-2 w-64 bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-xl z-50 overflow-hidden">
          <div className="px-4 py-3 border-b border-gray-100 dark:border-slate-700">
            <p className="text-sm font-bold text-gray-900 dark:text-slate-100 truncate">{user.fullName}</p>
            <span className="inline-block mt-1.5 text-[11px] bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-slate-300 px-2.5 py-0.5 rounded-full font-bold uppercase tracking-wide">
              {ROLE_LABEL[user.role] || user.role}
            </span>
          </div>
          <button
            onClick={toggleTheme}
            className="w-full flex items-center gap-3 px-4 py-3 text-sm font-semibold text-gray-700 dark:text-slate-200 hover:bg-gray-50 dark:hover:bg-slate-700 transition"
          >
            {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
            {theme === 'dark' ? t('common.lightMode') : t('common.darkMode')}
          </button>
          <div className="flex items-center gap-3 px-4 py-3 text-sm font-semibold text-gray-700 dark:text-slate-200 border-t border-gray-100 dark:border-slate-700">
            <Languages size={16} className="shrink-0" />
            <span className="shrink-0">{t('common.language')}:</span>
            <select
              value={i18n.language}
              onChange={(e) => i18n.changeLanguage(e.target.value)}
              className="ml-auto bg-transparent text-sm font-semibold outline-none cursor-pointer"
            >
              {LANGUAGES.map((lang) => (
                <option key={lang.code} value={lang.code}>{lang.label}</option>
              ))}
            </select>
          </div>
          <button
            onClick={logout}
            className="w-full flex items-center gap-3 px-4 py-3 text-sm font-semibold text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/40 transition"
          >
            <LogOut size={16} />
            {t('common.logout')}
          </button>
        </div>
      )}
    </div>
  );
};

export default UserMenu;
