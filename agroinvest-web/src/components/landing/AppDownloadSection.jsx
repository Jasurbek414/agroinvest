import React, { useEffect, useState } from 'react';
import { Smartphone, Download, CheckCircle, Apple, Play } from 'lucide-react';
import { getAppVersion } from '../../api/settings.api';

const AppDownloadSection = () => {
  const [versionInfo, setVersionInfo] = useState({
    versionName: '1.0.0',
    versionCode: 1,
    downloadUrl: '/agroinvest.apk',
    forceUpdate: false,
  });

  useEffect(() => {
    getAppVersion()
      .then((res) => {
        if (res.data) {
          setVersionInfo(res.data);
        }
      })
      .catch(() => {
        // Fallback to defaults
      });
  }, []);

  return (
    <section id="download-app" className="py-16 md:py-24 bg-gradient-to-br from-slate-900 via-slate-950 to-primary-950 text-white overflow-hidden relative">
      {/* Decorative background glow */}
      <div className="absolute top-1/2 left-1/4 -translate-y-1/2 w-96 h-96 bg-primary-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-10 right-10 w-80 h-80 bg-amber-500/5 rounded-full blur-3xl" />

      <div className="max-w-6xl mx-auto px-6 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          {/* Left Column: Visual Mockup */}
          <div className="lg:col-span-5 flex justify-center order-2 lg:order-1">
            <div className="relative w-64 h-[500px] bg-slate-800 rounded-[40px] p-3 shadow-2xl border-4 border-slate-700/80 ring-1 ring-slate-900/50">
              {/* Speaker & camera slot */}
              <div className="absolute top-0 left-1/2 -translate-x-1/2 h-5 w-32 bg-slate-900 rounded-b-xl z-20 flex items-center justify-center">
                <div className="w-12 h-1 bg-slate-800 rounded-full mb-1" />
                <div className="w-2.5 h-2.5 bg-slate-800 rounded-full ml-2 mb-1" />
              </div>
              
              {/* Screen Content Mockup */}
              <div className="w-full h-full bg-slate-950 rounded-[32px] overflow-hidden flex flex-col p-4 pt-8 select-none border border-slate-800">
                {/* Header info */}
                <div className="flex justify-between items-center text-[10px] text-gray-500 mb-4 px-2">
                  <span>9:41 AM</span>
                  <div className="flex gap-1">
                    <Smartphone size={10} />
                    <span>LTE</span>
                  </div>
                </div>

                {/* Logo & title inside mockup */}
                <div className="text-center mb-6 mt-2">
                  <span className="text-primary-400 font-extrabold text-lg tracking-tight">AgroInvest</span>
                  <div className="text-[10px] text-gray-400 mt-1">Investitsiyalar va loyihalar paneli</div>
                </div>

                {/* Mockup dashboard card */}
                <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-3 mb-3">
                  <div className="text-[9px] text-gray-500 uppercase tracking-wider">Mening Hamyonim</div>
                  <div className="text-sm font-bold text-slate-100 mt-1">12,500,000 UZS</div>
                  <div className="flex justify-between items-center mt-3 pt-2 border-t border-slate-800 text-[8px] text-primary-400 font-semibold">
                    <span>+14.2% o'sish</span>
                    <span>4 ta faol investitsiya</span>
                  </div>
                </div>

                {/* Mockup project item */}
                <div className="bg-slate-900/40 border border-slate-800/80 rounded-2xl p-3 flex-1 flex flex-col justify-between">
                  <div>
                    <div className="flex justify-between items-center mb-1.5">
                      <span className="text-[9px] font-bold text-amber-400 bg-amber-500/10 px-2 py-0.5 rounded-full">Chorvachilik</span>
                      <span className="text-[8px] text-gray-500">14 oyga</span>
                    </div>
                    <div className="text-[10px] font-bold text-slate-200 line-clamp-1">Hisor qo'ylari yetishtirish</div>
                    <div className="text-[8px] text-gray-400 mt-1 line-clamp-2">Loyiha doirasida zotdor Hisor qo'ylari sotib olinadi va parvarish qilinadi.</div>
                  </div>
                  
                  {/* Progress bar in mockup */}
                  <div className="mt-2">
                    <div className="flex justify-between text-[7px] text-gray-500 mb-1">
                      <span>72% yig'ildi</span>
                      <span>150,000,000 UZS</span>
                    </div>
                    <div className="w-full bg-slate-800 h-1 rounded-full overflow-hidden">
                      <div className="bg-primary-500 h-full w-[72%]" />
                    </div>
                  </div>
                </div>

                {/* Simulated bottom tab bar */}
                <div className="mt-4 pt-2.5 border-t border-slate-900 flex justify-around text-gray-600 text-[8px]">
                  <span className="text-primary-400 flex flex-col items-center gap-0.5"><Smartphone size={10} /><span>Asosiy</span></span>
                  <span className="flex flex-col items-center gap-0.5"><Smartphone size={10} /><span>Loyihalar</span></span>
                  <span className="flex flex-col items-center gap-0.5"><Smartphone size={10} /><span>Hamyon</span></span>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column: Text & Download Buttons */}
          <div className="lg:col-span-7 space-y-6 order-1 lg:order-2 text-center lg:text-left">
            <h2 className="text-3xl md:text-5xl font-extrabold tracking-tight leading-tight">
              AgroInvest Mobil Ilovasi bilan <br />
              <span className="text-primary-400">loyiha monitoringi har doim yoningizda</span>
            </h2>
            
            <p className="text-base text-gray-300 max-w-xl mx-auto lg:mx-0">
              Platformaning barcha imkoniyatlari — sarmoya kiritish, shartnoma imzolash, hisobotlarni topshirish va daromadlarni yechib olish endi yanada qulay va tezkor shaklda.
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 max-w-md mx-auto lg:mx-0">
              <div className="flex items-center gap-2.5 text-sm text-gray-200">
                <CheckCircle className="text-primary-400 shrink-0" size={18} />
                <span>Tezkor hisobotlar va bildirishnomalar</span>
              </div>
              <div className="flex items-center gap-2.5 text-sm text-gray-200">
                <CheckCircle className="text-primary-400 shrink-0" size={18} />
                <span>Biometrik (FaceID/TouchID) himoya</span>
              </div>
              <div className="flex items-center gap-2.5 text-sm text-gray-200">
                <CheckCircle className="text-primary-400 shrink-0" size={18} />
                <span>Kelishuv shartnomalarini OTP orqali imzolash</span>
              </div>
              <div className="flex items-center gap-2.5 text-sm text-gray-200">
                <CheckCircle className="text-primary-400 shrink-0" size={18} />
                <span>Sarmoya va daromadlar nazorati</span>
              </div>
            </div>

            {/* Version check info */}
            <div className="pt-2">
              <span className="inline-block px-3 py-1 rounded-full text-xs font-semibold bg-slate-800/80 border border-slate-700/50 text-gray-300">
                Joriy versiya: <strong className="text-primary-400">v{versionInfo.versionName}</strong> (Kod: {versionInfo.versionCode})
              </span>
            </div>

            {/* Action Buttons */}
            <div className="flex flex-col sm:flex-row items-center gap-4 pt-4 justify-center lg:justify-start">
              {/* Direct APK Download Button */}
              <a
                href={versionInfo.downloadUrl}
                download
                className="inline-flex items-center gap-3 px-8 py-4 rounded-2xl bg-primary-600 hover:bg-primary-500 text-white font-bold text-base shadow-xl shadow-primary-500/20 hover:shadow-primary-500/30 transition duration-200 w-full sm:w-auto justify-center group"
              >
                <Download size={20} className="group-hover:translate-y-0.5 transition-transform" />
                <div className="text-left">
                  <div className="text-[10px] text-primary-200 font-semibold uppercase tracking-wider leading-none">Android uchun</div>
                  <div className="text-sm font-extrabold mt-0.5">APK Yuklab Olish</div>
                </div>
              </a>

              {/* App Stores App coming soon */}
              <div className="flex gap-3 w-full sm:w-auto">
                <div className="relative opacity-60 cursor-not-allowed group bg-slate-800 border border-slate-700 px-5 py-3 rounded-2xl flex items-center gap-3 flex-1 sm:flex-initial">
                  <Play size={20} className="text-gray-400" />
                  <div className="text-left">
                    <span className="block text-[8px] text-gray-500 uppercase font-semibold">Google Play</span>
                    <span className="block text-xs font-bold text-gray-400">Tez kunda</span>
                  </div>
                </div>
                
                <div className="relative opacity-60 cursor-not-allowed group bg-slate-800 border border-slate-700 px-5 py-3 rounded-2xl flex items-center gap-3 flex-1 sm:flex-initial">
                  <Apple size={20} className="text-gray-400" />
                  <div className="text-left">
                    <span className="block text-[8px] text-gray-500 uppercase font-semibold">App Store</span>
                    <span className="block text-xs font-bold text-gray-400">Tez kunda</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
        </div>
      </div>
    </section>
  );
};

export default AppDownloadSection;
