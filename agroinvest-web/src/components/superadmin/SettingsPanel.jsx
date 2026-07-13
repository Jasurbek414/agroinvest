import React, { useEffect, useState } from 'react';
import { updatePlatformSetting, updateInvestorFarmerShares } from '../../api/superadmin.api';
import Button from '../ui/Button';
import Card from '../ui/Card';
import Input from '../ui/Input';
import { useToast } from '../ui/ToastProvider';

const SHARE_KEYS = ['default_investor_share_pct', 'default_farmer_share_pct'];

const SETTING_LABELS = {
  default_commission_pct: 'Platforma komissiyasi (%)',
  min_investment_amount: "Minimal investitsiya summasi (so'm)",
  max_investment_cancel_hours: 'Bekor qilish oynasi (soat)',
  report_frequency_days: 'Hisobot chastotasi (kun)',
  otp_expiry_minutes: 'OTP amal qilish muddati (daqiqa)',
  max_otp_attempts: 'OTP urinishlar soni',
  jwt_access_expiry_seconds: 'JWT access token muddati (sekund)',
  jwt_refresh_expiry_days: 'JWT refresh token muddati (kun)',
  app_version_code: 'Mobil ilova versiya kodi (versionCode)',
  app_version_name: 'Mobil ilova versiya nomi (versionName)',
  app_download_url: 'Mobil ilova yuklab olish manzili (APK URL)',
  app_force_update: 'Mobil ilovani majburiy yangilash (true/false)',
  company_bank_details: 'Kompaniya bank hisob raqami rekvizitlari',
  company_bank_doc_url: 'Kompaniya bank rekvizitlari hujjati (.pdf/.jpg) URL',
};

const isNumeric = (value) => value !== '' && !Number.isNaN(Number(value));

// Row for a single numeric setting: inline number input + Save, instead of the
// old one-size PromptDialog with zero type/range validation.
const SettingRow = ({ setting, onSave }) => {
  const [value, setValue] = useState(setting.settingValue);
  const [saving, setSaving] = useState(false);
  const dirty = value !== setting.settingValue;
  const numeric = isNumeric(setting.settingValue);

  const handleSave = async () => {
    if (numeric && !isNumeric(value)) return;
    setSaving(true);
    try {
      await onSave(setting.settingKey, value);
    } finally {
      setSaving(false);
    }
  };

  const isTextarea = setting.settingKey === 'company_bank_details';
  const isUrl = setting.settingKey === 'company_bank_doc_url' || setting.settingKey === 'app_download_url';

  return (
    <div className="flex items-start justify-between gap-3 border-b border-gray-100 dark:border-slate-700 pb-3 text-sm">
      <div className="flex-1 min-w-0">
        <p className="font-bold text-gray-800 dark:text-slate-200 text-xs">
          {SETTING_LABELS[setting.settingKey] || setting.settingKey}
        </p>
        {isTextarea ? (
          <textarea
            value={value}
            rows={3}
            onChange={(e) => setValue(e.target.value)}
            className="mt-1.5 w-full px-2.5 py-1.5 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-900 dark:text-slate-100 rounded-lg text-xs outline-none focus:ring-1 focus:ring-primary-500 whitespace-pre-wrap"
          />
        ) : (
          <input
            type={numeric ? 'number' : 'text'}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            className={`mt-1.5 ${isUrl ? 'w-full max-w-md' : 'w-40'} px-2.5 py-1.5 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-900 dark:text-slate-100 rounded-lg text-sm outline-none focus:ring-1 focus:ring-primary-500`}
          />
        )}
      </div>
      <div className="pt-5">
        <Button variant="secondary" size="sm" disabled={!dirty || saving} onClick={handleSave}>
          {saving ? 'Saqlanmoqda...' : 'Saqlash'}
        </Button>
      </div>
    </div>
  );
};

const SettingsPanel = ({ settings, onChanged }) => {
  const { showToast } = useToast();
  const shareSettings = settings.filter((s) => SHARE_KEYS.includes(s.settingKey));
  const otherSettings = settings.filter((s) => !SHARE_KEYS.includes(s.settingKey));

  const investorShare = shareSettings.find((s) => s.settingKey === 'default_investor_share_pct')?.settingValue;
  const farmerShare = shareSettings.find((s) => s.settingKey === 'default_farmer_share_pct')?.settingValue;
  const [investorPct, setInvestorPct] = useState(investorShare ?? '');
  const [farmerPct, setFarmerPct] = useState(farmerShare ?? '');
  const [savingShares, setSavingShares] = useState(false);

  useEffect(() => { setInvestorPct(investorShare ?? ''); }, [investorShare]);
  useEffect(() => { setFarmerPct(farmerShare ?? ''); }, [farmerShare]);

  const sharesSum = Number(investorPct) + Number(farmerPct);
  const sharesValid = isNumeric(investorPct) && isNumeric(farmerPct) && sharesSum === 100;

  const handleSaveSetting = async (key, value) => {
    try {
      await updatePlatformSetting(key, value);
      showToast('Platforma sozlamasi muvaffaqiyatli yangilandi');
      onChanged?.();
    } catch (err) {
      showToast(err.error?.message || "Sozlamani o'zgartirishda xatolik", 'error');
    }
  };

  const handleSaveShares = async () => {
    if (!sharesValid) return;
    setSavingShares(true);
    try {
      await updateInvestorFarmerShares(Number(investorPct), Number(farmerPct));
      showToast('Investor va fermer ulushlari yangilandi');
      onChanged?.();
    } catch (err) {
      showToast(err.error?.message || "Ulushlarni o'zgartirishda xatolik", 'error');
    } finally {
      setSavingShares(false);
    }
  };

  return (
    <Card>
      <h2 className="text-lg font-bold text-gray-900 dark:text-slate-100 mb-4">Sozlamalar</h2>

      {shareSettings.length > 0 && (
        <div className="mb-5 p-4 rounded-xl border border-gray-100 dark:border-slate-700 bg-gray-50/60 dark:bg-slate-900/40 space-y-3">
          <p className="text-xs font-bold text-gray-600 dark:text-slate-300 uppercase">Foyda taqsimoti ulushlari</p>
          <p className="text-[11px] text-gray-500 dark:text-slate-400">
            Yig'indisi aynan 100% bo'lishi shart - ikkalasi birgalikda saqlanadi.
          </p>
          <div className="flex items-end gap-3">
            <Input
              label="Investor ulushi (%)"
              type="number"
              value={investorPct}
              onChange={(e) => setInvestorPct(e.target.value)}
              containerClassName="flex-1"
            />
            <Input
              label="Fermer ulushi (%)"
              type="number"
              value={farmerPct}
              onChange={(e) => setFarmerPct(e.target.value)}
              containerClassName="flex-1"
            />
          </div>
          <div className="flex items-center justify-between">
            <span className={`text-xs font-bold ${sharesValid ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
              Yig'indi: {Number.isFinite(sharesSum) ? sharesSum : '—'}%
            </span>
            <Button size="sm" disabled={!sharesValid || savingShares} onClick={handleSaveShares}>
              {savingShares ? 'Saqlanmoqda...' : 'Ulushlarni saqlash'}
            </Button>
          </div>
        </div>
      )}

      <div className="space-y-4">
        {otherSettings.map((s) => (
          <SettingRow key={s.id} setting={s} onSave={handleSaveSetting} />
        ))}
      </div>
    </Card>
  );
};

export default SettingsPanel;
