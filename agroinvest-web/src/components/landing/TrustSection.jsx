import React from 'react';
import { ShieldCheck, AlertTriangle, FileCheck2, Scale } from 'lucide-react';

const TRUST_ITEMS = [
  { 
    icon: ShieldCheck, 
    title: 'Haqiqiy KYC Tekshiruvi', 
    desc: "Har bir fermer va investorning pasport ma'lumotlari platforma admin jamoasi tomonidan batafsil va qo'lda vettingdan o'tkaziladi." 
  },
  { 
    icon: FileCheck2, 
    title: "Shaffof Foto/Video Hisobot", 
    desc: "Fermerlar doimiy ravishda dala va chorva holati bo'yicha hisobot yuklab boradilar, barcha sarf-xarajatlar ochiq-oydin ko'rinadi." 
  },
  { 
    icon: Scale, 
    title: 'Nizolarni Kafolatli Hal Qilish', 
    desc: "Har qanday kutilmagan vaziyat yuzaga kelsa, kelishuv shartnomalari hamda adminlar guruhi qonuniy va adolatli yechim topadi." 
  },
];

const TrustSection = () => {
  return (
    <section id="trust-safety" className="max-w-6xl mx-auto px-6 py-16 md:py-24 space-y-12">
      
      {/* Cards list */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {TRUST_ITEMS.map((item) => (
          <div 
            key={item.title} 
            className="text-center p-6 bg-white dark:bg-slate-900 rounded-3xl border border-gray-150/50 dark:border-slate-800/80 shadow-sm hover:shadow-md hover:-translate-y-0.5 transition duration-300 group"
          >
            <span className="inline-flex w-12 h-12 rounded-2xl bg-primary-50 dark:bg-primary-950/40 text-primary-600 dark:text-primary-400 items-center justify-center mb-5 shadow-inner border border-primary-100/50 dark:border-primary-900/30 group-hover:scale-105 transition-transform">
              <item.icon size={22} />
            </span>
            <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base">{item.title}</h3>
            <p className="text-xs text-gray-500 dark:text-slate-400 mt-2.5 leading-relaxed">{item.desc}</p>
          </div>
        ))}
      </div>

      {/* Warning Box */}
      <div className="max-w-3xl mx-auto bg-gradient-to-br from-amber-500/10 via-amber-600/5 to-transparent dark:from-amber-950/20 dark:to-slate-950 border border-amber-500/20 dark:border-amber-900/40 rounded-3xl p-6 md:p-8 flex flex-col sm:flex-row gap-5 shadow-sm hover:shadow transition duration-200">
        <div className="shrink-0 w-12 h-12 rounded-2xl bg-amber-500/15 text-amber-600 dark:text-amber-400 flex items-center justify-center self-start">
          <AlertTriangle size={24} className="animate-pulse" />
        </div>
        <div className="space-y-1.5">
          <h4 className="font-black text-amber-800 dark:text-amber-300 text-sm md:text-base uppercase tracking-wider">Kafolatlangan daromad yo'q!</h4>
          <p className="text-xs sm:text-sm text-amber-700/90 dark:text-amber-400 leading-relaxed">
            Har bir loyihada ko'rsatilgan foyda foizi — bu <strong>kutilayotgan</strong> (prognoz qilingan) daromad hisoblanadi. 
            Chorvachilik va dehqonchilik tabiiy xavflarga (kasallik, ob-havo, narx o'zgarishi va h.k.) ega. 
            Har bir loyihaning risk darajasi (Past / O'rtacha / Yuqori) sahifasida aniq ko'rsatilgan — sarmoya kiritishdan oldin ularni albatta o'qib chiqing.
          </p>
        </div>
      </div>

    </section>
  );
};

export default TrustSection;
