import React from 'react';
import { Link } from 'react-router-dom';

const ProjectCard = ({ project }) => {
  const {
    id,
    title,
    description,
    assetType,
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

  const getRiskBadgeColor = (risk) => {
    switch (risk) {
      case 'LOW':
        return 'bg-blue-50 text-blue-700 border-blue-100';
      case 'MEDIUM':
        return 'bg-yellow-50 text-yellow-700 border-yellow-100';
      default:
        return 'bg-red-50 text-red-700 border-red-100';
    }
  };

  const getStatusBadgeColor = (pStatus) => {
    switch (pStatus) {
      case 'PENDING':
        return 'bg-gray-100 text-gray-700';
      case 'APPROVED':
        return 'bg-blue-100 text-blue-800';
      case 'FUNDING':
        return 'bg-green-100 text-green-800';
      case 'ACTIVE':
        return 'bg-purple-100 text-purple-800';
      case 'COMPLETED':
        return 'bg-teal-100 text-teal-800';
      default:
        return 'bg-red-100 text-red-800';
    }
  };

  const formatAmount = (num) => {
    return new Intl.NumberFormat('uz-UZ').format(num) + ' UZS';
  };

  return (
    <div className="bg-white rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition duration-200 overflow-hidden flex flex-col justify-between">
      <div className="p-6">
        <div className="flex justify-between items-center gap-2 mb-4">
          <span className={`text-xs px-2.5 py-1 font-semibold rounded-full border ${getRiskBadgeColor(riskLevel)}`}>
            {riskLevel} RISK
          </span>
          <span className={`text-xs px-2.5 py-1 font-semibold rounded-full ${getStatusBadgeColor(status)}`}>
            {status}
          </span>
        </div>

        <h3 className="text-lg font-bold text-gray-900 line-clamp-1 mb-1">{title}</h3>
        <p className="text-xs text-gray-400 mb-3">Fermer: {farmerName}</p>
        <p className="text-sm text-gray-500 line-clamp-2 mb-4 h-10">{description}</p>

        <div className="grid grid-cols-2 gap-4 mb-4 bg-gray-50 p-3 rounded-xl text-center">
          <div>
            <p className="text-xs text-gray-400">Daromadlilik</p>
            <p className="text-base font-extrabold text-green-600">+{expectedReturnPct}%</p>
          </div>
          <div>
            <p className="text-xs text-gray-400">Muddati</p>
            <p className="text-base font-bold text-gray-800">{durationDays} kun</p>
          </div>
        </div>

        {/* Progress Bar */}
        <div>
          <div className="flex justify-between text-xs font-semibold text-gray-500 mb-1.5">
            <span>{percent}% yig'ildi</span>
            <span className="text-gray-900">{formatAmount(raisedAmount)}</span>
          </div>
          <div className="w-full bg-gray-100 h-2 rounded-full overflow-hidden">
            <div
              className="bg-green-600 h-full rounded-full transition-all duration-300"
              style={{ width: `${percent}%` }}
            />
          </div>
          <div className="flex justify-between text-[11px] text-gray-400 mt-1">
            <span>Maqsad: {formatAmount(targetAmount)}</span>
          </div>
        </div>
      </div>

      <div className="p-6 pt-0">
        <Link
          to={`/projects/${id}`}
          className="block w-full py-2.5 text-center bg-gray-50 hover:bg-green-600 hover:text-white text-green-700 font-semibold rounded-xl border border-green-200/50 hover:border-transparent transition"
        >
          Tafsilotlar
        </Link>
      </div>
    </div>
  );
};

export default ProjectCard;
