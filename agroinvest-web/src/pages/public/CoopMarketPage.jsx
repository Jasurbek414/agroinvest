import React, { useEffect, useState } from 'react';
import { getActiveCoopOffers } from '../../api/coop.api';
import { useAuthStore } from '../../store/auth.store';
import CoopOfferCard from '../../components/coop/CoopOfferCard';
import CoopOfferFormModal from '../../components/coop/CoopOfferFormModal';
import { BarChart3, Plus, Globe, Sparkles, HelpCircle, Layers } from 'lucide-react';

const CoopMarketPage = () => {
  const { user } = useAuthStore();
  const [offers, setOffers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('ALL'); // 'ALL' | 'BUSINESS_PLAN' | 'INVESTOR_OFFER' | 'CONTRACT_SALE'
  const [formOpen, setFormOpen] = useState(false);

  useEffect(() => {
    fetchOffers();
  }, [activeTab]);

  const fetchOffers = async () => {
    setLoading(true);
    try {
      const typeParam = activeTab === 'ALL' ? '' : activeTab;
      const res = await getActiveCoopOffers(typeParam);
      setOffers(res.data.content || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50/40 dark:bg-slate-950 p-6 md:p-12 transition-all duration-300">
      <div className="max-w-6xl mx-auto space-y-8 animate-in fade-in duration-300">
        
        {/* Banner */}
        <div className="relative overflow-hidden p-8 md:p-10 border border-emerald-500/10 dark:border-slate-800 bg-gradient-to-br from-slate-900 via-slate-950 to-primary-950 text-white rounded-[32px] shadow-xl flex flex-col md:flex-row justify-between md:items-center gap-6">
          <div className="absolute top-0 right-0 w-80 h-80 bg-primary-500/10 rounded-full blur-3xl -z-10" />
          <div className="space-y-2">
            <h1 className="text-2xl md:text-4xl font-black text-white tracking-tight flex items-center gap-2">
              <BarChart3 className="text-primary-400" />
              <span>Investitsiya bozori</span>
            </h1>
            <p className="text-gray-305 text-xs md:text-sm max-w-xl leading-relaxed">
              Platforma ichidagi yangi biznes kooperatsiya bozori. Bu yerda tayyor investitsiyalar, shartnomalar savdosi, investorlar sarmoyalari va biznes-rejalar katalogi joylashgan.
            </p>
          </div>

          {user && (
            <button
              onClick={() => setFormOpen(true)}
              className="px-5 py-3.5 bg-primary-500 hover:bg-primary-400 text-white font-extrabold text-xs rounded-xl shadow-lg hover:shadow-primary-500/20 transition flex items-center justify-center gap-1.5 shrink-0 self-start md:self-center"
            >
              <Plus size={16} />
              <span>E'lon / Taklif joylash</span>
            </button>
          )}
        </div>

        {/* Tab switchers */}
        <div className="flex flex-wrap items-center gap-2 p-1.5 bg-white dark:bg-slate-900 border border-gray-150/40 dark:border-slate-800/80 rounded-2xl">
          {[
            { id: 'ALL', label: 'Barchasi' },
            { id: 'BUSINESS_PLAN', label: 'Biznes Rejalar' },
            { id: 'INVESTOR_OFFER', label: 'Investor takliflari' },
            { id: 'CONTRACT_SALE', label: 'Tayyor shartnomalar' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`px-4 py-2 text-xs font-black rounded-xl transition-all duration-200 ${
                activeTab === tab.id
                  ? 'bg-primary-600 text-white'
                  : 'text-gray-500 dark:text-slate-400 hover:bg-gray-50 dark:hover:bg-slate-950'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Catalog */}
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20 space-y-3">
            <div className="w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin" />
            <p className="text-xs text-gray-550 dark:text-slate-400 font-bold animate-pulse">Yuklanmoqda...</p>
          </div>
        ) : offers.length === 0 ? (
          <div className="text-center py-20 bg-white dark:bg-slate-900 rounded-[28px] border border-gray-150/40 dark:border-slate-800/80">
            <HelpCircle size={40} className="text-gray-300 dark:text-slate-700 mx-auto" />
            <p className="text-xs text-gray-400 dark:text-slate-500 font-extrabold mt-3">Ushbu bo'limda hozircha tasdiqlangan e'lonlar mavjud emas.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {offers.map((offer) => (
              <CoopOfferCard key={offer.id} offer={offer} />
            ))}
          </div>
        )}

        {/* Modal form */}
        {formOpen && (
          <CoopOfferFormModal
            onClose={() => setFormOpen(false)}
            onSaved={() => {
              setFormOpen(false);
              fetchOffers();
            }}
          />
        )}

      </div>
    </div>
  );
};

export default CoopMarketPage;
