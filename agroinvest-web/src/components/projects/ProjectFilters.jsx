import React from 'react';

const ProjectFilters = ({ currentStatus, onStatusChange }) => {
  const statuses = [
    { label: "Barchasi", value: "" },
    { label: "Mablag' yig'ilmoqda", value: 'FUNDING' },
    { label: "Faol parvarishda", value: 'ACTIVE' },
    { label: "Yakunlangan", value: 'COMPLETED' },
  ];

  return (
    <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-none">
      {statuses.map((status) => (
        <button
          key={status.value}
          onClick={() => onStatusChange(status.value)}
          className={`px-4 py-2 text-sm font-semibold rounded-full border transition whitespace-nowrap ${
            currentStatus === status.value
              ? 'bg-primary-600 border-transparent text-white shadow-sm'
              : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-600 text-gray-600 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700'
          }`}
        >
          {status.label}
        </button>
      ))}
    </div>
  );
};

export default ProjectFilters;
