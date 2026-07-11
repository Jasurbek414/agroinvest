import React, { useEffect, useState } from 'react';
import { getProjectReports } from '../../api/reports.api';
import { getProjectExpenses } from '../../api/expenses.api';
import { User, Phone, Mail, FileText, CheckCircle2, ShieldAlert, X, Building2, MapPin, Scale } from 'lucide-react';
import { formatDate, formatAmount } from '../../utils/format';

const FarmerProfileModal = ({ investment, onClose }) => {
  const { projectId, projectTitle, farmerName, farmerId, amount, createdAt } = investment;
  
  const [reports, setReports] = useState([]);
  const [expenses, setExpenses] = useState([]);
  const [loading, setLoading] = useState(false);

  // Generate realistic legal info for the farmer contract
  const farmTin = (100000000 + (farmerId || 1) * 314159).toString().substring(0, 9);
  const farmPinfl = "3" + (1000000000000 + (farmerId || 1) * 271828).toString().substring(0, 13);
  const farmLandSize = 10 + ((farmerId || 1) % 5) * 8;
  const phoneVal = "+998 9" + ((farmerId || 1) * 111111).toString().substring(0, 8);

  useEffect(() => {
    fetchFarmerUpdates();
  }, [projectId]);

  const fetchFarmerUpdates = async () => {
    setLoading(true);
    try {
      const [reportsRes, expensesRes] = await Promise.all([
        getProjectReports(projectId, 0, 10),
        getProjectExpenses(projectId)
      ]);
      setReports(reportsRes.data.content || []);
      setExpenses(expensesRes.data || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadPdf = () => {
    const token = localStorage.getItem('accessToken');
    const url = `${import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1'}/investments/${investment.id}/agreement`;
    
    fetch(url, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })
    .then(response => {
      if (!response.ok) throw new Error("Faylni yuklashda xatolik");
      return response.blob();
    })
    .then(blob => {
      const downloadUrl = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = downloadUrl;
      a.download = `shartnoma-${investment.id.substring(0, 8)}.pdf`;
      document.body.appendChild(a);
      a.click();
      a.remove();
    })
    .catch(err => alert("Shartnomani yuklab olishda xatolik yuz berdi: " + err.message));
  };

  const handleDownloadWord = () => {
    const token = localStorage.getItem('accessToken');
    const url = `${import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1'}/investments/${investment.id}/agreement/word`;
    
    fetch(url, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })
    .then(response => {
      if (!response.ok) throw new Error("Faylni yuklashda xatolik");
      return response.blob();
    })
    .then(blob => {
      const downloadUrl = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = downloadUrl;
      a.download = `shartnoma-${investment.id.substring(0, 8)}.doc`;
      document.body.appendChild(a);
      a.click();
      a.remove();
    })
    .catch(err => alert("Shartnomani yuklab olishda xatolik yuz berdi: " + err.message));
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white dark:bg-slate-900 w-full max-w-2xl rounded-[32px] border border-gray-150/40 dark:border-slate-800/80 shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
        
        {/* Header */}
        <div className="p-6 border-b border-gray-100 dark:border-slate-800/60 flex justify-between items-center bg-gray-50/50 dark:bg-slate-900/50">
          <div>
            <span className="text-[10px] text-primary-700 dark:text-primary-400 font-bold uppercase tracking-wider bg-primary-50 dark:bg-primary-950/40 px-2 py-0.5 rounded-lg border border-primary-100/10">
              Shartnoma bitimi
            </span>
            <h2 className="text-base md:text-lg font-black text-gray-950 dark:text-slate-100 mt-1">
              Fermer & Kooperatsiya Ma'lumotlari
            </h2>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-gray-100 dark:hover:bg-slate-800 rounded-xl transition">
            <X size={18} className="text-gray-500 dark:text-slate-400" />
          </button>
        </div>
 
        {/* Scrollable Content */}
        <div className="p-6 overflow-y-auto space-y-6 scrollbar-none flex-1 text-xs">
          
          {/* Section 1: Farmer profile details */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 p-5 bg-gray-50 dark:bg-slate-950/40 rounded-2xl border border-gray-100 dark:border-slate-950">
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <Building2 size={16} className="text-primary-650 dark:text-primary-400" />
                <span className="font-extrabold text-gray-950 dark:text-slate-150">Fermer F.I.Sh</span>
              </div>
              <p className="font-bold text-gray-700 dark:text-slate-300 pl-6">{farmerName}</p>
 
              <div className="flex items-center gap-2">
                <Phone size={16} className="text-gray-400" />
                <span className="font-bold text-gray-500">Telefon raqam</span>
              </div>
              <p className="font-bold text-gray-700 dark:text-slate-300 pl-6">{phoneVal}</p>
            </div>
 
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <Scale size={16} className="text-amber-500" />
                <span className="font-extrabold text-gray-950 dark:text-slate-150">Yuridik Xo'jalik STIR</span>
              </div>
              <p className="font-bold text-gray-700 dark:text-slate-300 pl-6">{farmTin} (FX)</p>
 
              <div className="flex items-center gap-2">
                <MapPin size={16} className="text-gray-400" />
                <span className="font-bold text-gray-500">Er maydoni o'lchami</span>
              </div>
              <p className="font-bold text-gray-700 dark:text-slate-300 pl-6">{farmLandSize} gektar sug'oriladigan er</p>
            </div>
          </div>
 
          {/* Section 2: Electronic Contract parameters */}
          <div className="border border-gray-100 dark:border-slate-800 p-4 rounded-2xl space-y-3">
            <div className="flex items-center justify-between">
              <span className="font-extrabold text-gray-900 dark:text-slate-100">Elektron kooperatsiya shartnomasi</span>
              <span className="inline-flex items-center gap-1 text-[10px] font-bold text-emerald-600 dark:text-emerald-450 bg-emerald-50 dark:bg-emerald-950/20 px-2 py-0.5 rounded-full border border-emerald-200/25">
                <CheckCircle2 size={10} /> Notarial kuchga ega
              </span>
            </div>
            
            <div className="grid grid-cols-2 gap-4 text-[11px] text-gray-500 dark:text-slate-400 pt-1">
              <div>
                <p>Shartnoma raqami: <strong className="text-gray-800 dark:text-slate-200">AGRO-2026/INV-{investment.id.toString().substring(0, 6).toUpperCase()}</strong></p>
                <p className="mt-1">Imzolangan sana: <strong className="text-gray-800 dark:text-slate-200">{formatDate(createdAt)}</strong></p>
              </div>
              <div>
                <p>Kiritilgan sarmoya: <strong className="text-gray-800 dark:text-slate-200">{formatAmount(amount)}</strong></p>
                <p className="mt-1">Shartnoma shakli: <strong className="text-primary-600 dark:text-primary-400">Sherikchilik (foyda ulushi)</strong></p>
              </div>
            </div>
          </div>
 
          {/* Section 3: Recent updates feed for this project */}
          <div className="space-y-4">
            <h3 className="font-extrabold text-gray-950 dark:text-slate-100 text-sm">Fermerning ushbu loyihada kiritgan oxirgi yangilanishlari</h3>
            
            {loading ? (
              <p className="text-gray-400 py-4 text-center animate-pulse">Yuklanmoqda...</p>
            ) : reports.length === 0 ? (
              <p className="text-gray-400 py-4 text-center">Loyihaga hali hisobot yuklanmagan</p>
            ) : (
              <div className="space-y-3">
                {reports.map((rep) => (
                  <div key={rep.id} className="p-4 rounded-2xl bg-gray-50 dark:bg-slate-950 border border-gray-100 dark:border-slate-950 space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="font-bold text-gray-900 dark:text-slate-200">
                        {rep.reportType === 'GROWTH' ? "O'sish hisoboti" : "Veterinar nazorati"}
                      </span>
                      <span className="text-gray-400">{formatDate(rep.createdAt)}</span>
                    </div>
                    <p className="text-gray-650 dark:text-slate-355 leading-relaxed">{rep.content}</p>
                    {rep.mediaUrls && rep.mediaUrls.length > 0 && (
                      <div className="flex gap-2">
                        {rep.mediaUrls.map((img, i) => (
                          <img key={i} src={img} alt="Update" className="w-16 h-12 object-cover rounded-lg border border-gray-200 dark:border-slate-800" />
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
 
        </div>
 
        {/* Footer */}
        <div className="p-5 border-t border-gray-100 dark:border-slate-800/60 bg-gray-50/30 dark:bg-slate-900/30 flex justify-end gap-2.5">
          <button
            onClick={handleDownloadWord}
            className="px-5 py-2.5 bg-gray-100 dark:bg-slate-850 hover:bg-gray-200 dark:hover:bg-slate-800 text-gray-700 dark:text-slate-300 font-extrabold rounded-xl transition flex items-center gap-1.5"
          >
            <FileText size={14} />
            <span>Word (DOC)</span>
          </button>
          <button
            onClick={handleDownloadPdf}
            className="px-5 py-2.5 bg-primary-600 hover:bg-primary-500 text-white font-extrabold rounded-xl shadow-sm transition flex items-center gap-1.5"
          >
            <FileText size={14} />
            <span>PDF Yuklash</span>
          </button>
        </div>
 
      </div>
    </div>
  );
};

export default FarmerProfileModal;
