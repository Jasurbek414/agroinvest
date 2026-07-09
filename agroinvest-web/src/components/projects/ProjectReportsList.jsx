import React, { useEffect, useState } from 'react';
import { ClipboardList } from 'lucide-react';
import { getProjectReports } from '../../api/reports.api';
import EmptyState from '../ui/EmptyState';
import { formatDate } from '../../utils/format';

const REPORT_TYPE_LABELS = {
  ROUTINE: 'Muntazam',
  EMERGENCY: 'Favqulodda',
  VERIFICATION: 'Tekshiruv',
  FINAL: 'Yakuniy',
  COMPLETION: 'Yakunlash',
};

// Lets an investor see the farmer's own progress updates for a project they funded -
// previously these were only visible to admins reviewing the verification queue.
const ProjectReportsList = ({ projectId }) => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const res = await getProjectReports(projectId);
        setReports(res.data.content || []);
      } catch {
        setReports([]);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [projectId]);

  if (loading) {
    return <p className="text-sm text-gray-400 dark:text-slate-500 animate-pulse">Yuklanmoqda...</p>;
  }

  if (reports.length === 0) {
    return <EmptyState icon={ClipboardList} title="Hali progress hisobotlari yo'q" />;
  }

  return (
    <div className="space-y-4">
      {reports.map((r) => (
        <div key={r.id} className="border border-gray-100 dark:border-slate-700 rounded-2xl p-5">
          <div className="flex justify-between items-start gap-3 mb-2">
            <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded-full ${
              r.reportType === 'EMERGENCY' ? 'bg-red-50 dark:bg-red-950 text-red-700 dark:text-red-300' : 'bg-blue-50 dark:bg-blue-950 text-blue-700 dark:text-blue-300'
            }`}>
              {REPORT_TYPE_LABELS[r.reportType] || r.reportType}
            </span>
            <span className="text-[11px] text-gray-400 dark:text-slate-500">{formatDate(r.createdAt)}</span>
          </div>
          <p className="text-sm text-gray-700 dark:text-slate-300">{r.notes}</p>
          {r.mediaUrls && r.mediaUrls.length > 0 && (
            <div className="grid grid-cols-3 gap-2 mt-3">
              {r.mediaUrls.map((url, i) => (
                <img key={i} src={url} alt={`Fermer hisobotidan rasm ${i + 1}`} className="rounded-lg h-20 w-full object-cover border border-gray-100 dark:border-slate-600" />
              ))}
            </div>
          )}
          {r.isVerified && (
            <p className="text-[11px] text-primary-600 dark:text-primary-400 font-bold mt-2">Admin tomonidan tasdiqlangan</p>
          )}
        </div>
      ))}
    </div>
  );
};

export default ProjectReportsList;
