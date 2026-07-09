import React from 'react';
import { AlertTriangle, ShieldAlert, ShieldCheck, ShieldQuestion } from 'lucide-react';

// TZ §8.3 "Halokat siyosati": every project page must show its risk level with
// an explanation of what that level means, plus the mandated "no guaranteed
// return" disclaimer. Previously only the short generic disclaimer existed
// (in the sidebar) with no explanation of what LOW/MEDIUM/HIGH actually means.
const RISK_INFO = {
  LOW: {
    label: 'Past xavfli loyiha',
    icon: ShieldCheck,
    tone: 'text-blue-700 dark:text-blue-400 bg-blue-50 dark:bg-blue-950 border-blue-100 dark:border-blue-900',
    desc: "Barqaror tajribaga ega fermer, sinovdan o'tgan aktiv turi va qisqa/o'rtacha muddat. Baribir tabiiy xavflar (kasallik, ob-havo) butunlay yo'qolmaydi.",
  },
  MEDIUM: {
    label: "O'rtacha xavfli loyiha",
    icon: ShieldQuestion,
    tone: 'text-amber-700 dark:text-amber-400 bg-amber-50 dark:bg-amber-950/40 border-amber-100 dark:border-amber-900',
    desc: "Odatiy chorvachilik/dehqonchilik xavflari (kasallik, narx tebranishi, ob-havo) mavjud. Fermerning tajribasi va hisobot intizomi kuzatib boriladi.",
  },
  HIGH: {
    label: 'Yuqori xavfli loyiha',
    icon: ShieldAlert,
    tone: 'text-red-700 dark:text-red-400 bg-red-50 dark:bg-red-950 border-red-100 dark:border-red-900',
    desc: "Yangi fermer, uzoq muddat yoki sinov aktiv turi. Yo'qotish ehtimoli sezilarli darajada yuqori — faqat yo'qotishga tayyor mablag'ni kiriting.",
  },
};

const RiskDisclosure = ({ riskLevel }) => {
  const info = RISK_INFO[riskLevel] || RISK_INFO.MEDIUM;
  const Icon = info.icon;

  return (
    <div className={`rounded-2xl border p-4 space-y-3 ${info.tone}`}>
      <div className="flex items-center gap-2">
        <Icon size={18} />
        <span className="font-bold text-sm">{info.label}</span>
      </div>
      <p className="text-xs leading-relaxed opacity-90">{info.desc}</p>
      <div className="flex items-start gap-2 pt-2 border-t border-current/20">
        <AlertTriangle size={16} className="shrink-0 mt-0.5" />
        <p className="text-xs leading-relaxed font-semibold">
          Kafolatlangan daromad yo'q — bu KUTILAYOTGAN daromad. Zarar yuzaga kelsa: veterinar/agronom xulosasi va foto-dalil
          yuklanadi, admin tekshiradi, zaxira fond hisobidan qoplash imkoniyati ko'riladi va barcha investorlarga xabar beriladi.
        </p>
      </div>
    </div>
  );
};

export default RiskDisclosure;
