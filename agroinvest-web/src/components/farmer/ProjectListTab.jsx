import React from 'react';
import { Inbox } from 'lucide-react';
import Badge from '../ui/Badge';
import EmptyState from '../ui/EmptyState';
import { formatAmount } from '../../utils/format';

const ProjectListTab = ({ projects, loading, onCreateClick, onReportClick, onExpenseClick, onVetClick }) => {
  if (loading) {
    return <p className="text-gray-500 animate-pulse text-center">Yuklanmoqda...</p>;
  }

  if (projects.length === 0) {
    return (
      <EmptyState
        icon={Inbox}
        title="Sizda hali loyihalar mavjud emas"
        action={
          <button
            onClick={onCreateClick}
            className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white text-xs font-bold rounded-xl transition"
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

        return (
          <div key={p.id} className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col justify-between space-y-4">
            <div>
              <div className="flex justify-between items-center mb-3">
                <span className="text-[10px] font-bold text-green-700 uppercase bg-green-50 px-2 py-0.5 rounded">
                  {p.assetType}
                </span>
                <Badge status={p.status} />
              </div>
              <h3 className="font-bold text-gray-900 text-base">{p.title}</h3>
              <p className="text-gray-500 text-xs mt-1.5 line-clamp-2">{p.description}</p>
            </div>

            <div className="space-y-3 pt-2">
              <div className="w-full bg-gray-100 h-1.5 rounded-full overflow-hidden">
                <div className="bg-green-600 h-full rounded-full" style={{ width: `${percent}%` }} />
              </div>
              <div className="flex justify-between items-center text-[11px] font-bold text-gray-400">
                <span>{percent}% yig'ildi</span>
                <span className="text-gray-800">{formatAmount(raised)} / {formatAmount(target)}</span>
              </div>
            </div>

            {(p.status === 'ACTIVE' || p.status === 'FUNDING') && (
              <div className="grid grid-cols-3 gap-2">
                <button
                  onClick={() => onReportClick(p.id)}
                  className="py-2 bg-yellow-50 hover:bg-yellow-100 border border-yellow-200 text-yellow-800 text-[11px] font-bold rounded-xl transition"
                >
                  Hisobot
                </button>
                <button
                  onClick={() => onExpenseClick(p.id, p.expensePolicy)}
                  className="py-2 bg-blue-50 hover:bg-blue-100 border border-blue-200 text-blue-800 text-[11px] font-bold rounded-xl transition"
                >
                  Harajat
                </button>
                <button
                  onClick={() => onVetClick(p.id)}
                  className="py-2 bg-purple-50 hover:bg-purple-100 border border-purple-200 text-purple-800 text-[11px] font-bold rounded-xl transition"
                >
                  Vet hujjat
                </button>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
};

export default ProjectListTab;
