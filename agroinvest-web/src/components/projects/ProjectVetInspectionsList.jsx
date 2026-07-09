import React, { useEffect, useState } from 'react';
import { HeartPulse } from 'lucide-react';
import { getProjectVetInspections } from '../../api/vet.api';
import EmptyState from '../ui/EmptyState';
import Badge from '../ui/Badge';
import { formatDate } from '../../utils/format';

// VERIFIED inspections are a public trust signal - visible to any visitor,
// including guests deciding whether to invest (server-side filters
// PENDING/REJECTED to the owner + staff only, so what renders here for a
// regular investor/guest is always already-verified).
const ProjectVetInspectionsList = ({ projectId }) => {
  const [inspections, setInspections] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const res = await getProjectVetInspections(projectId);
        setInspections(res.data || []);
      } catch {
        setInspections([]);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [projectId]);

  if (loading) {
    return <p className="text-sm text-gray-400 dark:text-slate-500 animate-pulse">Yuklanmoqda...</p>;
  }

  if (inspections.length === 0) {
    return <EmptyState icon={HeartPulse} title="Hali veterinar tekshiruvi yo'q" />;
  }

  return (
    <div className="space-y-3">
      {inspections.map((v) => (
        <div key={v.id} className="border border-gray-100 dark:border-slate-700 rounded-2xl p-4">
          <div className="flex justify-between items-start gap-3 mb-1.5">
            <span className="text-xs font-bold text-gray-700 dark:text-slate-300">{v.vetName}{v.vetLicenseNo ? ` (${v.vetLicenseNo})` : ''}</span>
            <Badge status={v.healthStatus} />
          </div>
          <p className="text-[11px] text-gray-400 dark:text-slate-500">{formatDate(v.inspectionDate)}</p>
          {v.conclusion && <p className="text-xs text-gray-500 dark:text-slate-400 mt-1.5">{v.conclusion}</p>}
          {v.status === 'VERIFIED' && (
            <p className="text-[11px] text-primary-600 dark:text-primary-400 font-bold mt-2">Admin tomonidan tasdiqlangan ✓</p>
          )}
        </div>
      ))}
    </div>
  );
};

export default ProjectVetInspectionsList;
