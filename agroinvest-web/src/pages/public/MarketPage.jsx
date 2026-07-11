import React from 'react';
import { ShoppingBag, ArrowUpRight, CheckCircle2, ShieldCheck, ShoppingCart } from 'lucide-react';

const MARKET_ITEMS = [
  { id: 1, category: "Yem-xashak", title: "Premium sifatdagi sershira beda toylari", price: "25 000 UZS / toy", stock: "Bor", supplier: "AgroFeed Ltd" },
  { id: 2, category: "Urug'chilik", title: "Kasalikka chidamli makkajo'xori urug'i", price: "120 000 UZS / kg", stock: "Bor", supplier: "Nukus Seeds Co" },
  { id: 3, category: "Texnika va jihozlar", title: "Tomchilatib sug'orish tizimi (1 gektar uchun)", price: "8 500 000 UZS", stock: "Buyurtma berish", supplier: "AgroDrip Tashkent" },
  { id: 4, category: "Hayvonlar parvarishi", title: "Golland zotli toza qonli buzoqlar", price: "15 000 000 UZS / bosh", stock: "Bor", supplier: "Samarkand Breeding Farm" },
];

const MarketPage = () => {
  return (
    <div className="min-h-screen bg-gray-50/40 dark:bg-slate-950 p-6 md:p-12 transition-all duration-300">
      <div className="max-w-6xl mx-auto space-y-8 animate-in fade-in duration-300">
        
        {/* Banner */}
        <div className="relative overflow-hidden p-8 md:p-10 border border-emerald-500/10 dark:border-slate-800 bg-gradient-to-br from-slate-900 via-slate-950 to-primary-950 text-white rounded-[32px] shadow-xl">
          <div className="absolute top-0 right-0 w-80 h-80 bg-primary-500/10 rounded-full blur-3xl -z-10" />
          <h1 className="text-2xl md:text-4xl font-black text-white tracking-tight flex items-center gap-2">
            <ShoppingBag className="text-primary-400" />
            <span>Agro-Market & Bozor</span>
          </h1>
          <p className="text-gray-305 text-xs md:text-sm mt-2 max-w-2xl leading-relaxed">
            Fermerlar uchun sifatli yem-xashak, urug'lar, zamonaviy qishloq xo'jaligi jihozlari va nasldor hayvonlarni ulgurji narxlarda xarid qilish bozori.
          </p>
        </div>

        {/* Catalog items */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {MARKET_ITEMS.map((item) => (
            <div key={item.id} className="bg-white dark:bg-slate-900 p-5 rounded-[24px] border border-gray-150/60 dark:border-slate-800/80 shadow-sm hover:shadow-md transition-all duration-300 flex flex-col justify-between group">
              <div>
                <span className="inline-block px-2 py-0.5 rounded-lg bg-primary-50 dark:bg-primary-950/40 text-primary-700 dark:text-primary-400 text-[10px] font-bold border border-primary-100/10">
                  {item.category}
                </span>
                <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-sm mt-3 leading-tight group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">
                  {item.title}
                </h3>
                <p className="text-[10px] text-gray-400 dark:text-slate-500 mt-1 font-semibold">Yetkazib beruvchi: {item.supplier}</p>
              </div>

              <div className="mt-5 space-y-3.5">
                <div className="flex justify-between items-center text-xs">
                  <span className="text-gray-400 font-bold">Narxi:</span>
                  <span className="font-black text-gray-950 dark:text-slate-100">{item.price}</span>
                </div>
                
                <div className="flex justify-between items-center text-xs">
                  <span className="text-gray-400 font-bold">Mavjudligi:</span>
                  <span className="inline-flex items-center gap-1 font-bold text-emerald-600 dark:text-emerald-450">
                    <CheckCircle2 size={12} /> {item.stock}
                  </span>
                </div>

                <button 
                  onClick={() => alert("Ushbu maxsulotni xarid qilish uchun platforma admin jamoasi bilan bog'laning.")}
                  className="w-full py-2.5 bg-gray-50 dark:bg-slate-950 hover:bg-primary-600 text-primary-700 dark:text-primary-400 hover:text-white dark:hover:text-white font-bold text-xs rounded-xl border border-primary-200/20 dark:border-slate-800/80 hover:border-transparent transition flex items-center justify-center gap-1.5"
                >
                  <ShoppingCart size={13} />
                  <span>Buyurtma berish</span>
                </button>
              </div>
            </div>
          ))}
        </div>

      </div>
    </div>
  );
};

export default MarketPage;
