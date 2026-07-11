import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Sprout } from 'lucide-react';
import { useAuthStore } from '../../store/auth.store';
import { getNavLinks } from './navLinks';
import { useThemeStore } from '../../store/theme.store';

const Sidebar = () => {
  const { user } = useAuthStore();
  const location = useLocation();
  const { sidebarCollapsed, toggleSidebar } = useThemeStore();
  
  if (!user) return null;

  const links = getNavLinks(user.role);
  const isDashboard = location.pathname.endsWith('/dashboard');
  const currentUrl = location.pathname + (location.search || (isDashboard ? '?tab=withdrawals' : ''));

  return (
    <aside className={`hidden md:flex md:flex-col shrink-0 h-screen sticky top-0 bg-white dark:bg-slate-900 border-r border-gray-100 dark:border-slate-800 transition-all duration-300 ${sidebarCollapsed ? 'w-20' : 'w-64'}`}>
      <div className={`h-16 flex items-center ${sidebarCollapsed ? 'justify-center' : 'px-6'}`}>
        <button
          onClick={toggleSidebar}
          className="flex items-center gap-2.5 focus:outline-none"
          aria-label={sidebarCollapsed ? "Menyuni yozish" : "Menyuni yig'ish"}
        >
          <span className="w-9 h-9 rounded-xl bg-primary-600 flex items-center justify-center text-white shadow-sm shrink-0 hover:bg-primary-500 transition">
            <Sprout size={18} />
          </span>
          {!sidebarCollapsed && (
            <span className="text-lg font-black text-primary-700 dark:text-primary-400 tracking-tight animate-in fade-in duration-300">
              AgroInvest
            </span>
          )}
        </button>
      </div>

      <nav className="flex-1 px-3 py-2 space-y-1 overflow-y-auto scrollbar-none">
        {(() => {
          let lastSection = null;
          return links.map(({ to, label, icon: Icon, section }) => {
            const isLinkActive = currentUrl === to;
            const showHeader = section && section !== lastSection;
            lastSection = section;

            return (
              <React.Fragment key={to}>
                {showHeader && (
                  sidebarCollapsed ? (
                    <div className="my-3 border-t border-gray-100 dark:border-slate-800" />
                  ) : (
                    <div className="pt-4 pb-1.5 px-3 text-[10px] font-bold text-gray-400 dark:text-slate-500 uppercase tracking-wider animate-in fade-in duration-300">
                      {section}
                    </div>
                  )
                )}
                <Link
                  to={to}
                  title={sidebarCollapsed ? label : undefined}
                  className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold transition ${
                    isLinkActive
                      ? 'bg-primary-50 text-primary-700 dark:bg-primary-950 dark:text-primary-300'
                      : 'text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-800'
                  } ${sidebarCollapsed ? 'justify-center' : ''}`}
                >
                  <Icon size={18} className="shrink-0" />
                  {!sidebarCollapsed && (
                    <span className="truncate animate-in fade-in duration-200">{label}</span>
                  )}
                </Link>
              </React.Fragment>
            );
          });
        })()}
      </nav>
    </aside>
  );
};

export default Sidebar;
