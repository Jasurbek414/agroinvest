import React from 'react';
import { Inbox, FileText, Receipt, ShieldAlert, Award, Calendar, ArrowUpRight } from 'lucide-react';
import Badge from '../ui/Badge';
import EmptyState from '../ui/EmptyState';
import { formatAmount } from '../../utils/format';
import { getAssetTypeMeta } from '../../utils/assetType';

const ProjectListTab = ({ projects, loading, onCreateClick, onReportClick, onExpenseClick, onVetClick }) => {
  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-20 space-y-3">
        <div className="w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin" />
        <p className="text-xs text-gray-500 dark:text-slate-400">Loyihalar yuklanmoqda...</p>
      </div>
    );
  }

  if (projects.length === 0) {
    return (
      <EmptyState
        icon={Inbox}
        title="Sizda hali loyihalar mavjud emas"
        action={
          <button
            onClick={onCreateClick}
            className="px-5 py-2.5 bg-primary-600 hover:bg-primary-500 text-white text-xs font-bold rounded-xl transition shadow-md shadow-primary-600/10"
          >
            Birinchi loyihangizni qo'shing
          </button>
        }
      />
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {projects.map((p) => {
        const raised = p.raisedAmount || 0;
        const target = p.targetAmount || 1;
        const percent = Math.min(100, Math.round((raised / target) * 100));
        const meta = getAssetTypeMeta(p.assetType);
        const Icon = meta.icon;

        return (
          <div key={p.id} className="bg-white dark:bg-slate-900 p-6 rounded-[24px] border border-gray-150/60 dark:border-slate-800/80 shadow-sm flex flex-col justify-between space-y-5 group hover:shadow-md transition duration-300">
            
            {/* Header section with Category & Status */}
            <div>
              <div className="flex justify-between items-center mb-3">
                <span 
                  className="px-2.5 py-1 rounded-lg text-[10px] font-bold flex items-center gap-1 border border-gray-150/20 shadow-inner"
                  style={{ backgroundColor: meta.color + '10', color: meta.color }}
                >
                  <Icon size={12} />
                  <span>{meta.label}</span>
                </span>
                <Badge status={p.status} />
              </div>
              <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base leading-tight group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">
                {p.title}
              </h3>
              <p className="text-gray-500 dark:text-slate-400 text-xs mt-1.5 line-clamp-2 leading-relaxed">
                {p.description}
              </p>
            </div>

            {/* Financial indicators and Progress */}
            <div className="space-y-3 pt-1">
              <div className="w-full bg-gray-100 dark:bg-slate-800 h-1.5 rounded-full overflow-hidden">
                <div 
                  className="bg-primary-600 h-full rounded-full transition-all duration-300" 
                  style={{ width: `${percent}%` }} 
                />
              </div>
              
              <div className="flex justify-between items-center text-[11px] font-bold text-gray-400 dark:text-slate-550">
                <span>{percent}% yig'ildi</span>
                <span className="text-gray-800 dark:text-slate-200">
                  {formatAmount(raised)} <span className="text-gray-300 dark:text-slate-700">/</span> {formatAmount(target)}
                </span>
              </div>
            </div>

            {/* Action buttons (only if ACTIVE or FUNDING) */}
            {(p.status === 'ACTIVE' || p.status === 'FUNDING') ? (
              <div className="grid grid-cols-3 gap-2.5 pt-2 border-t border-gray-100 dark:border-slate-800/80">
                <button
                  onClick={() => onReportClick(p.id)}
                  className="flex flex-col items-center justify-center py-2 px-1 bg-yellow-50/50 dark:bg-yellow-950/20 hover:bg-yellow-100 dark:hover:bg-yellow-950/40 border border-yellow-250/20 dark:border-yellow-900/30 text-yellow-800 dark:text-yellow-400 text-[10px] font-bold rounded-xl transition duration-200 gap-1"
                >
                  <FileText size={14} />
                  <span>Kunlik hisobot</span>
                </button>
                
                <button
                  onClick={() => onExpenseClick(p.id, p.expensePolicy)}
                  className="flex flex-col items-center justify-center py-2 px-1 bg-blue-50/50 dark:bg-blue-950/20 hover:bg-blue-100 dark:hover:bg-blue-950/40 border border-blue-250/20 dark:border-blue-900/30 text-blue-800 dark:text-blue-400 text-[10px] font-bold rounded-xl transition duration-200 gap-1"
                >
                  <Receipt size={14} />
                  <span>Xarajat qaydi</span>
                </button>
                
                <button
                  onClick={() => onVetClick(p.id)}
                  className="flex flex-col items-center justify-center py-2 px-1 bg-purple-50/50 dark:bg-purple-950/20 hover:bg-purple-100 dark:hover:bg-purple-950/40 border border-purple-250/20 dark:border-purple-900/30 text-purple-800 dark:text-purple-400 text-[10px] font-bold rounded-xl transition duration-200 gap-1"
                >
                  <ShieldAlert size={14} />
                  <span>Vet hujjat</span>
                </button>
              </div>
            ) : (
              <div className="pt-2 border-t border-gray-100 dark:border-slate-800/80 text-center">
                <span className="text-[10px] font-bold text-gray-450 dark:text-slate-500 uppercase tracking-wider block">
                  Ariza tekshiruv jarayonida
                </span>
              </div>
            )}
            
          </div>
        );
      })}
    </div>
  );
};

export default ProjectListTab;
