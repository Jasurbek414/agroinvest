import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { Menu } from 'lucide-react';
import { useAuthStore } from '../../store/auth.store';
import NotificationBell from '../notifications/NotificationBell';
import UserMenu from './UserMenu';
import MobileDrawer from './MobileDrawer';

const MobileHeader = () => {
  const { user } = useAuthStore();
  const [drawerOpen, setDrawerOpen] = useState(false);

  return (
    <>
      <header className="md:hidden sticky top-0 z-40 h-16 flex items-center justify-between gap-2 px-4 bg-white dark:bg-slate-900 border-b border-gray-100 dark:border-slate-800">
        <div className="flex items-center gap-1 min-w-0">
          {user && (
            <button
              onClick={() => setDrawerOpen(true)}
              aria-label="Menyuni ochish"
              className="p-2 -ml-2 rounded-xl hover:bg-gray-100 dark:hover:bg-slate-800 text-gray-700 dark:text-slate-200"
            >
              <Menu size={22} />
            </button>
          )}
          <Link to="/projects" className="text-lg font-black text-primary-700 dark:text-primary-400 truncate">
            AgroInvest
          </Link>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          {user && <NotificationBell />}
          <UserMenu />
        </div>
      </header>
      <MobileDrawer open={drawerOpen} onClose={() => setDrawerOpen(false)} />
    </>
  );
};

export default MobileHeader;
