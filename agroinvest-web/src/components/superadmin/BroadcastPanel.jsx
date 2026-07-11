import React, { useState } from 'react';
import { Megaphone, Send } from 'lucide-react';
import { broadcastNotification } from '../../api/superadmin.api';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import ConfirmDialog from '../ui/ConfirmDialog';
import { useToast } from '../ui/ToastProvider';

const AUDIENCE_OPTIONS = [
  { value: '', label: 'Barcha foydalanuvchilar' },
  { value: 'INVESTOR', label: 'Sarmoyadorlar' },
  { value: 'FARMER', label: 'Fermerlar' },
  { value: 'ADMIN', label: 'Adminlar' },
  { value: 'MODERATOR', label: 'Moderatorlar' },
  { value: 'VERIFIER', label: 'Verifikatorlar' },
];

const CHANNEL_OPTIONS = [
  { value: 'IN_APP', label: 'Ilova ichida (tavsiya etiladi)' },
  { value: 'PUSH', label: 'Push-bildirishnoma' },
  { value: 'SMS', label: 'SMS' },
  { value: 'TELEGRAM', label: 'Telegram' },
];

const selectClasses = 'w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500 focus:border-primary-500';

// SuperAdmin announcement blast: one message to every (non-blocked) user of the
// chosen audience via POST /superadmin/broadcast.
const BroadcastPanel = () => {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [role, setRole] = useState('');
  const [channel, setChannel] = useState('IN_APP');
  const [confirming, setConfirming] = useState(false);
  const [sending, setSending] = useState(false);
  const { showToast } = useToast();

  const audienceLabel = AUDIENCE_OPTIONS.find((o) => o.value === role)?.label || 'Barcha foydalanuvchilar';

  const handleSend = async () => {
    setConfirming(false);
    setSending(true);
    try {
      const res = await broadcastNotification({ title: title.trim(), message: message.trim(), role: role || undefined, channel });
      showToast(`Xabarnoma ${res.data?.recipients ?? 0} ta foydalanuvchiga yuborildi`);
      setTitle('');
      setMessage('');
    } catch (err) {
      showToast(err.error?.message || 'Xabarnoma yuborishda xatolik yuz berdi', 'error');
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="max-w-2xl">
      <Card padded={false} className="overflow-hidden">
        <div className="p-6 border-b border-gray-100 dark:border-slate-700 flex items-center gap-3">
          <span className="w-10 h-10 rounded-xl bg-primary-50 dark:bg-primary-950 text-primary-600 dark:text-primary-400 flex items-center justify-center shrink-0">
            <Megaphone size={18} />
          </span>
          <div>
            <h2 className="text-lg font-bold text-gray-900 dark:text-slate-100">Ommaviy xabarnoma</h2>
            <p className="text-xs text-gray-500 dark:text-slate-400">Tanlangan auditoriyaning barcha faol foydalanuvchilariga yuboriladi</p>
          </div>
        </div>

        <form
          className="p-6 space-y-4"
          onSubmit={(e) => { e.preventDefault(); setConfirming(true); }}
        >
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Auditoriya</label>
              <select value={role} onChange={(e) => setRole(e.target.value)} className={selectClasses}>
                {AUDIENCE_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Yuborish kanali</label>
              <select value={channel} onChange={(e) => setChannel(e.target.value)} className={selectClasses}>
                {CHANNEL_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
          </div>

          <Input
            label="Sarlavha"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Masalan: Texnik ishlar haqida"
            maxLength={120}
            required
          />

          <div>
            <label className="block text-xs font-semibold text-gray-600 dark:text-slate-400 mb-1.5">Xabar matni</label>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              rows={5}
              maxLength={1000}
              required
              placeholder="Foydalanuvchilarga yuboriladigan xabar matni..."
              className="w-full px-3.5 py-2.5 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-900 dark:text-slate-100 rounded-xl text-sm outline-none focus:ring-1 focus:ring-primary-500 focus:border-primary-500 resize-y"
            />
            <p className="mt-1 text-[11px] text-gray-400 dark:text-slate-500 text-right">{message.length}/1000</p>
          </div>

          {channel !== 'IN_APP' && (
            <div className="p-3 bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/50 rounded-xl text-xs text-amber-700 dark:text-amber-300">
              Diqqat: SMS/Telegram/Push kanallari orqali yuborish auditoriya kattaligiga qarab vaqt olishi mumkin.
            </div>
          )}

          <div className="flex justify-end">
            <Button type="submit" icon={Send} disabled={sending || !title.trim() || !message.trim()}>
              {sending ? 'Yuborilmoqda...' : 'Yuborish'}
            </Button>
          </div>
        </form>
      </Card>

      <ConfirmDialog
        open={confirming}
        title="Xabarnomani yuborish"
        message={`"${title.trim()}" xabarnomasi quyidagi auditoriyaga yuboriladi: ${audienceLabel}. Davom etasizmi?`}
        confirmLabel="Yuborish"
        onCancel={() => setConfirming(false)}
        onConfirm={handleSend}
      />
    </div>
  );
};

export default BroadcastPanel;
