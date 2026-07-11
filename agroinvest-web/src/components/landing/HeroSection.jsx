import React from 'react';
import { Link } from 'react-router-dom';
import { TrendingUp, Sprout, ArrowRight, Sparkles } from 'lucide-react';

const HeroSection = () => {
  return (
    <section className="relative overflow-hidden bg-gradient-to-br from-primary-50 via-white to-primary-50 dark:from-slate-900 dark:via-slate-950 dark:to-slate-900 transition-colors duration-300">
      {/* Decorative Blur Spheres */}
      <div className="absolute top-[-10%] right-[-10%] w-[40vw] h-[40vw] bg-primary-400/10 dark:bg-primary-500/5 rounded-full blur-3xl" />
      <div className="absolute bottom-[-10%] left-[-10%] w-[35vw] h-[35vw] bg-amber-400/5 dark:bg-amber-500/5 rounded-full blur-3xl" />

      <div className="max-w-6xl mx-auto px-6 py-16 md:py-28 text-center relative z-10">
        
        {/* Subtitle Badge */}
        <span className="inline-flex items-center gap-1.5 px-4 py-1.5 rounded-full text-[10px] sm:text-xs font-bold bg-primary-100/80 dark:bg-primary-950/40 text-primary-700 dark:text-primary-300 border border-primary-200/50 dark:border-primary-900/30 mb-6 shadow-sm">
          <Sprout size={13} className="animate-bounce" />
          <span>O'zbekistondagi ilk qishloq xo'jaligi investitsiya platformasi</span>
        </span>
        
        {/* Main Title */}
        <h1 className="text-3xl xs:text-4xl sm:text-5xl md:text-6xl font-black text-gray-900 dark:text-slate-100 tracking-tight leading-[1.15] max-w-4xl mx-auto">
          Pulingizni yerga qo'ying,<br className="hidden sm:block" />{' '}
          <span className="bg-gradient-to-r from-primary-600 to-emerald-500 bg-clip-text text-transparent dark:from-primary-400 dark:to-emerald-300">
            daromadga aylantiring
          </span>
        </h1>
        
        {/* Description */}
        <p className="mt-6 text-sm sm:text-base md:text-lg text-gray-500 dark:text-slate-450 max-w-2xl mx-auto leading-relaxed">
          Investorlar fermerlarning chorvachilik va dehqonchilik loyihalarini moliyalashtirib barqaror foyda ulushi oladilar;
          fermerlar esa o'z loyihalarini rivojlantirishga tez va shaffof sarmoya topadilar.
        </p>

        {/* Action CTAs */}
        <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4 max-w-md sm:max-w-none mx-auto">
          <Link
            to="/register?role=INVESTOR"
            className="inline-flex items-center gap-2.5 px-8 py-4 rounded-2xl bg-primary-600 hover:bg-primary-500 text-white font-extrabold text-sm shadow-xl shadow-primary-600/20 hover:shadow-primary-600/30 hover:scale-[1.02] active:scale-[0.98] transition duration-200 w-full sm:w-auto justify-center group"
          >
            <TrendingUp size={16} className="group-hover:translate-x-0.5 transition-transform" />
            <span>Investor bo'lib boshlash</span>
          </Link>
          <Link
            to="/register?role=FARMER"
            className="inline-flex items-center gap-2.5 px-8 py-4 rounded-2xl bg-white dark:bg-slate-800 hover:bg-gray-50 dark:hover:bg-slate-750 text-gray-800 dark:text-slate-100 font-extrabold text-sm border border-gray-200 dark:border-slate-700 shadow-sm hover:shadow-md hover:scale-[1.02] active:scale-[0.98] transition duration-200 w-full sm:w-auto justify-center"
          >
            <Sprout size={16} />
            <span>Fermer bo'lib ariza berish</span>
          </Link>
        </div>

        {/* Projects link */}
        <div className="mt-8">
          <Link
            to="/projects"
            className="inline-flex items-center gap-1.5 text-xs sm:text-sm font-bold text-primary-700 dark:text-primary-400 hover:text-primary-600 dark:hover:text-primary-300 transition group"
          >
            <span>Faol investitsiya loyihalarini ko'rish</span>
            <ArrowRight size={14} className="group-hover:translate-x-0.5 transition-transform" />
          </Link>
        </div>

      </div>
    </section>
  );
};

export default HeroSection;
