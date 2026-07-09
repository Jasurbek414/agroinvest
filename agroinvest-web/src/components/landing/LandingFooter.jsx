import React from 'react';
import { Link } from 'react-router-dom';

const LandingFooter = () => {
  const year = new Date().getFullYear();
  return (
    <footer className="border-t border-gray-100 dark:border-slate-800 bg-white dark:bg-slate-950">
      <div className="max-w-6xl mx-auto px-6 py-10 flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <span className="text-lg font-black text-primary-700 dark:text-primary-400 tracking-tight">AgroInvest</span>
          <span className="text-xs text-gray-400 dark:text-slate-500">— qishloq xo'jaligi investitsiya platformasi</span>
        </div>
        <nav className="flex items-center gap-6 text-sm font-semibold text-gray-500 dark:text-slate-400">
          <Link to="/projects" className="hover:text-primary-600 dark:hover:text-primary-400">Loyihalar</Link>
          <Link to="/register" className="hover:text-primary-600 dark:hover:text-primary-400">Ro'yxatdan o'tish</Link>
          <Link to="/login" className="hover:text-primary-600 dark:hover:text-primary-400">Kirish</Link>
        </nav>
        <p className="text-xs text-gray-400 dark:text-slate-500">© {year} AgroInvest. Barcha huquqlar himoyalangan.</p>
      </div>
    </footer>
  );
};

export default LandingFooter;
