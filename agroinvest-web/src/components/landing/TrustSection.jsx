import React from 'react';
import { ShieldCheck, AlertTriangle, FileCheck2, Scale } from 'lucide-react';

const TRUST_ITEMS = [
  { icon: ShieldCheck, title: 'KYC tekshiruvi', desc: "Har bir fermer va investor pasport ma'lumotlari admin tomonidan qo'lda tasdiqlanadi" },
  { icon: FileCheck2, title: "Shaffof hisobot", desc: "Fermer muntazam foto/video hisobot yuboradi, barcha xarajatlar ochiq ko'rinadi" },
  { icon: Scale, title: 'Nizolarni hal qilish', desc: "Kelishmovchilik yuzaga kelsa, platforma admin jamoasi ishni ko'rib chiqadi" },
];

// TZ §8.3 "Halokat siyosati" - mandated on every project page AND, per this
// session's landing-page work, surfaced up-front here too: every visitor should
// see the risk/no-guarantee disclosure before they ever reach a project page.
const TrustSection = () => {
  return (
    <section className="max-w-6xl mx-auto px-6 py-16 md:py-24">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
        {TRUST_ITEMS.map((item) => (
          <div key={item.title} className="text-center">
            <span className="inline-flex w-12 h-12 rounded-2xl bg-primary-50 dark:bg-primary-950 text-primary-600 dark:text-primary-400 items-center justify-center mb-4">
              <item.icon size={22} />
            </span>
            <h3 className="font-bold text-gray-900 dark:text-slate-100">{item.title}</h3>
            <p className="text-sm text-gray-500 dark:text-slate-400 mt-1.5">{item.desc}</p>
          </div>
        ))}
      </div>

      <div className="max-w-3xl mx-auto bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-900 rounded-2xl p-6 flex gap-4">
        <AlertTriangle size={22} className="text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
        <div>
          <p className="font-bold text-amber-800 dark:text-amber-300 text-sm">Kafolatlangan daromad yo'q</p>
          <p className="text-sm text-amber-700 dark:text-amber-400 mt-1">
            Har bir loyihada ko'rsatilgan foyda foizi — bu <strong>kutilayotgan</strong>, kafolatlangan emas, daromad.
            Chorvachilik va dehqonchilik tabiiy xavflarga (kasallik, ob-havo va h.k.) ega. Har bir loyihaning xavf darajasi
            (Past/O'rtacha/Yuqori) sahifasida aniq ko'rsatiladi — sarmoya kiritishdan oldin uni albatta o'qib chiqing.
          </p>
        </div>
      </div>
    </section>
  );
};

export default TrustSection;
