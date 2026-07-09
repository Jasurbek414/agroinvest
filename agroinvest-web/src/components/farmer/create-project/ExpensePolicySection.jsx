import React from 'react';

const EXPENSE_POLICIES = [
  { value: 'INVESTOR_BUDGET', label: 'Loyiha byudjetidan', hint: 'Yig\'ilgan mablag\' ichidan, shaffof hisobda' },
  { value: 'FARMER_REIMBURSED', label: 'O\'zim to\'layman', hint: 'Sotuvdan keyin, foyda bo\'linishidan OLDIN qaytariladi' },
  { value: 'MIXED', label: 'Aralash', hint: 'Har bir harajatda alohida belgilayman' },
];

const ExpensePolicySection = ({ expensePolicy, setExpensePolicy }) => {
  return (
    <div className="pt-2 border-t border-gray-100 dark:border-slate-700">
      <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-2 mt-4">Joriy harajatlar siyosati</label>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-2">
        {EXPENSE_POLICIES.map((p) => (
          <button
            key={p.value}
            type="button"
            onClick={() => setExpensePolicy(p.value)}
            className={`text-left p-3 rounded-xl border text-xs transition ${
              expensePolicy === p.value ? 'border-primary-500 bg-primary-50 dark:bg-primary-950' : 'border-gray-200 dark:border-slate-600 hover:border-gray-300 dark:hover:border-slate-500'
            }`}
          >
            <p className="font-bold text-gray-800 dark:text-slate-200">{p.label}</p>
            <p className="text-gray-500 dark:text-slate-400 mt-0.5">{p.hint}</p>
          </button>
        ))}
      </div>
    </div>
  );
};

export default ExpensePolicySection;
