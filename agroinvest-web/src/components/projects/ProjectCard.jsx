import React from 'react';
import { Link } from 'react-router-dom';
import Badge from '../ui/Badge';
import { formatAmount } from '../../utils/format';
import { getAssetTypeMeta } from '../../utils/assetType';
import { MapPin, Calendar, ArrowUpRight, Shield, Award } from 'lucide-react';

const ProjectCard = ({ project }) => {
  const {
    id,
    title,
    description,
    riskLevel,
    targetAmount,
    raisedAmount,
    expectedReturnPct,
    durationDays,
    status,
    farmerName,
    assetType,
    region,
  } = project;

  const meta = getAssetTypeMeta(assetType);
  const Icon = meta.icon;

  const percent = Math.min(
    100,
    Math.round((raisedAmount / targetAmount) * 100)
  );

  return (
    <div className="bg-white dark:bg-slate-900 rounded-[24px] border border-gray-150/60 dark:border-slate-800/80 shadow-sm hover:shadow-md dark:hover:border-slate-700/60 transition-all duration-300 overflow-hidden flex flex-col justify-between group">
      
      {/* Upper Content Area */}
      <div className="p-6 space-y-4">
        
        {/* Category Icon and Status/Risk Badges */}
        <div className="flex justify-between items-center gap-2">
          <span 
            className="w-10 h-10 rounded-xl flex items-center justify-center shadow-sm border border-gray-150/30 dark:border-slate-800" 
            style={{ backgroundColor: meta.color + '12', color: meta.color }}
          >
            <Icon size={18} />
          </span>
          <div className="flex items-center gap-1.5">
            <Badge status={riskLevel || 'MEDIUM'} />
            <Badge status={status} />
          </div>
        </div>

        {/* Title and Farmer */}
        <div>
          <h3 className="text-base font-extrabold text-gray-950 dark:text-slate-100 line-clamp-1 group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">
            {title}
          </h3>
          <p className="text-[11px] font-bold text-gray-400 dark:text-slate-500 mt-1 flex items-center gap-1">
            <Award size={12} className="text-primary-500/80" />
            <span>Fermer: {farmerName}</span>
            {region && (
              <>
                <span className="text-gray-300 dark:text-slate-700">•</span>
                <span className="flex items-center gap-0.5"><MapPin size={11} />{region}</span>
              </>
            )}
          </p>
        </div>

        {/* Description */}
        <p className="text-xs text-gray-500 dark:text-slate-400 line-clamp-2 h-9 leading-relaxed">
          {description}
        </p>

        {/* Financial info blocks */}
        <div className="grid grid-cols-2 gap-3.5 p-3 rounded-2xl bg-gray-50 dark:bg-slate-950/60 border border-gray-100 dark:border-slate-950 text-xs">
          <div>
            <span className="text-[10px] text-gray-400 font-semibold uppercase tracking-wider block">Maqsad summa</span>
            <p className="font-black text-[13px] text-gray-950 dark:text-slate-100 mt-0.5">{formatAmount(targetAmount)}</p>
          </div>
          <div>
            <span className="text-[10px] text-gray-400 font-semibold uppercase tracking-wider block">Kutilayotgan foyda</span>
            <p className="font-black text-[13px] text-emerald-600 dark:text-emerald-400 mt-0.5 flex items-center gap-0.5">
              <ArrowUpRight size={14} />+{expectedReturnPct}%
            </p>
          </div>
        </div>

        {/* Progress bar details */}
        <div className="space-y-1.5 pt-1">
          <div className="flex justify-between text-[11px] font-bold text-gray-500 dark:text-slate-400">
            <span>{percent}% yig'ildi</span>
            <span className="text-gray-950 dark:text-slate-150">{formatAmount(raisedAmount)}</span>
          </div>
          <div className="w-full bg-gray-100 dark:bg-slate-800 h-1.5 rounded-full overflow-hidden">
            <div
              className="bg-primary-600 h-full rounded-full transition-all duration-300"
              style={{ width: `${percent}%` }}
            />
          </div>
          <div className="flex justify-between text-[10px] text-gray-400 dark:text-slate-500 pt-0.5">
            <span className="flex items-center gap-1"><Calendar size={11} />Muddati: {durationDays} kun</span>
          </div>
        </div>

      </div>

      {/* Button CTA Link */}
      <div className="px-6 pb-6 pt-0">
        <Link
          to={`/projects/${id}`}
          className="flex items-center justify-center gap-1.5 w-full py-3 bg-gray-50 dark:bg-slate-950 hover:bg-primary-600 dark:hover:bg-primary-650 hover:text-white dark:hover:text-white text-primary-700 dark:text-primary-400 font-bold text-xs rounded-xl border border-primary-200/40 dark:border-slate-800/80 hover:border-transparent transition-all duration-200"
        >
          <span>Tafsilotlarni ko'rish</span>
          <ArrowUpRight size={14} />
        </Link>
      </div>

    </div>
  );
};

export default ProjectCard;
