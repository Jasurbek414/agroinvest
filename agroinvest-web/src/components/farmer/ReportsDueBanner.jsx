import React from 'react';
import { AlertCircle, Send } from 'lucide-react';

// Actionable version of the old "Bugun hisobot kerak" stat: lists exactly
// which ACTIVE projects still owe today's daily log (stats.projects[].reportDue
// from GET /dashboard/me) and opens the report modal right from the banner.
const ReportsDueBanner = ({ stats, onReportClick }) => {
  const dueProjects = (stats?.projects || []).filter((p) => p.reportDue);
  if (dueProjects.length === 0) return null;

  return (
    <div className="bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-900 rounded-3xl p-5 space-y-3 animate-in fade-in duration-300">
      <div className="flex items-center gap-2">
        <AlertCircle size={18} className="text-amber-600 dark:text-amber-400 shrink-0" />
        <div>
          <h3 className="text-sm font-extrabold text-amber-900 dark:text-amber-200">
            Bugun {dueProjects.length} ta loyihaga kunlik hisobot yuborilmagan
          </h3>
          <p className="text-[11px] text-amber-700/80 dark:text-amber-400/80 font-semibold mt-0.5">
            Muntazam hisobotlar investorlar ishonchini oshiradi va loyiha reytingiga ta'sir qiladi
          </p>
        </div>
      </div>

      <div className="flex flex-wrap gap-2">
        {dueProjects.map((p) => (
          <button
            key={p.id}
            onClick={() => onReportClick(p.id)}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 bg-white dark:bg-slate-900 border border-amber-300 dark:border-amber-800 text-amber-800 dark:text-amber-300 text-xs font-bold rounded-xl hover:bg-amber-100 dark:hover:bg-amber-950/60 transition duration-200"
          >
            <Send size={12} />
            <span className="max-w-[180px] truncate">{p.title}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

export default ReportsDueBanner;
