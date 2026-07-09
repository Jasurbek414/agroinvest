import React from 'react';

const ReportFrequencySlider = ({ reportFrequencyDays, setReportFrequencyDays }) => {
  return (
    <div className="pt-2 border-t border-gray-100 dark:border-slate-700">
      <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1 mt-4">
        Hisobot chastotasi ({reportFrequencyDays === 1 ? 'kunlik' : `har ${reportFrequencyDays} kunda`})
      </label>
      <input
        type="range"
        min={1}
        max={14}
        value={reportFrequencyDays}
        onChange={(e) => setReportFrequencyDays(parseInt(e.target.value))}
        className="w-full accent-primary-600"
      />
    </div>
  );
};

export default ReportFrequencySlider;
