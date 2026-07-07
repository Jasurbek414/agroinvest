import React from 'react';
import { Scale } from 'lucide-react';
import Card from '../ui/Card';
import Badge from '../ui/Badge';
import EmptyState from '../ui/EmptyState';
import { formatDate } from '../../utils/format';

const DISPUTE_TYPE_LABELS = {
  PROJECT_ABANDONED: "Loyiha e'tiborsiz qoldirilgan",
  NO_REPORTS: 'Hisobotlar yuborilmayapti',
  FUNDS_MISUSE: "Mablag' noto'g'ri ishlatilgan",
  PAYOUT_DELAY: "To'lov kechikmoqda",
  OTHER: 'Boshqa',
};

const DisputeList = ({ disputes, showParties = false }) => {
  if (!disputes || disputes.length === 0) {
    return <EmptyState icon={Scale} title='Shikoyatlar topilmadi' />;
  }

  return (
    <div className="space-y-4">
      {disputes.map((d) => (
        <Card key={d.id} className="space-y-3">
          <div className="flex justify-between items-start gap-4">
            <div>
              <p className="font-bold text-gray-900 dark:text-slate-100">{d.projectTitle}</p>
              <p className="text-xs text-gray-400 dark:text-slate-500 mt-0.5">{DISPUTE_TYPE_LABELS[d.disputeType] || d.disputeType}</p>
            </div>
            <Badge status={d.status} />
          </div>

          {showParties && (
            <p className="text-xs text-gray-500 dark:text-slate-400">
              <span className="font-semibold">{d.filedByName}</span> tomonidan <span className="font-semibold">{d.againstUserName}</span> ustidan
            </p>
          )}

          <p className="text-sm text-gray-600 dark:text-slate-300">{d.description}</p>

          {d.resolution && (
            <div className="bg-green-50 dark:bg-green-950 border border-green-100 dark:border-green-900 rounded-xl p-3">
              <p className="text-xs font-bold text-green-700 dark:text-green-300 mb-1">Yechim:</p>
              <p className="text-sm text-green-800 dark:text-green-200">{d.resolution}</p>
            </div>
          )}

          <p className="text-[11px] text-gray-400 dark:text-slate-500">{formatDate(d.createdAt)}</p>
        </Card>
      ))}
    </div>
  );
};

export default DisputeList;
