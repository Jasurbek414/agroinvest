import React, { useState, useEffect } from 'react';
import { useAuthStore } from '../../store/auth.store';
import { useToast } from '../../components/ui/ToastProvider';
import { User, ShieldCheck, CreditCard, Building2, MapPin, CheckCircle2 } from 'lucide-react';

const SettingsPage = () => {
  const { user } = useAuthStore();
  const { showToast } = useToast();
  
  // State for all profile fields
  const [profile, setProfile] = useState({
    firstName: user?.firstName || '',
    lastName: user?.lastName || '',
    middleName: '',
    phone: user?.phone || '',
    email: '',
    birthDate: '',
    // Legal & Passport info
    passportSeries: '',
    passportNumber: '',
    pinfl: '', // JShShIR - 14 digits
    // Address info
    region: '',
    district: '',
    addressDetails: '',
    // Financial Payout Info
    cardNumber: '',
    cardExpiry: '',
    cardHolder: '',
    // Farm Details (only for Farmers)
    farmName: '',
    farmTin: '', // STIR - 9 digits
    farmLandArea: '', // in hectares
  });

  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (user?.id) {
      const saved = localStorage.getItem(`profile_details_${user.id}`);
      if (saved) {
        try {
          setProfile(JSON.parse(saved));
        } catch (e) {
          console.error(e);
        }
      }
    }
  }, [user]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setProfile(prev => ({ ...prev, [name]: value }));
  };

  const handleSave = (e) => {
    e.preventDefault();
    setLoading(true);
    
    // Simple validation
    if (profile.pinfl && profile.pinfl.length !== 14) {
      showToast("JShShIR (PINFL) 14 ta raqamdan iborat bo'lishi kerak", 'error');
      setLoading(false);
      return;
    }
    
    if (user?.id) {
      localStorage.setItem(`profile_details_${user.id}`, JSON.stringify(profile));
    }
    
    setTimeout(() => {
      setLoading(false);
      showToast("Shaxsiy ma'lumotlar to'liq va muvaffaqiyatli saqlandi!", 'success');
    }, 600);
  };

  return (
    <div className="min-h-screen bg-gray-50/40 dark:bg-slate-950 p-6 md:p-12 transition-all duration-300">
      <form onSubmit={handleSave} className="max-w-3xl mx-auto space-y-8 animate-in fade-in duration-300">
        
        {/* Title */}
        <div>
          <h1 className="text-2xl md:text-3xl font-black text-gray-950 dark:text-slate-100 tracking-tight">Profil Sozlamalari</h1>
          <p className="text-xs sm:text-sm text-gray-550 dark:text-slate-400 mt-1">
            Notarial va elektron shartnoma tuzish uchun shaxsiy ma'lumotlaringizni to'liq to'ldiring
          </p>
        </div>

        {/* Section 1: Personal Profile details */}
        <div className="bg-white dark:bg-slate-900 p-6 md:p-8 rounded-[28px] border border-gray-150/60 dark:border-slate-800/80 shadow-sm space-y-6">
          <div className="flex items-center gap-2 pb-3 border-b border-gray-100 dark:border-slate-800/60 text-primary-650 dark:text-primary-400 font-extrabold text-sm uppercase tracking-wide">
            <User size={16} />
            <span>Asosiy shaxsiy ma'lumotlar</span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 text-xs font-bold text-gray-700 dark:text-slate-300">
            <div className="space-y-1">
              <label>Familiya <span className="text-rose-500">*</span></label>
              <input 
                type="text" required name="lastName" value={profile.lastName} onChange={handleChange}
                className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>
            
            <div className="space-y-1">
              <label>Ism <span className="text-rose-500">*</span></label>
              <input 
                type="text" required name="firstName" value={profile.firstName} onChange={handleChange}
                className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>

            <div className="space-y-1">
              <label>Otasining ismi</label>
              <input 
                type="text" name="middleName" value={profile.middleName} onChange={handleChange}
                className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>

            <div className="space-y-1">
              <label>Telefon raqam <span className="text-rose-500">*</span></label>
              <input 
                type="text" required name="phone" value={profile.phone} onChange={handleChange}
                className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>

            <div className="space-y-1">
              <label>Email manzil</label>
              <input 
                type="email" name="email" value={profile.email} onChange={handleChange}
                placeholder="example@mail.ru"
                className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>

            <div className="space-y-1">
              <label>Tug'ilgan sana</label>
              <input 
                type="date" name="birthDate" value={profile.birthDate} onChange={handleChange}
                className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>
          </div>
        </div>

        {/* Section 2: Passport / PINFL Verification details */}
        <div className="bg-white dark:bg-slate-900 p-6 md:p-8 rounded-[28px] border border-gray-150/60 dark:border-slate-800/80 shadow-sm space-y-6">
          <div className="flex items-center gap-2 pb-3 border-b border-gray-100 dark:border-slate-800/60 text-primary-650 dark:text-primary-400 font-extrabold text-sm uppercase tracking-wide">
            <ShieldCheck size={16} />
            <span>Pasport & JShShIR (PINFL) tekshiruvi</span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 text-xs font-bold text-gray-700 dark:text-slate-300">
            <div className="space-y-1">
              <label>Pasport seriyasi</label>
              <input 
                type="text" name="passportSeries" value={profile.passportSeries} onChange={handleChange} placeholder="AA"
                maxLength={2} className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500 uppercase"
              />
            </div>

            <div className="space-y-1">
              <label>Pasport raqami</label>
              <input 
                type="text" name="passportNumber" value={profile.passportNumber} onChange={handleChange} placeholder="1234567"
                maxLength={7} className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>

            <div className="space-y-1">
              <label>JShShIR (PINFL) <span className="text-rose-500">*</span></label>
              <input 
                type="text" name="pinfl" value={profile.pinfl} onChange={handleChange} placeholder="14 xonali son"
                maxLength={14} className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>
          </div>
        </div>

        {/* Section 3: Legal Address Details */}
        <div className="bg-white dark:bg-slate-900 p-6 md:p-8 rounded-[28px] border border-gray-150/60 dark:border-slate-800/80 shadow-sm space-y-6">
          <div className="flex items-center gap-2 pb-3 border-b border-gray-100 dark:border-slate-800/60 text-primary-650 dark:text-primary-400 font-extrabold text-sm uppercase tracking-wide">
            <MapPin size={16} />
            <span>Doimiy ro'yxatdan o'tgan manzili</span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 text-xs font-bold text-gray-700 dark:text-slate-300">
            <div className="space-y-1">
              <label>Viloyat</label>
              <input 
                type="text" name="region" value={profile.region} onChange={handleChange} placeholder="Toshkent vil."
                className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>

            <div className="space-y-1">
              <label>Tuman / Shahar</label>
              <input 
                type="text" name="district" value={profile.district} onChange={handleChange} placeholder="Qibray tumani"
                className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>

            <div className="space-y-1">
              <label>Ko'cha, uy / xonadon</label>
              <input 
                type="text" name="addressDetails" value={profile.addressDetails} onChange={handleChange} placeholder="Navro'z ko'chasi, 24-uy"
                className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>
          </div>
        </div>

        {/* Section 4: Bank details (For investment returns & payouts) */}
        <div className="bg-white dark:bg-slate-900 p-6 md:p-8 rounded-[28px] border border-gray-150/60 dark:border-slate-800/80 shadow-sm space-y-6">
          <div className="flex items-center gap-2 pb-3 border-b border-gray-100 dark:border-slate-800/60 text-primary-650 dark:text-primary-400 font-extrabold text-sm uppercase tracking-wide">
            <CreditCard size={16} />
            <span>Pul o'tkazmalari uchun bank kartasi (Humo / Uzcard)</span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 text-xs font-bold text-gray-700 dark:text-slate-300">
            <div className="space-y-1">
              <label>Karta raqami</label>
              <input 
                type="text" name="cardNumber" value={profile.cardNumber} onChange={handleChange} placeholder="8600 ...."
                maxLength={16} className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>

            <div className="space-y-1">
              <label>Amal qilish muddati</label>
              <input 
                type="text" name="cardExpiry" value={profile.cardExpiry} onChange={handleChange} placeholder="MM/YY"
                maxLength={5} className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
              />
            </div>

            <div className="space-y-1">
              <label>Karta egasining F.I.Sh</label>
              <input 
                type="text" name="cardHolder" value={profile.cardHolder} onChange={handleChange} placeholder="ESHMURADOV ESHMAT"
                className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500 uppercase"
              />
            </div>
          </div>
        </div>

        {/* Section 5: Farm Details (Only visible to Farmers) */}
        {user?.role === 'FARMER' && (
          <div className="bg-white dark:bg-slate-900 p-6 md:p-8 rounded-[28px] border border-gray-150/60 dark:border-slate-800/80 shadow-sm space-y-6">
            <div className="flex items-center gap-2 pb-3 border-b border-gray-100 dark:border-slate-800/60 text-primary-650 dark:text-primary-400 font-extrabold text-sm uppercase tracking-wide">
              <Building2 size={16} />
              <span>Yuridik dehqon/fermer xo'jaligi ma'lumotlari</span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 text-xs font-bold text-gray-700 dark:text-slate-300">
              <div className="space-y-1">
                <label>Fermer xo'jaligi nomi <span className="text-rose-500">*</span></label>
                <input 
                  type="text" required={user?.role === 'FARMER'} name="farmName" value={profile.farmName} onChange={handleChange} placeholder="GOLDEN CATTLE FX"
                  className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
                />
              </div>

              <div className="space-y-1">
                <label>Xo'jalik STIR (TIN) <span className="text-rose-500">*</span></label>
                <input 
                  type="text" required={user?.role === 'FARMER'} name="farmTin" value={profile.farmTin} onChange={handleChange} placeholder="9 xonali STIR"
                  maxLength={9} className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
                />
              </div>

              <div className="space-y-1">
                <label>Er maydoni (Gektar) <span className="text-rose-500">*</span></label>
                <input 
                  type="number" required={user?.role === 'FARMER'} name="farmLandArea" value={profile.farmLandArea} onChange={handleChange} placeholder="25"
                  className="w-full p-3 rounded-xl border border-gray-200 dark:border-slate-800 bg-gray-50/20 dark:bg-slate-955 text-xs font-semibold focus:ring-1 focus:ring-primary-500"
                />
              </div>
            </div>
          </div>
        )}

        {/* Submit */}
        <div className="flex justify-end pt-4">
          <button
            type="submit"
            disabled={loading}
            className="px-8 py-3.5 bg-primary-600 hover:bg-primary-500 text-white font-extrabold text-xs rounded-xl shadow-md transition duration-200 disabled:opacity-50"
          >
            {loading ? "Saqlanmoqda..." : "Profil Ma'lumotlarini Saqlash"}
          </button>
        </div>

      </form>
    </div>
  );
};

export default SettingsPage;
