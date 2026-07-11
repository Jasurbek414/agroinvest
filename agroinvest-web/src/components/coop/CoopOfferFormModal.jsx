import React, { useState } from 'react';
import { createCoopOffer } from '../../api/coop.api';
import { useToast } from '../../components/ui/ToastProvider';
import { X, Check } from 'lucide-react';

const CoopOfferFormModal = ({ onClose, onSaved }) => {
  const { showToast } = useToast();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    type: 'BUSINESS_PLAN', // default
    amount: '',
    contactPhone: '',
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.title.trim() || !formData.description.trim() || !formData.amount || !formData.contactPhone.trim()) {
      showToast("Iltimos, barcha maydonlarni to'ldiring.", 'error');
      return;
    }

    setLoading(true);
    try {
      await createCoopOffer({
        title: formData.title.trim(),
        description: formData.description.trim(),
        type: formData.type,
        amount: parseFloat(formData.amount),
        contactPhone: formData.contactPhone.trim(),
      });
      showToast("Taklif muvaffaqiyatli topshirildi va moderator tekshiruviga yuborildi!", 'success');
      onSaved?.();
    } catch (err) {
      showToast(err.error?.message || "Xatolik yuz berdi.", 'error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-950/60 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-in fade-in duration-200">
      <div className="bg-white dark:bg-slate-900 rounded-[32px] border border-gray-150/40 dark:border-slate-800/80 shadow-2xl max-w-md w-full p-6 space-y-4 max-h-[90vh] overflow-y-auto scrollbar-none">
        
        <div className="flex justify-between items-center pb-3 border-b border-gray-100 dark:border-slate-800/60">
          <div>
            <span className="text-[10px] text-primary-700 dark:text-primary-400 font-bold uppercase tracking-wider bg-primary-50 dark:bg-primary-950/40 px-2 py-0.5 rounded-lg">
              Yangi taklif qo'shish
            </span>
            <h3 className="font-black text-gray-950 dark:text-slate-100 text-base mt-1">Investitsiya bozori arizasi</h3>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-gray-100 dark:hover:bg-slate-800 rounded-xl transition">
            <X size={16} className="text-gray-500 dark:text-slate-400" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4 text-xs font-bold text-gray-700 dark:text-slate-350">
          
          <div className="space-y-1.5">
            <label>Sarlavha (Nomi) <span className="text-rose-500">*</span></label>
            <input
              type="text" required name="title" value={formData.title} onChange={handleChange}
              placeholder="Masalan: 12% foyda ulushli nasldor chorvachilik biznes rejasi"
              className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
            />
          </div>

          <div className="space-y-1.5">
            <label>Bo'lim turi <span className="text-rose-500">*</span></label>
            <select
              name="type" value={formData.type} onChange={handleChange}
              className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
            >
              <option value="BUSINESS_PLAN">Biznes reja / Loyiha loyihasi</option>
              <option value="INVESTOR_OFFER">Investor sarmoyaviy taklifi (Pul taklif qilish)</option>
              <option value="CONTRACT_SALE">Tayyor shartnomalar & Loyihalar savdosi</option>
            </select>
          </div>

          <div className="space-y-1.5">
            <label>Summa (UZS) <span className="text-rose-500">*</span></label>
            <input
              type="number" required name="amount" value={formData.amount} onChange={handleChange}
              placeholder="Masalan: 150000000"
              className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
            />
          </div>

          <div className="space-y-1.5">
            <label>Bog'lanish uchun telefon <span className="text-rose-500">*</span></label>
            <input
              type="text" required name="contactPhone" value={formData.contactPhone} onChange={handleChange}
              placeholder="+998 90 123 45 67"
              className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
            />
          </div>

          <div className="space-y-1.5">
            <label>Taklif tavsifi va batafsil reja <span className="text-rose-500">*</span></label>
            <textarea
              required name="description" value={formData.description} onChange={handleChange} rows={5}
              placeholder="Biznesning asosiy maqsadi, joylashuvi, foyda taqsimoti, risklar va kutilayotgan daromad haqida batafsil ma'lumot kiriting..."
              className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500 resize-y"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3.5 bg-primary-600 hover:bg-primary-500 disabled:opacity-40 text-white font-extrabold text-xs rounded-xl shadow-md transition flex items-center justify-center gap-2"
          >
            <span>{loading ? "Yuborilmoqda..." : "Tasdiqlash & Yuborish"}</span>
          </button>
        </form>

      </div>
    </div>
  );
};

export default CoopOfferFormModal;
