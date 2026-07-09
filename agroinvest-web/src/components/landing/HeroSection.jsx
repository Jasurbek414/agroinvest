import React from 'react';
import { Link } from 'react-router-dom';
import { TrendingUp, Sprout, ArrowRight } from 'lucide-react';

// Deliberately balanced messaging: an investor and a farmer landing here should
// each see themselves in the first two lines, not have to scroll to find "their" CTA.
const HeroSection = () => {
  return (
    <section className="relative overflow-hidden bg-gradient-to-br from-primary-50 via-white to-primary-50 dark:from-slate-900 dark:via-slate-950 dark:to-slate-900">
      <div className="max-w-6xl mx-auto px-6 py-20 md:py-28 text-center">
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-primary-100 dark:bg-primary-950 text-primary-700 dark:text-primary-300 mb-6">
          <Sprout size={13} /> O'zbekistondagi qishloq xo'jaligi investitsiya platformasi
        </span>
        <h1 className="text-4xl md:text-6xl font-extrabold text-gray-900 dark:text-slate-100 tracking-tight leading-tight">
          Pulingizni yerga qo'ying,<br className="hidden md:block" /> daromadga aylantiring
        </h1>
        <p className="mt-6 text-lg text-gray-500 dark:text-slate-400 max-w-2xl mx-auto">
          Investorlar fermerlarning chorvachilik va dehqonchilik loyihalarini moliyalashtirib foyda ulushi oladi;
          fermerlar esa o'z loyihalariga tez va shaffof mablag' topadi.
        </p>

        <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
          <Link
            to="/register?role=INVESTOR"
            className="inline-flex items-center gap-2 px-7 py-3.5 rounded-xl bg-primary-600 hover:bg-primary-700 text-white font-bold shadow-lg shadow-primary-600/20 transition w-full sm:w-auto justify-center"
          >
            <TrendingUp size={18} /> Investor sifatida boshlash
          </Link>
          <Link
            to="/register?role=FARMER"
            className="inline-flex items-center gap-2 px-7 py-3.5 rounded-xl bg-white dark:bg-slate-800 hover:bg-gray-50 dark:hover:bg-slate-700 text-gray-800 dark:text-slate-100 font-bold border border-gray-200 dark:border-slate-600 shadow-sm transition w-full sm:w-auto justify-center"
          >
            <Sprout size={18} /> Fermer sifatida loyiha qo'yish
          </Link>
        </div>

        <Link
          to="/projects"
          className="mt-8 inline-flex items-center gap-1 text-sm font-semibold text-primary-700 dark:text-primary-400 hover:underline"
        >
          Faol loyihalarni ko'rish <ArrowRight size={14} />
        </Link>
      </div>
    </section>
  );
};

export default HeroSection;
