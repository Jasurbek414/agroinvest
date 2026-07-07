import React from 'react';
import Sidebar from './Sidebar';
import MobileHeader from './MobileHeader';
import TopBar from './TopBar';

// Replaces the old single inline `Layout` (a bare top navbar with no sidebar
// and no mobile nav) with a real app shell: desktop sidebar + topbar, mobile
// header + slide-in drawer.
const AppShell = ({ children }) => (
  <div className="min-h-screen flex bg-gray-50 dark:bg-slate-900">
    <Sidebar />
    <div className="flex-1 flex flex-col min-w-0">
      <MobileHeader />
      <TopBar />
      <main className="flex-1">{children}</main>
    </div>
  </div>
);

export default AppShell;
