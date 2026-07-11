import React, { useEffect, useState } from 'react';
import { Inbox, FileText, CheckCircle2, AlertCircle } from 'lucide-react';
import { getProjectReports } from '../../api/reports.api';
import { formatDate } from '../../utils/format';

const REPORT_TYPE_LABEL = {
  GROWTH: "O'sish hisoboti",
  DAILY: 'Kunlik hisobot',
  VERIFICATION: 'Dala tekshiruvi',
};

// Aggregated feed of the latest reports from every project the investor is
// funded in. Owns its fetch: one request per distinct project, merged and
// sorted client-side (there is no cross-project reports endpoint for investors).
const ReportsTimelineTab = ({ investments }) => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (investments.length === 0) return;
    let cancelled = false;

    const fetchAll = async () => {
      setLoading(true);
      try {
        const projectIds = [...new Set(investments.map((inv) => inv.projectId))];
        const results = await Promise.all(projectIds.map(async (projectId) => {
          try {
            const res = await getProjectReports(projectId, 0, 5);
            const project = investments.find((inv) => inv.projectId === projectId);
            return (res.data.content || []).map((rep) => ({
              ...rep,
              projectTitle: project?.projectTitle || "Noma'lum loyiha",
            }));
          } catch {
            return [];
          }
        }));
        if (!cancelled) {
          setReports(results.flat().sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    fetchAll();
    return () => { cancelled = true; };
  }, [investments]);

  return (
    <div className="bg-white dark:bg-slate-900 p-6 rounded-3xl border border-gray-150/50 dark:border-slate-800/80 shadow-sm space-y-6 animate-in fade-in duration-300">
      <div>
        <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-base">Sarmoyalaringiz bo'yicha hisobotlar</h3>
        <p className="text-xs text-gray-450 dark:text-slate-500 mt-0.5">Siz sarmoya kiritgan faol loyihalardan kelgan kunlik o'sish va veterinariya hisobotlari tasmasi</p>
      </div>

      {loading ? (
        <div className="flex flex-col items-center justify-center py-10 space-y-3">
          <div className="w-6 h-6 border-3 border-primary-500 border-t-transparent rounded-full animate-spin" />
          <p className="text-[11px] text-gray-450 dark:text-slate-500">Hisobotlar tahlil qilinmoqda...</p>
        </div>
      ) : reports.length === 0 ? (
        <div className="text-center py-10">
          <Inbox className="mx-auto text-gray-300 dark:text-slate-700" size={36} />
          <p className="text-xs text-gray-450 dark:text-slate-500 mt-2">Hozircha faol loyihalardan yangi hisobotlar kelib tushmagan</p>
        </div>
      ) : (
        <div className="flow-root">
          <ul className="-mb-8">
            {reports.map((report, idx) => (
              <li key={report.id}>
                <div className="relative pb-8">
                  {idx !== reports.length - 1 && (
                    <span className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-150 dark:bg-slate-800" aria-hidden="true" />
                  )}
                  <div className="relative flex space-x-3 items-start">
                    <div>
                      <span className="h-8 w-8 rounded-full bg-primary-100 dark:bg-primary-950/40 text-primary-700 dark:text-primary-400 flex items-center justify-center ring-8 ring-white dark:ring-slate-900">
                        <FileText size={14} />
                      </span>
                    </div>

                    <div className="flex-1 min-w-0 pt-0.5">
                      <div className="flex justify-between items-start gap-4">
                        <div>
                          <p className="text-xs font-bold text-gray-900 dark:text-slate-100">{report.projectTitle}</p>
                          <span className="inline-block mt-0.5 text-[10px] text-gray-450 dark:text-slate-500 font-semibold uppercase">
                            {REPORT_TYPE_LABEL[report.reportType] || 'Veterinar nazorati'}
                          </span>
                        </div>
                        <span className="text-[10px] text-gray-400 dark:text-slate-500 font-bold shrink-0">{formatDate(report.createdAt)}</span>
                      </div>

                      <p className="text-xs text-gray-600 dark:text-slate-350 leading-relaxed mt-2 p-3 bg-gray-50 dark:bg-slate-950/50 rounded-xl border border-gray-100 dark:border-slate-950">
                        {report.content}
                      </p>

                      {report.mediaUrls && report.mediaUrls.length > 0 && (
                        <div className="grid grid-cols-3 gap-2 mt-2">
                          {report.mediaUrls.map((m, mIdx) => (
                            <img key={mIdx} src={m} alt="Hisobot rasmi" className="w-full h-16 object-cover rounded-lg border border-gray-150 dark:border-slate-800" />
                          ))}
                        </div>
                      )}

                      <div className="flex items-center gap-1.5 mt-2">
                        {report.verified ? (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-50 dark:bg-emerald-950/30 text-emerald-700 dark:text-emerald-400 text-[9px] font-bold border border-emerald-200/20">
                            <CheckCircle2 size={10} /> Tasdiqlangan
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-amber-50 dark:bg-amber-950/30 text-amber-700 dark:text-amber-400 text-[9px] font-bold border border-amber-250/20">
                            <AlertCircle size={10} /> Tekshiruvda
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

export default ReportsTimelineTab;
