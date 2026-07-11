import React from 'react';
import { BadgeDollarSign, User, Phone, Calendar, ArrowRight, ShieldCheck, Briefcase } from 'lucide-react';
import { formatAmount, formatDate } from '../../utils/format';

const CoopOfferCard = ({ offer, onAction, actionLabel }) => {
  const getOfferTypeLabel = (type) => {
    switch (type) {
      case 'CONTRACT_SALE': return 'Tayyor shartnoma savdosi';
      case 'INVESTOR_OFFER': return 'Investor sarmoya taklifi';
      case 'BUSINESS_PLAN': return 'Biznes reja / Tashabbus';
      default: return type;
    }
  };

  const getOfferTypeColor = (type) => {
    switch (type) {
      case 'CONTRACT_SALE': return 'bg-blue-50 text-blue-700 border-blue-200/20 dark:bg-blue-950/40 dark:text-blue-400';
      case 'INVESTOR_OFFER': return 'bg-emerald-50 text-emerald-700 border-emerald-200/20 dark:bg-emerald-950/40 dark:text-emerald-450';
      case 'BUSINESS_PLAN': return 'bg-purple-50 text-purple-700 border-purple-200/20 dark:bg-purple-950/40 dark:text-purple-400';
      default: return 'bg-gray-50 text-gray-700';
    }
  };

  return (
    <div className="bg-white dark:bg-slate-900 p-5 rounded-[28px] border border-gray-150/60 dark:border-slate-800/80 shadow-sm flex flex-col justify-between hover:shadow-md hover:border-gray-200 dark:hover:border-slate-750 transition-all duration-300 group">
      <div>
        <div className="flex justify-between items-start gap-2">
          <span className={`px-2.5 py-0.5 rounded-lg text-[10px] font-bold border ${getOfferTypeColor(offer.type)}`}>
            {getOfferTypeLabel(offer.type)}
          </span>
          <span className="text-[10px] text-gray-400 font-semibold flex items-center gap-1">
            <Calendar size={11} />
            {formatDate(offer.createdAt)}
          </span>
        </div>

        <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-sm mt-3.5 leading-tight group-hover:text-primary-650 dark:group-hover:text-primary-400 transition-colors">
          {offer.title}
        </h3>
        <p className="text-xs text-gray-500 dark:text-slate-400 mt-2 line-clamp-3 leading-relaxed">
          {offer.description}
        </p>
      </div>

      <div className="mt-5 pt-4 border-t border-gray-100 dark:border-slate-800/60 space-y-4">
        
        <div className="grid grid-cols-2 gap-2 text-[11px]">
          <div className="space-y-1">
            <span className="text-gray-400 block font-bold">Joylovchi:</span>
            <span className="font-extrabold text-gray-900 dark:text-slate-200 flex items-center gap-1">
              <User size={12} className="text-gray-400" />
              {offer.creatorName}
            </span>
          </div>
          <div className="space-y-1">
            <span className="text-gray-400 block font-bold">Aloqa uchun:</span>
            <span className="font-extrabold text-gray-900 dark:text-slate-200 flex items-center gap-1">
              <Phone size={12} className="text-gray-400" />
              {offer.contactPhone}
            </span>
          </div>
        </div>

        <div className="flex justify-between items-center bg-gray-50/50 dark:bg-slate-950/40 p-3 rounded-xl border border-gray-100/10">
          <div>
            <span className="text-[10px] text-gray-400 dark:text-slate-500 font-bold block uppercase tracking-wide">Talab qilinadigan mablag'</span>
            <span className="font-black text-sm text-gray-950 dark:text-slate-100 block mt-0.5">
              {formatAmount(offer.amount)}
            </span>
          </div>
          
          {onAction ? (
            <button
              onClick={() => onAction(offer)}
              className="px-3.5 py-2 bg-primary-600 hover:bg-primary-500 text-white font-extrabold text-[10px] uppercase tracking-wide rounded-lg shadow-sm flex items-center gap-1 transition"
            >
              <span>{actionLabel || "Ko'rish"}</span>
              <ArrowRight size={11} />
            </button>
          ) : (
            <a
              href={`tel:${offer.contactPhone}`}
              className="px-3.5 py-2 bg-gray-100 hover:bg-primary-600 text-gray-700 hover:text-white dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-primary-600 font-bold text-xs rounded-xl transition flex items-center gap-1"
            >
              <Phone size={13} />
              <span>Bog'lanish</span>
            </a>
          )}
        </div>

      </div>
    </div>
  );
};

export default CoopOfferCard;
