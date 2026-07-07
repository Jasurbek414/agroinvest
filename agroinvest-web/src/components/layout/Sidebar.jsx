import React from 'react';
import { Link, NavLink } from 'react-router-dom';
import { useAuthStore } from '../../store/auth.store';
import { getNavLinks } from './navLinks';

// Desktop-only (md+) fixed left navigation. Replaces the old single-row of
// horizontal links, which had no room for a growing number of role-specific
// sections and disappeared entirely below the md breakpoint.
const Sidebar = () => {
  const { user } = useAuthStore();
  if (!user) return null;

  const links = getNavLinks(user.role);

  return (
    <aside className="hidden md:flex md:flex-col md:w-64 md:shrink-0 md:h-screen md:sticky md:top-0 bg-white dark:bg-slate-900 border-r border-gray-100 dark:border-slate-800">
      <div className="h-16 flex items-center px-6">
        <Link to="/projects" className="text-xl font-black text-primary-700 dark:text-primary-400 tracking-tight">
          AgroInvest
        </Link>
      </div>
      <nav className="flex-1 px-3 py-2 space-y-1 overflow-y-auto">
        {links.map(({ to, label, icon: Icon }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/projects'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold transition ${
                isActive
                  ? 'bg-primary-50 text-primary-700 dark:bg-primary-950 dark:text-primary-300'
                  : 'text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-800'
              }`
            }
          >
            <Icon size={18} />
            {label}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
};

export default Sidebar;
