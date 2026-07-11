import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { X } from 'lucide-react';
import { useAuthStore } from '../../store/auth.store';
import { getNavLinks } from './navLinks';

// Slide-in nav drawer for < md screens. Previously the navbar's link row was
// simply `hidden` below md with no replacement, so mobile users (the majority
// of this platform's traffic) had no way to navigate beyond the current page.
const MobileDrawer = ({ open, onClose }) => {
  const { user } = useAuthStore();
  const location = useLocation();
  
  const links = user ? getNavLinks(user.role) : [];
  const isDashboard = location.pathname.endsWith('/dashboard');
  const currentUrl = location.pathname + (location.search || (isDashboard ? '?tab=withdrawals' : ''));

  return (
    <div className={`md:hidden fixed inset-0 z-50 ${open ? '' : 'pointer-events-none'}`} aria-hidden={!open}>
      <div
        className={`absolute inset-0 bg-black/40 transition-opacity duration-200 ${open ? 'opacity-100' : 'opacity-0'}`}
        onClick={onClose}
      />
      <div
        className={`absolute left-0 top-0 h-full w-72 max-w-[80vw] bg-white dark:bg-slate-900 shadow-xl transition-transform duration-200 ${
          open ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="h-16 flex items-center justify-between px-4 border-b border-gray-100 dark:border-slate-800">
          <span className="text-lg font-black text-primary-700 dark:text-primary-400">AgroInvest</span>
          <button
            onClick={onClose}
            aria-label="Menyuni yopish"
            className="p-2 rounded-xl hover:bg-gray-100 dark:hover:bg-slate-800 text-gray-600 dark:text-slate-300"
          >
            <X size={20} />
          </button>
        </div>
        <nav className="p-3 space-y-1">
          {(() => {
            let lastSection = null;
            return links.map(({ to, label, icon: Icon, section }) => {
              const isLinkActive = currentUrl === to;
              const showHeader = section && section !== lastSection;
              lastSection = section;

              return (
                <React.Fragment key={to}>
                  {showHeader && (
                    <div className="pt-4 pb-1.5 px-3 text-[10px] font-bold text-gray-400 dark:text-slate-500 uppercase tracking-wider">
                      {section}
                    </div>
                  )}
                  <Link
                    to={to}
                    onClick={onClose}
                    className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold transition ${
                      isLinkActive
                        ? 'bg-primary-50 text-primary-700 dark:bg-primary-950 dark:text-primary-300'
                        : 'text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-800'
                    }`}
                  >
                    <Icon size={18} />
                    {label}
                  </Link>
                </React.Fragment>
              );
            });
          })()}
        </nav>
      </div>
    </div>
  );
};

export default MobileDrawer;
