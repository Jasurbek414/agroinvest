import React, { useEffect, useState } from 'react';
import { getPendingExpenses, reviewExpense } from '../../../api/expenses.api';
import { formatAmount, formatDate } from '../../../utils/format';
import { Receipt, Landmark, ShieldCheck, FileText, Image, Eye, Calendar, DollarSign, Wallet } from 'lucide-react';
import Badge from '../../ui/Badge';
import Button from '../../ui/Button';
import DataTable from '../../ui/DataTable';
import PromptDialog from '../../ui/PromptDialog';
import { useToast } from '../../ui/ToastProvider';

const CATEGORY_LABEL_UZ = {
  FEED: 'Yem-xashak',
  MEDICINE: 'Dori-darmon',
  VET_SERVICE: 'Veterinar xizmati',
  TRANSPORT: 'Transport',
  LABOR: 'Ish haqi',
  EQUIPMENT: 'Jihozlar',
  OTHER: 'Boshqa',
};

const PAYER_LABEL_UZ = {
  INVESTOR_BUDGET: "Loyiha byudjetidan",
  FARMER: "Fermer to'lagan",
};

const ExpensesTab = ({ onActionDone }) => {
  const [expenses, setExpenses] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rejectTarget, setRejectTarget] = useState(null);
  const [selectedExpense, setSelectedExpense] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const { showToast } = useToast();

  const fetchData = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getPendingExpenses(page, 15);
      setExpenses(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError('Harajatlarni yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(0); }, []);

  const runAction = async (id, approve, comment) => {
    try {
      await reviewExpense(id, approve, comment);
      showToast(approve ? 'Harajat tasdiqlandi' : 'Harajat rad etildi');
      fetchData(pageInfo.pageNumber);
      setSelectedExpense(null);
      onActionDone?.();
    } catch (err) {
      showToast(err.error?.message || 'Xatolik yuz berdi', 'error');
    }
  };

  const filteredExpenses = expenses.filter(e => {
    const matchesSearch = e.projectTitle?.toLowerCase().includes(searchQuery.toLowerCase()) || 
                          e.description?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = categoryFilter ? e.category === categoryFilter : true;
    return matchesSearch && matchesCategory;
  });

  const pendingCount = expenses.length;
  const totalPendingAmount = expenses.reduce((sum, e) => sum + (e.amount || 0), 0);
  const farmerPaidCount = expenses.filter(e => e.payerSource === 'FARMER').length;

  return (
    <div className="space-y-6 p-6">
      {/* Stats row */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-amber-50/50 dark:bg-amber-950/10 border border-amber-100 dark:border-amber-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-amber-500/10 text-amber-600 dark:text-amber-400 rounded-xl shrink-0">
            <Receipt size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Kutilayotgan harajatlar</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{pendingCount} ta</p>
          </div>
        </div>

        <div className="bg-primary-50/50 dark:bg-primary-950/10 border border-primary-100 dark:border-primary-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-primary-500/10 text-primary-600 dark:text-primary-400 rounded-xl shrink-0">
            <DollarSign size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Kutilayotgan jami summa</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{formatAmount(totalPendingAmount)}</p>
          </div>
        </div>

        <div className="bg-sky-50/50 dark:bg-sky-950/10 border border-sky-100 dark:border-sky-900/30 p-4 rounded-2xl flex items-center gap-4">
          <div className="p-3 bg-sky-500/10 text-sky-600 dark:text-sky-400 rounded-xl shrink-0">
            <Wallet size={20} />
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Fermer to'lagan (Qaytariladigan)</p>
            <p className="text-xl font-black text-gray-900 dark:text-slate-100 mt-0.5">{farmerPaidCount} ta harajat</p>
          </div>
        </div>
      </div>

      {/* Main Content Card */}
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-gray-100 dark:border-slate-700 shadow-sm overflow-hidden">
        <DataTable
          loading={loading}
          error={error}
          onRetry={() => fetchData(pageInfo.pageNumber)}
          rows={filteredExpenses}
          emptyTitle="Tasdiqlanish kutilayotgan harajatlar yo'q"
          searchable
          search={searchQuery}
          onSearchChange={setSearchQuery}
          searchPlaceholder="Loyiha nomi bo'yicha qidirish..."
          filters={
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="px-3 py-2 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500"
            >
              <option value="">Barcha toifalar</option>
              {Object.entries(CATEGORY_LABEL_UZ).map(([key, value]) => (
                <option key={key} value={key}>{value}</option>
              ))}
            </select>
          }
          page={{ ...pageInfo, onPageChange: fetchData }}
          columns={[
            { key: 'projectTitle', header: 'Loyiha', render: (e) => <span className="font-semibold text-gray-900 dark:text-slate-100">{e.projectTitle}</span> },
            { key: 'category', header: 'Toifa', render: (e) => (
              <span className="text-xs font-bold text-gray-600 dark:text-slate-400 bg-gray-50 dark:bg-slate-900 px-2.5 py-1 rounded-lg border border-gray-100 dark:border-slate-800">
                {CATEGORY_LABEL_UZ[e.category] || e.category}
              </span>
            )},
            { key: 'amount', header: 'Summa', render: (e) => <span className="font-bold text-primary-700 dark:text-primary-400">{formatAmount(e.amount)}</span> },
            { key: 'payerSource', header: "To'lovchi", render: (e) => (
              <span className={`text-[11px] font-bold px-2 py-0.5 rounded ${
                e.payerSource === 'FARMER' ? 'bg-amber-50 text-amber-700 dark:bg-amber-955' : 'bg-primary-50 text-primary-700 dark:bg-primary-955'
              }`}>
                {PAYER_LABEL_UZ[e.payerSource] || e.payerSource}
              </span>
            )},
            { key: 'expenseDate', header: 'Sana', render: (e) => <span className="text-xs text-gray-500 dark:text-slate-400">{formatDate(e.expenseDate)}</span> },
            { key: 'receiptUrls', header: 'Hujjatlar', render: (e) => e.receiptUrls && e.receiptUrls.length > 0 ? (
              <button 
                onClick={() => setSelectedExpense(e)}
                className="flex items-center gap-1.5 px-3 py-1 bg-gray-50 dark:bg-slate-950 border border-gray-100 dark:border-slate-800 rounded-lg text-xs text-primary-600 hover:text-primary-700 font-bold transition shadow-sm"
              >
                <FileText size={14} />
                Hujjatni ochish
              </button>
            ) : <span className="text-xs text-gray-400">Yo'q</span> },
            {
              key: 'actions', header: 'Amallar', align: 'right',
              render: (e) => (
                <div className="flex justify-end gap-1.5">
                  <Button variant="ghost" size="sm" icon={Eye} onClick={() => setSelectedExpense(e)}>Batafsil</Button>
                  <Button variant="danger" size="sm" onClick={() => setRejectTarget(e.id)}>Rad etish</Button>
                  <Button variant="primary" size="sm" onClick={() => runAction(e.id, true, null)}>Tasdiqlash</Button>
                </div>
              ),
            },
          ]}
          renderMobileCard={(e) => (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="font-bold text-gray-950 dark:text-slate-100">{e.projectTitle}</span>
                <span className="text-xs text-primary-700 dark:text-primary-400 font-bold">{formatAmount(e.amount)}</span>
              </div>
              <p className="text-xs text-gray-600 dark:text-slate-400">
                {CATEGORY_LABEL_UZ[e.category] || e.category} · {PAYER_LABEL_UZ[e.payerSource] || e.payerSource}
              </p>
              {e.description && <p className="text-xs text-gray-500 dark:text-slate-400 italic">"{e.description}"</p>}
              <div className="flex gap-2 pt-1">
                <Button variant="secondary" size="sm" className="flex-1" onClick={() => setSelectedExpense(e)}>Batafsil</Button>
                <Button variant="danger" size="sm" className="flex-1" onClick={() => setRejectTarget(e.id)}>Rad etish</Button>
                <Button variant="primary" size="sm" className="flex-1" onClick={() => runAction(e.id, true, null)}>Tasdiqlash</Button>
              </div>
            </div>
          )}
        />
      </div>

      {/* Details modal */}
      {selectedExpense && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm transition-opacity">
          <div className="relative w-full max-w-lg bg-white dark:bg-slate-800 rounded-3xl shadow-xl overflow-hidden animate-in fade-in zoom-in duration-200 border border-gray-100 dark:border-slate-700">
            <div className="px-6 py-5 border-b border-gray-100 dark:border-slate-700 flex justify-between items-center bg-gray-50/50 dark:bg-slate-900/30">
              <div>
                <h3 className="text-lg font-bold text-gray-900 dark:text-slate-100">Harajat tafsilotlari</h3>
                <p className="text-xs text-gray-500 dark:text-slate-400 mt-0.5">Sana: {formatDate(selectedExpense.expenseDate)}</p>
              </div>
              <button onClick={() => setSelectedExpense(null)} className="p-2 rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700 hover:text-gray-600">&times;</button>
            </div>

            <div className="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
              <div className="flex items-center gap-4 pb-4 border-b border-gray-100 dark:border-slate-700">
                <div className="w-12 h-12 rounded-xl bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 flex items-center justify-center font-extrabold shrink-0">
                  <Receipt size={24} />
                </div>
                <div>
                  <h4 className="text-base font-bold text-gray-900 dark:text-slate-100">{selectedExpense.projectTitle}</h4>
                  <p className="text-xs text-gray-500 dark:text-slate-400">Toifa: {CATEGORY_LABEL_UZ[selectedExpense.category] || selectedExpense.category}</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-xs text-gray-400 font-medium">Harajat summasi</p>
                  <p className="text-lg font-black text-primary-700 dark:text-primary-400 mt-0.5">{formatAmount(selectedExpense.amount)}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400 font-medium">To'lov manbai</p>
                  <p className="font-semibold text-gray-900 dark:text-slate-100 mt-1">{PAYER_LABEL_UZ[selectedExpense.payerSource] || selectedExpense.payerSource}</p>
                </div>
              </div>

              {selectedExpense.description && (
                <div className="space-y-1">
                  <p className="text-xs text-gray-400 font-bold uppercase">Harajat tavsifi</p>
                  <p className="text-sm text-gray-700 dark:text-slate-200 leading-relaxed bg-gray-50 dark:bg-slate-900/40 p-3 rounded-xl border border-gray-100 dark:border-slate-800">
                    {selectedExpense.description}
                  </p>
                </div>
              )}

              {selectedExpense.receiptUrls && selectedExpense.receiptUrls.length > 0 && (
                <div className="space-y-2">
                  <p className="text-xs text-gray-400 font-bold uppercase">Chek / Kvitansiyalar</p>
                  <div className="grid grid-cols-2 gap-2">
                    {selectedExpense.receiptUrls.map((url, idx) => (
                      <div key={idx} className="border border-gray-100 dark:border-slate-700 rounded-xl overflow-hidden bg-gray-50 flex items-center justify-center relative group min-h-28">
                        <img src={url} alt="Chek" className="h-28 w-full object-cover" />
                        <a 
                          href={url} 
                          target="_blank" 
                          rel="noopener noreferrer" 
                          className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-xs font-bold transition gap-1"
                        >
                          <Eye size={14} /> Ochish
                        </a>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <div className="px-6 py-4 border-t border-gray-100 dark:border-slate-700 bg-gray-50/50 dark:bg-slate-900/30 flex justify-end gap-2">
              <Button variant="secondary" onClick={() => setSelectedExpense(null)}>Yopish</Button>
              <Button variant="danger" onClick={() => setRejectTarget(selectedExpense.id)}>Rad etish</Button>
              <Button variant="primary" onClick={() => runAction(selectedExpense.id, true, null)}>Tasdiqlash</Button>
            </div>
          </div>
        </div>
      )}

      <PromptDialog
        open={!!rejectTarget}
        title="Harajatni rad etish"
        label="Izoh"
        tone="danger"
        confirmLabel="Rad etish"
        onCancel={() => setRejectTarget(null)}
        onConfirm={(comment) => { runAction(rejectTarget, false, comment); setRejectTarget(null); }}
      />
    </div>
  );
};

export default ExpensesTab;
