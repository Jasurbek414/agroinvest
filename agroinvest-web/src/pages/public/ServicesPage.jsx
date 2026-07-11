import React from 'react';
import { ShieldCheck, HeartPulse, Hammer, Landmark, Award, Star } from 'lucide-react';

const SERVICES = [
  { id: 1, icon: HeartPulse, title: "Veterinariya & Sanitariya Nazorati", desc: "Tajribali veterinar shifokorlarimiz hayvonlarni emlash va doimiy monitoring xizmatini yo'lga qo'yadilar.", status: "Faol" },
  { id: 2, icon: ShieldCheck, title: "Qonuniy Huquqiy Kooperatsiya", desc: "Investor va fermer o'rtasidagi bitimlarni notarial hamda elektron tasdiqlash, soliq maslahatlari.", status: "Faol" },
  { id: 3, icon: Landmark, title: "Sug'urta & Agro-Kafolat", desc: "Ekinlar va chorvani tabiiy ofat, kasalliklar hamda nobud bo'lish xavflaridan kafolatli sug'urtalash.", status: "Tez kunda" },
  { id: 4, icon: Hammer, title: "Dron & GPS Monitoring Xizmati", desc: "Dala maydonlari va hayvonlar yaylovlarini sun'iy yo'ldosh va dron kameralari orqali 24/7 kuzatib borish.", status: "Tez kunda" },
];

const ServicesPage = () => {
  return (
    <div className="min-h-screen bg-gray-50/40 dark:bg-slate-950 p-6 md:p-12 transition-all duration-300">
      <div className="max-w-6xl mx-auto space-y-8 animate-in fade-in duration-300">
        
        {/* Banner */}
        <div className="relative overflow-hidden p-8 md:p-10 border border-emerald-500/10 dark:border-slate-800 bg-gradient-to-br from-slate-900 via-slate-950 to-primary-950 text-white rounded-[32px] shadow-xl">
          <div className="absolute top-0 right-0 w-80 h-80 bg-primary-500/10 rounded-full blur-3xl -z-10" />
          <h1 className="text-2xl md:text-4xl font-black text-white tracking-tight flex items-center gap-2">
            <Award className="text-primary-400" />
            <span>Qo'shimcha Xizmatlar</span>
          </h1>
          <p className="text-gray-305 text-xs md:text-sm mt-2 max-w-2xl leading-relaxed">
            Platformamiz orqali fermer xo'jaliklari va sarmoyadorlarga qulaylik yaratuvchi veterinariya, huquqiy yordam, sug'urtalash va avtomatlashtirilgan dron monitoring xizmatlari.
          </p>
        </div>

        {/* Services grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {SERVICES.map((srv) => {
            const Icon = srv.icon;
            return (
              <div key={srv.id} className="bg-white dark:bg-slate-900 p-6 rounded-[28px] border border-gray-150/60 dark:border-slate-800/80 shadow-sm flex gap-4 hover:shadow-md transition duration-300">
                <span className="w-12 h-12 rounded-2xl bg-primary-50 dark:bg-primary-950/40 text-primary-600 dark:text-primary-400 flex items-center justify-center shrink-0 shadow-inner border border-primary-100/10">
                  <Icon size={22} />
                </span>
                
                <div className="space-y-2">
                  <div className="flex justify-between items-center gap-2">
                    <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-sm md:text-base leading-tight">
                      {srv.title}
                    </h3>
                    <span className={`px-2 py-0.5 rounded-full text-[9px] font-black shrink-0 ${
                      srv.status === 'Faol' 
                        ? 'bg-emerald-50 dark:bg-emerald-950/30 text-emerald-700 dark:text-emerald-450 border border-emerald-200/25' 
                        : 'bg-gray-100 dark:bg-slate-800 text-gray-400 dark:text-slate-500'
                    }`}>
                      {srv.status}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500 dark:text-slate-400 leading-relaxed">{srv.desc}</p>
                </div>
              </div>
            );
          })}
        </div>

      </div>
    </div>
  );
};

export default ServicesPage;
