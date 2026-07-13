import React, { useEffect, useState } from 'react';
import { getSuperAdminCoopOffers, updateCoopOfferStatus, deleteCoopOffer } from '../../api/coop.api';
import { useToast } from '../ui/ToastProvider';
import { Check, X, Trash2, Calendar, Phone, User, AlertCircle, BarChart3, Search, Eye, Filter, RefreshCw, FileText, FileSpreadsheet, File, Download } from 'lucide-react';
import { formatAmount, formatDate } from '../../utils/format';
import Card from '../ui/Card';
import Badge from '../ui/Badge';
import ConfirmDialog from '../ui/ConfirmDialog';

const CoopModerationPanel = () => {
  const { showToast } = useToast();
  const [offers, setOffers] = useState([]);
  const [loading, setLoading] = useState(true);
  
  // Section Navigation: 'BUSINESS_PLAN' | 'INVESTOR_OFFER' | 'CONTRACT_SALE' | 'ANALYTICS'
  const [activeSection, setActiveSection] = useState('BUSINESS_PLAN');
  
  // Status filter inside active section
  const [statusFilter, setStatusFilter] = useState('ALL'); // 'ALL' | 'PENDING' | 'APPROVED' | 'REJECTED'
  
  // Search query
  const [searchQuery, setSearchQuery] = useState('');
  
  // Dialog/Modal targets
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [detailTarget, setDetailTarget] = useState(null);

  const extractAttachments = (text) => {
    if (!text) return { docs: [], images: [] };
    const urlRegex = /(https?:\/\/[^\s]+)/g;
    const matches = text.match(urlRegex) || [];
    
    const docs = [];
    const images = [];
    
    matches.forEach(url => {
      const cleanUrl = url.replace(/[.,;)]$/, '');
      const lowercase = cleanUrl.toLowerCase();
      if (
        lowercase.endsWith('.pdf') || 
        lowercase.endsWith('.doc') || 
        lowercase.endsWith('.docx') || 
        lowercase.endsWith('.xls') || 
        lowercase.endsWith('.xlsx')
      ) {
        docs.push(cleanUrl);
      } else if (
        lowercase.endsWith('.png') || 
        lowercase.endsWith('.jpg') || 
        lowercase.endsWith('.jpeg') || 
        lowercase.endsWith('.webp')
      ) {
        images.push(cleanUrl);
      } else {
        docs.push(cleanUrl);
      }
    });
    
    return { docs, images };
  };

  useEffect(() => {
    fetchOffers();
  }, []);

  const fetchOffers = async () => {
    setLoading(true);
    try {
      const res = await getSuperAdminCoopOffers();
      setOffers(res.data.content || []);
    } catch (err) {
      showToast("Kooperatsiya takliflarini yuklashda xatolik yuz berdi", "error");
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateStatus = async (id, status) => {
    try {
      await updateCoopOfferStatus(id, status);
      showToast(`Taklif holati muvaffaqiyatli ${status === 'APPROVED' ? "tasdiqlandi" : "rad etildi"}!`, 'success');
      
      // Update local state without full reload for instant feedback
      setOffers(prev => prev.map(o => o.id === id ? { ...o, status } : o));
      if (detailTarget?.id === id) {
        setDetailTarget(prev => ({ ...prev, status }));
      }
    } catch (err) {
      showToast("Holatni yangilashda xatolik yuz berdi.", 'error');
    }
  };

  const handleDelete = async () => {
    try {
      await deleteCoopOffer(deleteTarget);
      showToast("Taklif butunlay o'chirildi!");
      setOffers(prev => prev.filter(o => o.id !== deleteTarget));
      setDeleteTarget(null);
      setDetailTarget(null);
    } catch (err) {
      showToast("Taklifni o'chirishda xatolik yuz berdi.", 'error');
    }
  };

  // Metrics for statistics sub-section
  const getMetrics = () => {
    const plans = offers.filter(o => o.type === 'BUSINESS_PLAN');
    const investorOffers = offers.filter(o => o.type === 'INVESTOR_OFFER');
    const contracts = offers.filter(o => o.type === 'CONTRACT_SALE');

    return {
      plansTotal: plans.length,
      plansPending: plans.filter(o => o.status === 'PENDING').length,
      plansApproved: plans.filter(o => o.status === 'APPROVED').length,
      plansAmount: plans.reduce((acc, curr) => acc + curr.amount, 0),

      investorTotal: investorOffers.length,
      investorPending: investorOffers.filter(o => o.status === 'PENDING').length,
      investorApproved: investorOffers.filter(o => o.status === 'APPROVED').length,
      investorAmount: investorOffers.reduce((acc, curr) => acc + curr.amount, 0),

      contractsTotal: contracts.length,
      contractsPending: contracts.filter(o => o.status === 'PENDING').length,
      contractsApproved: contracts.filter(o => o.status === 'APPROVED').length,
      contractsAmount: contracts.reduce((acc, curr) => acc + curr.amount, 0),

      totalBudget: offers.reduce((acc, curr) => acc + curr.amount, 0),
    };
  };

  const metrics = getMetrics();

  // Filter lists based on selected section, status filter, and search query
  const getFilteredList = () => {
    return offers.filter(o => {
      // 1. Section type match
      if (o.type !== activeSection) return false;
      
      // 2. Status match
      if (statusFilter !== 'ALL' && o.status !== statusFilter) return false;
      
      // 3. Search query match
      if (searchQuery.trim() !== '') {
        const q = searchQuery.toLowerCase();
        const matchesTitle = o.title?.toLowerCase().includes(q);
        const matchesDesc = o.description?.toLowerCase().includes(q);
        const matchesCreator = o.creatorName?.toLowerCase().includes(q);
        return matchesTitle || matchesDesc || matchesCreator;
      }
      
      return true;
    });
  };

  const filteredList = activeSection === 'ANALYTICS' ? [] : getFilteredList();

  return (
    <div className="space-y-6">
      
      {/* Metrics Bar */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-gradient-to-br from-purple-500/10 to-purple-600/5 dark:from-purple-950/20 dark:to-purple-900/5 p-4 rounded-2xl border border-purple-500/20 shadow-sm">
          <span className="text-[10px] text-purple-700 dark:text-purple-400 font-bold uppercase tracking-wider block">Biznes Rejalar</span>
          <div className="flex justify-between items-end mt-2">
            <span className="text-xl font-black text-gray-950 dark:text-slate-100">{metrics.plansTotal} ta</span>
            <span className="text-[10px] bg-purple-500/10 text-purple-700 dark:text-purple-400 px-2 py-0.5 rounded font-black">{metrics.plansPending} kutilmoqda</span>
          </div>
          <span className="text-[10px] text-gray-400 font-bold block mt-1">Sarmoya: {formatAmount(metrics.plansAmount)}</span>
        </div>

        <div className="bg-gradient-to-br from-emerald-500/10 to-emerald-600/5 dark:from-emerald-950/20 dark:to-emerald-900/5 p-4 rounded-2xl border border-emerald-500/20 shadow-sm">
          <span className="text-[10px] text-emerald-700 dark:text-emerald-450 font-bold uppercase tracking-wider block">Investor takliflari</span>
          <div className="flex justify-between items-end mt-2">
            <span className="text-xl font-black text-gray-950 dark:text-slate-100">{metrics.investorTotal} ta</span>
            <span className="text-[10px] bg-emerald-500/10 text-emerald-700 dark:text-emerald-450 px-2 py-0.5 rounded font-black">{metrics.investorPending} kutilmoqda</span>
          </div>
          <span className="text-[10px] text-gray-400 font-bold block mt-1">Budjet: {formatAmount(metrics.investorAmount)}</span>
        </div>

        <div className="bg-gradient-to-br from-blue-500/10 to-blue-600/5 dark:from-blue-950/20 dark:to-blue-900/5 p-4 rounded-2xl border border-blue-500/20 shadow-sm">
          <span className="text-[10px] text-blue-700 dark:text-blue-400 font-bold uppercase tracking-wider block">Tayyor shartnomalar</span>
          <div className="flex justify-between items-end mt-2">
            <span className="text-xl font-black text-gray-950 dark:text-slate-100">{metrics.contractsTotal} ta</span>
            <span className="text-[10px] bg-blue-500/10 text-blue-700 dark:text-blue-400 px-2 py-0.5 rounded font-black">{metrics.contractsPending} kutilmoqda</span>
          </div>
          <span className="text-[10px] text-gray-400 font-bold block mt-1">Qiymati: {formatAmount(metrics.contractsAmount)}</span>
        </div>

        <div className="bg-gradient-to-br from-amber-500/10 to-amber-600/5 dark:from-amber-950/20 dark:to-amber-900/5 p-4 rounded-2xl border border-amber-500/20 shadow-sm flex flex-col justify-between">
          <div>
            <span className="text-[10px] text-amber-700 dark:text-amber-400 font-bold uppercase tracking-wider block">Bozor jami aylanmasi</span>
            <span className="text-xl font-black text-gray-950 dark:text-slate-100 block mt-1">
              {formatAmount(metrics.totalBudget)}
            </span>
          </div>
          <span className="text-[10px] text-gray-400 font-bold block">Barcha taklif va rejalar jamlanmasi</span>
        </div>
      </div>

      {/* Main Panel Content Card */}
      <Card>
        {/* Section Navigation Headers */}
        <div className="flex flex-wrap items-center justify-between gap-4 pb-4 border-b border-gray-100 dark:border-slate-800/60 mb-6">
          <div className="flex items-center gap-1 bg-gray-50 dark:bg-slate-955 p-1 rounded-xl">
            {[
              { id: 'BUSINESS_PLAN', label: 'Biznes Rejalar' },
              { id: 'INVESTOR_OFFER', label: 'Investor takliflari' },
              { id: 'CONTRACT_SALE', label: 'Tayyor shartnomalar' },
              { id: 'ANALYTICS', label: 'Tahlillar & Statistika', icon: BarChart3 },
            ].map((section) => {
              const Icon = section.icon;
              return (
                <button
                  key={section.id}
                  onClick={() => {
                    setActiveSection(section.id);
                    setStatusFilter('ALL');
                    setSearchQuery('');
                  }}
                  className={`px-4 py-2 text-xs font-black rounded-lg transition-all duration-200 flex items-center gap-1.5 ${
                    activeSection === section.id
                      ? 'bg-white dark:bg-slate-900 text-primary-650 dark:text-primary-400 shadow-sm border border-gray-150/40 dark:border-slate-800/50'
                      : 'text-gray-500 dark:text-slate-400 hover:text-gray-900'
                  }`}
                >
                  {Icon && <Icon size={13} />}
                  <span>{section.label}</span>
                </button>
              );
            })}
          </div>

          <button
            onClick={fetchOffers}
            className="p-2.5 bg-gray-50 hover:bg-gray-100 dark:bg-slate-950 dark:hover:bg-slate-900 text-gray-400 dark:text-slate-500 rounded-xl transition border border-gray-100/10"
            title="Yangilash"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
          </button>
        </div>

        {/* Section Content: Analytics View */}
        {activeSection === 'ANALYTICS' && (
          <div className="space-y-6 py-4 animate-in fade-in duration-300">
            <h3 className="font-extrabold text-sm text-gray-950 dark:text-slate-100">Sub-Platforma bo'limlarining tahliliy ko'rsatkichi</h3>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="border border-gray-100 dark:border-slate-800/80 p-5 rounded-2xl space-y-4">
                <span className="font-black text-xs text-purple-750 dark:text-purple-400 uppercase tracking-wide block">1. Biznes Rejalar va Loyihalar</span>
                <div className="space-y-2 text-xs text-gray-550 dark:text-slate-400 font-semibold">
                  <div className="flex justify-between"><span>Jami arizalar:</span><strong className="text-gray-900 dark:text-slate-200">{metrics.plansTotal} ta</strong></div>
                  <div className="flex justify-between"><span>Tasdiqlanganlar:</span><strong className="text-emerald-600">{metrics.plansApproved} ta</strong></div>
                  <div className="flex justify-between"><span>Moderatsiyada:</span><strong className="text-amber-500">{metrics.plansPending} ta</strong></div>
                </div>
              </div>

              <div className="border border-gray-100 dark:border-slate-800/80 p-5 rounded-2xl space-y-4">
                <span className="font-black text-xs text-emerald-750 dark:text-emerald-450 uppercase tracking-wide block">2. Investorlar pul takliflari</span>
                <div className="space-y-2 text-xs text-gray-550 dark:text-slate-400 font-semibold">
                  <div className="flex justify-between"><span>Jami takliflar:</span><strong className="text-gray-900 dark:text-slate-200">{metrics.investorTotal} ta</strong></div>
                  <div className="flex justify-between"><span>Tasdiqlanganlar:</span><strong className="text-emerald-600">{metrics.investorApproved} ta</strong></div>
                  <div className="flex justify-between"><span>Moderatsiyada:</span><strong className="text-amber-500">{metrics.investorPending} ta</strong></div>
                </div>
              </div>

              <div className="border border-gray-100 dark:border-slate-800/80 p-5 rounded-2xl space-y-4">
                <span className="font-black text-xs text-blue-750 dark:text-blue-400 uppercase tracking-wide block">3. Tayyor shartnomalar savdosi</span>
                <div className="space-y-2 text-xs text-gray-550 dark:text-slate-400 font-semibold">
                  <div className="flex justify-between"><span>Jami shartnomalar:</span><strong className="text-gray-900 dark:text-slate-200">{metrics.contractsTotal} ta</strong></div>
                  <div className="flex justify-between"><span>Tasdiqlanganlar:</span><strong className="text-emerald-600">{metrics.contractsApproved} ta</strong></div>
                  <div className="flex justify-between"><span>Moderatsiyada:</span><strong className="text-amber-500">{metrics.contractsPending} ta</strong></div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Section Content: Data list for BUSINESS_PLAN, INVESTOR_OFFER, CONTRACT_SALE */}
        {activeSection !== 'ANALYTICS' && (
          <div className="space-y-4 animate-in fade-in duration-300">
            
            {/* Search and Inner Filter Tools */}
            <div className="flex flex-col sm:flex-row gap-3">
              <div className="relative flex-1">
                <Search size={14} className="absolute left-3 top-3.5 text-gray-400" />
                <input
                  type="text"
                  placeholder="Sarlavha, tavsif yoki joylovchi ismi bo'yicha qidirish..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-4 py-2.5 border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold rounded-xl outline-none focus:ring-1 focus:ring-primary-500"
                />
              </div>

              <div className="flex items-center gap-1.5 p-1 bg-gray-50 dark:bg-slate-955 border border-gray-200/40 dark:border-slate-800/60 rounded-xl shrink-0">
                {[
                  { id: 'ALL', label: 'Barchasi' },
                  { id: 'PENDING', label: 'Kutilayotganlar' },
                  { id: 'APPROVED', label: 'Tasdiqlanganlar' },
                  { id: 'REJECTED', label: 'Rad etilganlar' },
                  { id: 'WITHDRAWN', label: 'Qaytarib olinganlar' },
                ].map((st) => (
                  <button
                    key={st.id}
                    onClick={() => setStatusFilter(st.id)}
                    className={`px-3 py-1.5 text-[10px] font-black rounded-lg transition-all duration-200 ${
                      statusFilter === st.id
                        ? 'bg-white dark:bg-slate-900 text-primary-650 dark:text-primary-400 shadow-sm border border-gray-150/40 dark:border-slate-850'
                        : 'text-gray-500 dark:text-slate-400 hover:text-gray-900'
                    }`}
                  >
                    {st.label}
                  </button>
                ))}
              </div>
            </div>

            {/* List */}
            {loading ? (
              <p className="text-sm text-gray-400 text-center py-10 animate-pulse">Yuklanmoqda...</p>
            ) : filteredList.length === 0 ? (
              <div className="text-center py-10">
                <AlertCircle size={24} className="text-gray-300 mx-auto" />
                <p className="text-xs text-gray-400 mt-2 font-bold">Ushbu bo'limda filtrlar bo'yicha e'lonlar topilmadi</p>
              </div>
            ) : (
              <div className="space-y-4">
                {filteredList.map((o) => (
                  <div key={o.id} className="p-5 rounded-2xl border border-gray-100 dark:border-slate-800 bg-white dark:bg-slate-900 flex flex-col md:flex-row justify-between md:items-center gap-4 hover:shadow-sm transition">
                    <div className="space-y-2 max-w-2xl text-xs">
                      <div className="flex flex-wrap items-center gap-2">
                        {o.status === 'PENDING' && <Badge tone="yellow">Moderatsiyada</Badge>}
                        {o.status === 'APPROVED' && <Badge tone="green">Faol / Tasdiqlangan</Badge>}
                        {o.status === 'REJECTED' && <Badge tone="red">Rad etilgan</Badge>}
                        {o.status === 'WITHDRAWN' && <Badge tone="gray">Qaytarib olingan</Badge>}
                        
                        <span className="text-[10px] text-gray-400 font-bold flex items-center gap-1">
                          <Calendar size={11} /> {formatDate(o.createdAt)}
                        </span>
                      </div>
                      
                      <h3 className="font-extrabold text-sm text-gray-950 dark:text-slate-100">{o.title}</h3>
                      <p className="text-xs text-gray-550 dark:text-slate-400 leading-relaxed line-clamp-2">{o.description}</p>

                      <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-[11px] text-gray-400 font-bold pt-1">
                        <span className="flex items-center gap-1"><User size={12} className="text-gray-400" /> Joylovchi: {o.creatorName}</span>
                        <span className="flex items-center gap-1"><Phone size={12} className="text-gray-400" /> Aloqa: {o.contactPhone}</span>
                        <span className="text-gray-900 dark:text-slate-150 font-black">Summa: {formatAmount(o.amount)}</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 shrink-0 border-t md:border-t-0 pt-3 md:pt-0 border-gray-100 dark:border-slate-800">
                      <button
                        onClick={() => setDetailTarget(o)}
                        className="p-2 bg-gray-50 hover:bg-gray-150 dark:bg-slate-950 text-gray-500 rounded-xl transition"
                        title="Batafsil ko'rish"
                      >
                        <Eye size={16} />
                      </button>

                      {o.status === 'PENDING' && (
                        <>
                          <button
                            onClick={() => handleUpdateStatus(o.id, 'APPROVED')}
                            className="p-2 bg-emerald-50 hover:bg-emerald-600 text-emerald-700 hover:text-white border border-emerald-200/10 rounded-xl transition shadow-sm"
                            title="Tasdiqlash"
                          >
                            <Check size={16} />
                          </button>
                          <button
                            onClick={() => handleUpdateStatus(o.id, 'REJECTED')}
                            className="p-2 bg-rose-50 hover:bg-rose-600 text-rose-700 hover:text-white border border-rose-250/10 rounded-xl transition shadow-sm"
                            title="Rad etish"
                          >
                            <X size={16} />
                          </button>
                        </>
                      )}
                      
                      <button
                        onClick={() => setDeleteTarget(o.id)}
                        className="p-2 bg-gray-50 hover:bg-rose-600 text-gray-400 hover:text-white dark:bg-slate-955 dark:text-slate-500 rounded-xl transition"
                        title="O'chirish"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </Card>

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={!!deleteTarget}
        title="Taklifni o'chirish"
        message="Ushbu taklifni butunlay o'chirishni xohlaysizmi?"
        tone="danger"
        confirmLabel="O'chirish"
        onCancel={() => setDeleteTarget(null)}
        onConfirm={handleDelete}
      />

      {/* Full Detail Modal */}
      {detailTarget && (
        <div className="fixed inset-0 bg-slate-950/60 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-in fade-in duration-200">
          <div className="bg-white dark:bg-slate-900 rounded-[32px] border border-gray-150/40 dark:border-slate-800/80 shadow-2xl max-w-lg w-full p-6 space-y-4 max-h-[85vh] overflow-y-auto scrollbar-none">
            
            <div className="flex justify-between items-center pb-3 border-b border-gray-100 dark:border-slate-800/60">
              <div>
                <span className="px-2 py-0.5 bg-primary-50 dark:bg-primary-950/40 text-primary-700 dark:text-primary-400 text-[10px] font-bold rounded-md">
                  {activeSection === 'BUSINESS_PLAN' ? "Biznes Reja" : activeSection === 'INVESTOR_OFFER' ? "Investor taklifi" : "Tayyor shartnoma"}
                </span>
                <h3 className="font-black text-gray-950 dark:text-slate-100 text-base mt-1.5">Batafsil ma'lumot</h3>
              </div>
              <button onClick={() => setDetailTarget(null)} className="p-2 hover:bg-gray-100 dark:hover:bg-slate-800 rounded-xl transition">
                <X size={16} className="text-gray-500 dark:text-slate-400" />
              </button>
            </div>

            <div className="space-y-4 text-xs font-bold text-gray-600 dark:text-slate-350">
              <div className="space-y-1">
                <span className="text-gray-400 block uppercase tracking-wider text-[10px]">Sarlavha</span>
                <p className="text-sm font-black text-gray-950 dark:text-slate-100 leading-tight">{detailTarget.title}</p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <span className="text-gray-400 block uppercase tracking-wider text-[10px]">Joylovchi</span>
                  <p className="text-gray-900 dark:text-slate-200">{detailTarget.creatorName}</p>
                </div>
                <div className="space-y-1">
                  <span className="text-gray-400 block uppercase tracking-wider text-[10px]">Telefon raqami</span>
                  <p className="text-gray-900 dark:text-slate-200">{detailTarget.contactPhone}</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <span className="text-gray-400 block uppercase tracking-wider text-[10px]">Summa</span>
                  <p className="text-sm font-black text-primary-650 dark:text-primary-400">{formatAmount(detailTarget.amount)}</p>
                </div>
                <div className="space-y-1">
                  <span className="text-gray-400 block uppercase tracking-wider text-[10px]">Holat</span>
                  <p className="text-gray-900 dark:text-slate-200 flex items-center gap-1.5">
                    {detailTarget.status === 'PENDING' && <Badge tone="yellow">Moderatsiyada</Badge>}
                    {detailTarget.status === 'APPROVED' && <Badge tone="green">Tasdiqlangan</Badge>}
                    {detailTarget.status === 'REJECTED' && <Badge tone="red">Rad etilgan</Badge>}
                    {detailTarget.status === 'WITHDRAWN' && <Badge tone="gray">Qaytarib olingan</Badge>}
                  </p>
                </div>
              </div>

              <div className="space-y-1">
                <span className="text-gray-400 block uppercase tracking-wider text-[10px]">Taklif / Loyiha batafsil tavsifi</span>
                <p className="text-gray-700 dark:text-slate-350 font-semibold leading-relaxed p-4 bg-gray-50 dark:bg-slate-950/60 rounded-2xl border border-gray-100/5 whitespace-pre-wrap">
                  {detailTarget.description}
                </p>
              </div>

              {(() => {
                const { docs, images } = extractAttachments(detailTarget.description);
                if (docs.length === 0 && images.length === 0) return null;
                return (
                  <div className="space-y-2 border-t border-gray-100 dark:border-slate-800/60 pt-3">
                    <span className="text-gray-400 block uppercase tracking-wider text-[10px]">Ilova qilingan hujjatlar va fayllar</span>
                    <div className="grid grid-cols-1 gap-2">
                      {docs.map((url, i) => {
                        const parts = url.split('/');
                        const filename = decodeURIComponent(parts[parts.length - 1] || 'hujjat');
                        const isPdf = filename.toLowerCase().endsWith('.pdf');
                        const isExcel = filename.toLowerCase().endsWith('.xls') || filename.toLowerCase().endsWith('.xlsx');
                        return (
                          <div key={i} className="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-800/30 rounded-2xl border border-gray-100 dark:border-slate-800">
                            <div className="flex items-center gap-2.5 min-w-0">
                              <div className="p-2 bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 rounded-xl">
                                {isPdf ? <FileText size={16} /> : isExcel ? <FileSpreadsheet size={16} /> : <File size={16} />}
                              </div>
                              <span className="text-xs font-semibold text-gray-800 dark:text-slate-200 truncate pr-2">
                                {filename}
                              </span>
                            </div>
                            <div className="flex gap-2 shrink-0">
                              <a
                                href={url}
                                target="_blank"
                                rel="noreferrer"
                                className="px-3 py-1.5 bg-white dark:bg-slate-700 hover:bg-emerald-50 dark:hover:bg-slate-600 text-gray-700 dark:text-slate-200 hover:text-emerald-700 font-extrabold text-[10px] rounded-lg border border-gray-200/60 dark:border-slate-600 transition flex items-center gap-1 shadow-sm"
                              >
                                <Eye size={10} />
                                <span>Ochish</span>
                              </a>
                              <a
                                href={url}
                                download
                                target="_blank"
                                rel="noreferrer"
                                className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white font-extrabold text-[10px] rounded-lg shadow-sm transition flex items-center gap-1"
                              >
                                <Download size={10} />
                                <span>Yuklash</span>
                              </a>
                            </div>
                          </div>
                        );
                      })}
                      {images.map((url, i) => (
                        <div key={i} className="space-y-1.5 p-3 bg-slate-50 dark:bg-slate-800/30 rounded-2xl border border-gray-100 dark:border-slate-800">
                          <div className="flex items-center justify-between">
                            <span className="text-[10px] text-gray-400 uppercase tracking-wider">Ilova rasm</span>
                            <div className="flex gap-1.5 font-bold text-[10px]">
                              <a href={url} target="_blank" rel="noreferrer" className="text-primary-600 dark:text-primary-400 hover:underline">Kattalashtirish</a>
                              <span className="text-gray-300">|</span>
                              <a href={url} download target="_blank" rel="noreferrer" className="text-primary-650 dark:text-primary-400 hover:underline">Yuklash</a>
                            </div>
                          </div>
                          <img src={url} alt="Loyiha hujjati" className="max-h-40 w-full object-cover rounded-xl border border-gray-200/40 dark:border-slate-700" />
                        </div>
                      ))}
                    </div>
                  </div>
                );
              })()}

              {detailTarget.status === 'PENDING' && (
                <div className="p-4 bg-emerald-50/20 dark:bg-slate-800/30 rounded-2xl border border-emerald-500/10 dark:border-slate-700/50 space-y-2.5">
                  <span className="text-emerald-800 dark:text-emerald-400 block uppercase tracking-wider text-[9px] font-black">Moderator Tekshiruvi Bosqichlari</span>
                  <div className="space-y-1.5 text-slate-700 dark:text-slate-350 text-[11px] font-semibold">
                    <label className="flex items-center gap-2 cursor-pointer hover:text-gray-900 dark:hover:text-white transition">
                      <input type="checkbox" className="rounded text-emerald-600 focus:ring-emerald-500 w-3.5 h-3.5" />
                      <span>Loyiha ma'lumotlari haqiqiyligi tekshirildi</span>
                    </label>
                    <label className="flex items-center gap-2 cursor-pointer hover:text-gray-900 dark:hover:text-white transition">
                      <input type="checkbox" className="rounded text-emerald-600 focus:ring-emerald-500 w-3.5 h-3.5" />
                      <span>Ilova qilingan barcha hujjatlar to'liq va yuklanadi</span>
                    </label>
                    <label className="flex items-center gap-2 cursor-pointer hover:text-gray-900 dark:hover:text-white transition">
                      <input type="checkbox" className="rounded text-emerald-600 focus:ring-emerald-500 w-3.5 h-3.5" />
                      <span>Telefon raqami va kontakt ma'lumotlari to'g'ri</span>
                    </label>
                  </div>
                </div>
              )}
            </div>

            {/* Actions inside Modal */}
            <div className="pt-4 border-t border-gray-100 dark:border-slate-800/60 flex justify-between items-center">
              <button
                onClick={() => setDeleteTarget(detailTarget.id)}
                className="px-4 py-2 bg-rose-50 hover:bg-rose-600 text-rose-700 hover:text-white font-extrabold rounded-xl transition flex items-center gap-1"
              >
                <Trash2 size={13} />
                <span>O'chirish</span>
              </button>

              {detailTarget.status === 'PENDING' && (
                <div className="flex gap-2">
                  <button
                    onClick={() => handleUpdateStatus(detailTarget.id, 'APPROVED')}
                    className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white font-extrabold rounded-xl transition flex items-center gap-1"
                  >
                    <Check size={14} />
                    <span>Tasdiqlash</span>
                  </button>
                  <button
                    onClick={() => handleUpdateStatus(detailTarget.id, 'REJECTED')}
                    className="px-4 py-2 bg-rose-50 hover:bg-rose-600 text-rose-700 hover:text-white font-extrabold rounded-xl transition flex items-center gap-1"
                  >
                    <X size={14} />
                    <span>Rad etish</span>
                  </button>
                </div>
              )}
            </div>

          </div>
        </div>
      )}

    </div>
  );
};

export default CoopModerationPanel;
