import React from 'react';
import { ShieldCheck, Users, Target, CheckCircle2, Award, Scale } from 'lucide-react';

const AboutPage = () => {
  return (
    <div className="min-h-screen bg-gray-50/40 dark:bg-slate-950 p-6 md:p-12 transition-all duration-300">
      <div className="max-w-4xl mx-auto space-y-8 animate-in fade-in duration-300">
        
        {/* Banner */}
        <div className="relative overflow-hidden p-8 md:p-10 border border-emerald-500/10 dark:border-slate-800 bg-gradient-to-br from-slate-900 via-slate-950 to-primary-950 text-white rounded-[32px] shadow-xl">
          <div className="absolute top-0 right-0 w-80 h-80 bg-primary-500/10 rounded-full blur-3xl -z-10" />
          <h1 className="text-2xl md:text-4xl font-black text-white tracking-tight">Platforma haqida</h1>
          <p className="text-gray-305 text-xs md:text-sm mt-2 max-w-2xl leading-relaxed">
            AgroInvest — bu O'zbekistondagi ilk qishloq xo'jaligi va moliyaviy texnologiyalar (agrotech) kooperatsiyasi platformasi bo'lib, investorlar va fermerlar o'rtasida ishonchli sarmoya ko'prigini yaratadi.
          </p>
        </div>

        {/* Content details */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/60 dark:border-slate-800/80 shadow-sm space-y-4">
            <div className="flex items-center gap-2 text-primary-650 dark:text-primary-400 font-extrabold text-sm uppercase">
              <Target size={16} />
              <span>Bizning missiyamiz</span>
            </div>
            <p className="text-xs sm:text-sm text-gray-605 dark:text-slate-350 leading-relaxed">
              Qishloq xo'jaligi sohasiga shaffof va oson sarmoyalar oqimini yo'naltirish orqali dehqon va chorvadorlarimizga keng imkoniyatlar yaratish, hamda investorlar uchun yuqori rentabelli va xavfsiz agro-aktivlar bozorini taqdim etish.
            </p>
          </div>

          <div className="bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/60 dark:border-slate-800/80 shadow-sm space-y-4">
            <div className="flex items-center gap-2 text-primary-650 dark:text-primary-400 font-extrabold text-sm uppercase">
              <ShieldCheck size={16} />
              <span>Bizning xavfsizlik kafolatimiz</span>
            </div>
            <p className="text-xs sm:text-sm text-gray-605 dark:text-slate-350 leading-relaxed">
              Barcha loyihalar verifikatorlar tomonidan joyida tekshiriladi va veterinariya nazorati doimiy ravishda olib boriladi. Biznes shartnomalari huquqiy jihatdan himoyalangan bo'lib, platforma nizolarni nazorat qiladi.
            </p>
          </div>
        </div>

        {/* Core Principles */}
        <div className="bg-white dark:bg-slate-900 p-6 md:p-8 rounded-3xl border border-gray-150/60 dark:border-slate-800/80 shadow-sm space-y-6">
          <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base md:text-lg">Asosiy qadriyatlarimiz</h3>
          
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
            <div className="space-y-2">
              <div className="w-8 h-8 rounded-xl bg-primary-50 dark:bg-primary-950/40 text-primary-600 dark:text-primary-400 flex items-center justify-center shadow-inner">
                <CheckCircle2 size={16} />
              </div>
              <h4 className="font-extrabold text-sm text-gray-900 dark:text-slate-150">Shaffoflik</h4>
              <p className="text-[11px] text-gray-500 dark:text-slate-450 leading-relaxed">Har bir xarajat hujjati, o'sish hisobotlari va foto-dalillar doimiy ochiq holatda investorga taqdim etiladi.</p>
            </div>
            
            <div className="space-y-2">
              <div className="w-8 h-8 rounded-xl bg-primary-50 dark:bg-primary-950/40 text-primary-600 dark:text-primary-400 flex items-center justify-center shadow-inner">
                <Award size={16} />
              </div>
              <h4 className="font-extrabold text-sm text-gray-900 dark:text-slate-150">Sifat Nazorati</h4>
              <p className="text-[11px] text-gray-500 dark:text-slate-450 leading-relaxed">Veterinariya xizmati va agro-inspektorlar hayvonlarning emlanishi hamda oziqlantirilishini doimiy tekshiradi.</p>
            </div>

            <div className="space-y-2">
              <div className="w-8 h-8 rounded-xl bg-primary-50 dark:bg-primary-950/40 text-primary-600 dark:text-primary-400 flex items-center justify-center shadow-inner">
                <Scale size={16} />
              </div>
              <h4 className="font-extrabold text-sm text-gray-900 dark:text-slate-150">Huquqiy Himoya</h4>
              <p className="text-[11px] text-gray-500 dark:text-slate-450 leading-relaxed">Har bir sarmoya bitimi bo'yicha platformada elektron shartnoma tuziladi va qonuniy kuchga ega bo'ladi.</p>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
};

export default AboutPage;
