import React from 'react';
import { TrendingUp, Sprout } from 'lucide-react';

const INVESTOR_STEPS = [
  { title: "Ro'yxatdan o'ting va KYC tasdiqlang", desc: "Pasport ma'lumotlarini yuklab, xavfsiz tekshiruvdan o'ting" },
  { title: 'Loyihani tanlang va sarmoya kiriting', desc: "Xavf darajasi, kutilayotgan foyda va muddatni solishtirib qaror qabul qiling" },
  { title: 'Hisobotlarni kuzating, foyda oling', desc: "Fermerning muntazam hisobotlarini ko'ring va loyiha yakunida ulushingizni yeching" },
];

const FARMER_STEPS = [
  { title: "Ro'yxatdan o'ting va loyiha yarating", desc: "Chorva yoki ekin loyihangizni tavsif, rasm va moliyaviy shartlar bilan joylang" },
  { title: 'Admin tasdiqlaydi, mablag' + "'" + ' yig\'iladi', desc: "Loyihangiz tekshiruvdan o'tgach, investorlar mablag' kirita boshlaydi" },
  { title: "Ishlang, hisobot bering, daromad oling", desc: "Muntazam hisobot yuboring, xarajatlarni qayd eting va yakunda foydangizni oling" },
];

const StepList = ({ icon: Icon, title, accent, steps }) => (
  <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm p-6 md:p-8">
    <div className="flex items-center gap-2 mb-6">
      <span className={`w-9 h-9 rounded-xl flex items-center justify-center ${accent}`}>
        <Icon size={18} />
      </span>
      <h3 className="text-lg font-bold text-gray-900 dark:text-slate-100">{title}</h3>
    </div>
    <ol className="space-y-5">
      {steps.map((step, i) => (
        <li key={step.title} className="flex gap-3">
          <span className="shrink-0 w-7 h-7 rounded-full bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-slate-300 text-xs font-bold flex items-center justify-center">
            {i + 1}
          </span>
          <div>
            <p className="font-semibold text-sm text-gray-900 dark:text-slate-100">{step.title}</p>
            <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">{step.desc}</p>
          </div>
        </li>
      ))}
    </ol>
  </div>
);

const HowItWorksSection = () => {
  return (
    <section className="max-w-6xl mx-auto px-6 py-16 md:py-24">
      <div className="text-center mb-12">
        <h2 className="text-2xl md:text-3xl font-extrabold text-gray-900 dark:text-slate-100">Qanday ishlaydi</h2>
        <p className="text-gray-500 dark:text-slate-400 mt-2">Har ikkala tomon uchun ham oddiy va shaffof jarayon</p>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <StepList
          icon={TrendingUp}
          title="Investorlar uchun"
          accent="bg-primary-50 dark:bg-primary-950 text-primary-600 dark:text-primary-400"
          steps={INVESTOR_STEPS}
        />
        <StepList
          icon={Sprout}
          title="Fermerlar uchun"
          accent="bg-amber-50 dark:bg-amber-950 text-amber-600 dark:text-amber-400"
          steps={FARMER_STEPS}
        />
      </div>
    </section>
  );
};

export default HowItWorksSection;
