import React from 'react';
import { Link } from 'react-router-dom';
import Badge from '../ui/Badge';
import { formatAmount } from '../../utils/format';

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
  } = project;

  const percent = Math.min(
    100,
    Math.round((raisedAmount / targetAmount) * 100)
  );

  return (
    <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm hover:shadow-md transition duration-200 overflow-hidden flex flex-col justify-between">
      <div className="p-6">
        <div className="flex justify-between items-center gap-2 mb-4">
          <Badge status={riskLevel} />
          <Badge status={status} />
        </div>

        <h3 className="text-lg font-bold text-gray-900 dark:text-slate-100 line-clamp-1 mb-1">{title}</h3>
        <p className="text-xs text-gray-400 dark:text-slate-500 mb-3">Fermer: {farmerName}</p>
        <p className="text-sm text-gray-500 dark:text-slate-400 line-clamp-2 mb-4 h-10">{description}</p>

        <div className="grid grid-cols-2 gap-4 mb-4 bg-gray-50 dark:bg-slate-900/60 p-3 rounded-xl text-center">
          <div>
            <p className="text-xs text-gray-400 dark:text-slate-500">Daromadlilik</p>
            <p className="text-base font-extrabold text-primary-600 dark:text-primary-400">+{expectedReturnPct}%</p>
          </div>
          <div>
            <p className="text-xs text-gray-400 dark:text-slate-500">Muddati</p>
            <p className="text-base font-bold text-gray-800 dark:text-slate-200">{durationDays} kun</p>
          </div>
        </div>

        {/* Progress Bar */}
        <div>
          <div className="flex justify-between text-xs font-semibold text-gray-500 dark:text-slate-400 mb-1.5">
            <span>{percent}% yig'ildi</span>
            <span className="text-gray-900 dark:text-slate-100">{formatAmount(raisedAmount)}</span>
          </div>
          <div className="w-full bg-gray-100 dark:bg-slate-700 h-2 rounded-full overflow-hidden">
            <div
              className="bg-primary-600 h-full rounded-full transition-all duration-300"
              style={{ width: `${percent}%` }}
            />
          </div>
          <div className="flex justify-between text-[11px] text-gray-400 dark:text-slate-500 mt-1">
            <span>Maqsad: {formatAmount(targetAmount)}</span>
          </div>
        </div>
      </div>

      <div className="p-6 pt-0">
        <Link
          to={`/projects/${id}`}
          className="block w-full py-2.5 text-center bg-gray-50 dark:bg-slate-900/60 hover:bg-primary-600 hover:text-white text-primary-700 dark:text-primary-400 font-semibold rounded-xl border border-primary-200/50 dark:border-primary-900 hover:border-transparent transition"
        >
          Tafsilotlar
        </Link>
      </div>
    </div>
  );
};

export default ProjectCard;
