import React from 'react';
import { ANIMAL_TYPE_META } from '../../../utils/animalType';

const ANIMAL_TYPES = Object.entries(ANIMAL_TYPE_META).map(([value, meta]) => ({ value, label: meta.label }));

// Conditional 3-field block (animal type / headcount / price-per-head) shown
// only for LIVESTOCK/POULTRY projects. The asset-type <select> itself stays
// inline in CreateProjectForm so it can keep sharing a grid row with the title
// field - this component only owns the block that appears below it.
const AssetTypePicker = ({ isAnimalProject, animalType, setAnimalType, headcount, setHeadcount, pricePerHead, setPricePerHead }) => {
  if (!isAnimalProject) return null;

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div>
        <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Hayvon turi</label>
        <select
          value={animalType}
          onChange={(e) => setAnimalType(e.target.value)}
          className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 rounded-xl text-sm outline-none bg-white dark:bg-slate-900 dark:text-slate-100 focus:ring-1 focus:ring-primary-500"
          required={isAnimalProject}
        >
          <option value="">Tanlang</option>
          {ANIMAL_TYPES.map((t) => (
            <option key={t.value} value={t.value}>{t.label}</option>
          ))}
        </select>
      </div>
      <div>
        <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Bosh soni</label>
        <input
          type="number"
          value={headcount}
          onChange={(e) => setHeadcount(e.target.value)}
          placeholder="50"
          className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
          required={isAnimalProject}
        />
      </div>
      <div>
        <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Bir bosh narxi (so'm)</label>
        <input
          type="number"
          value={pricePerHead}
          onChange={(e) => setPricePerHead(e.target.value)}
          placeholder="1500000"
          className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500"
        />
      </div>
    </div>
  );
};

export default AssetTypePicker;
