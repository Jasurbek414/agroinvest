import React from 'react';
import { TrendingUp, Sprout, Sparkles } from 'lucide-react';

const INVESTOR_STEPS = [
  { title: "Ro'yxatdan o'ting va KYC tasdiqlang", desc: "Pasport ma'lumotlarini yuklab, xavfsiz va tezkor tekshiruvdan o'ting." },
  { title: 'Loyihani tanlang va sarmoya kiriting', desc: "Xavf darajasi, kutilayotgan foyda foizi va muddatlarni solishtirib, qulay loyihani tanlang." },
  { title: 'Hisobotlarni kuzating va foyda oling', desc: "Fermerning muntazam foto/video hisobotlarini ko'ring va muddat yakunida foydani yeching." },
];

const FARMER_STEPS = [
  { title: "Ro'yxatdan o'ting va loyiha yarating", desc: "Chorva yoki ekin loyihangizni batafsil tavsif, rasmlar va moliyaviy shartlar bilan joylashtiring." },
  { title: 'Admin tasdiqlaydi va sarmoya yig\'iladi', desc: "Loyihangiz tekshiruvdan o'tgach, investorlar platforma orqali mablag' kiritishni boshlaydilar." },
  { title: "Ishlang, hisobot bering va foyda oling", desc: "Loyihani boshqaring, hisobotlarni yuklang va yakunda kelishilgan foyda ulushiga ega bo'ling." },
];

const StepList = ({ icon: Icon, title, accent, steps, darkTheme }) => (
  <div className="bg-white dark:bg-slate-900 rounded-[28px] border border-gray-150/60 dark:border-slate-800/80 shadow-sm p-6 md:p-8 hover:shadow-md hover:-translate-y-1 transition-all duration-300 group">
    <div className="flex items-center gap-3 mb-6">
      <span className={`w-10 h-10 rounded-2xl flex items-center justify-center shadow-inner group-hover:scale-105 transition-transform ${accent}`}>
        <Icon size={20} />
      </span>
      <h3 className="text-lg font-extrabold text-gray-900 dark:text-slate-100">{title}</h3>
    </div>
    <ol className="space-y-6">
      {steps.map((step, i) => (
        <li key={step.title} className="flex gap-4 items-start">
          <span className="shrink-0 w-8 h-8 rounded-full bg-gradient-to-br from-gray-100 to-gray-200/50 dark:from-slate-800 dark:to-slate-900 text-gray-700 dark:text-slate-300 text-xs font-black flex items-center justify-center border border-gray-200/20 shadow-sm">
            {i + 1}
          </span>
          <div className="space-y-1">
            <p className="font-extrabold text-sm text-gray-950 dark:text-slate-100 leading-none">{step.title}</p>
            <p className="text-xs text-gray-500 dark:text-slate-400 leading-relaxed mt-1">{step.desc}</p>
          </div>
        </li>
      ))}
    </ol>
  </div>
);

const HowItWorksSection = () => {
  return (
    <section id="how-it-works" className="max-w-6xl mx-auto px-6 py-16 md:py-24">
      <div className="text-center mb-12">
        <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-[10px] font-bold bg-primary-100 dark:bg-primary-950/40 text-primary-700 dark:text-primary-400 border border-primary-200/30 uppercase tracking-wider">Jarayonlar</span>
        <h2 className="text-2xl md:text-4xl font-black text-gray-900 dark:text-slate-100 tracking-tight mt-3">Platforma qanday ishlaydi?</h2>
        <p className="text-sm text-gray-500 dark:text-slate-450 mt-2 max-w-xl mx-auto">Sarmoyador va fermerlarimiz uchun barcha bosqichlar sodda, xavfsiz va shaffof tuzilgan.</p>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <StepList
          icon={TrendingUp}
          title="Investorlar uchun"
          accent="bg-primary-50 dark:bg-primary-950/30 text-primary-600 dark:text-primary-400 border border-primary-100/50 dark:border-primary-900/30"
          steps={INVESTOR_STEPS}
        />
        <StepList
          icon={Sprout}
          title="Fermerlar uchun"
          accent="bg-amber-50 dark:bg-amber-950/30 text-amber-600 dark:text-amber-400 border border-amber-100/50 dark:border-amber-900/30"
          steps={FARMER_STEPS}
        />
      </div>
    </section>
  );
};

export default HowItWorksSection;
