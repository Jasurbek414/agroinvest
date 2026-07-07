import React from 'react';
import { useAuthStore } from '../../store/auth.store';
import NotificationBell from '../notifications/NotificationBell';
import UserMenu from './UserMenu';

// Desktop-only (md+) bar sitting beside the Sidebar. Mobile gets the
// equivalent controls inside MobileHeader instead.
const TopBar = () => {
  const { user } = useAuthStore();

  return (
    <header className="hidden md:flex sticky top-0 z-30 h-16 items-center justify-end gap-3 px-6 bg-white/80 dark:bg-slate-900/80 backdrop-blur border-b border-gray-100 dark:border-slate-800">
      {user && <NotificationBell />}
      <UserMenu />
    </header>
  );
};

export default TopBar;
