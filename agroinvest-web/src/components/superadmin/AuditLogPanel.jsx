import React, { useEffect, useState } from 'react';
import { getAuditLogs } from '../../api/superadmin.api';
import Card from '../ui/Card';
import EmptyState from '../ui/EmptyState';
import ErrorState from '../ui/ErrorState';
import Pagination from '../ui/Pagination';
import { SkeletonTable } from '../ui/Skeleton';
import { formatDate } from '../../utils/format';
import AuditLogDiff from './AuditLogDiff';

const ACTION_OPTIONS = [
  { value: '', label: 'Barcha amallar' },
  { value: 'CREATE_ADMIN_ACCOUNT', label: "Xodim yaratildi" },
  { value: 'BLOCK_ACCOUNT', label: 'Hisob bloklandi' },
  { value: 'UNBLOCK_ACCOUNT', label: 'Hisob blokdan chiqarildi' },
  { value: 'UPDATE_SETTING', label: 'Sozlama o\'zgartirildi' },
  { value: 'UPDATE_INVESTOR_FARMER_SHARES', label: 'Ulushlar o\'zgartirildi' },
  { value: 'RESOLVE_DISPUTE', label: 'Nizo hal qilindi' },
  { value: 'APPROVE_WITHDRAWAL', label: "Yechish tasdiqlandi" },
  { value: 'REJECT_WITHDRAWAL', label: 'Yechish rad etildi' },
  { value: 'BLOCK_USER', label: 'Foydalanuvchi bloklandi' },
  { value: 'UNBLOCK_USER', label: 'Foydalanuvchi blokdan chiqarildi' },
  { value: 'UPDATE_KYC_STATUS', label: 'KYC holati yangilandi' },
  { value: 'BROADCAST_NOTIFICATION', label: 'Ommaviy xabarnoma' },
  { value: 'RESET_STAFF_PASSWORD', label: 'Xodim paroli tiklandi' },
  { value: 'CHANGE_STAFF_ROLE', label: 'Xodim roli o\'zgartirildi' },
];

const ENTITY_OPTIONS = [
  { value: '', label: 'Barcha obyektlar' },
  { value: 'User', label: 'Foydalanuvchi' },
  { value: 'PlatformSettings', label: 'Sozlamalar' },
  { value: 'Notification', label: 'Xabarnoma' },
  { value: 'Project', label: 'Loyiha' },
  { value: 'WithdrawalRequest', label: "Yechish so'rovi" },
  { value: 'Dispute', label: 'Nizo' },
];

const filterInputClasses = 'px-3 py-2 border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-gray-700 dark:text-slate-200 rounded-xl text-xs font-semibold outline-none focus:ring-1 focus:ring-primary-500';

// Previously received a static `auditLogs` prop from the parent with no filter
// or pagination controls despite the backend already supporting both.
const AuditLogPanel = () => {
  const [logs, setLogs] = useState([]);
  const [pageInfo, setPageInfo] = useState({ pageNumber: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [action, setAction] = useState('');
  const [entityType, setEntityType] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');

  const fetchLogs = async (page = 0) => {
    setLoading(true);
    setError(null);
    try {
      const res = await getAuditLogs(page, 20, {
        action: action || undefined,
        entityType: entityType || undefined,
        from: from || undefined,
        to: to || undefined,
      });
      setLogs(res.data.content || []);
      setPageInfo({ pageNumber: res.data.pageNumber, totalPages: res.data.totalPages });
    } catch (err) {
      setError('Audit jurnalini yuklashda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchLogs(0); }, [action, entityType, from, to]);

  return (
    <Card padded={false} className="overflow-hidden h-fit">
      <div className="p-6 border-b border-gray-100 dark:border-slate-700 space-y-3">
        <h2 className="text-lg font-bold text-gray-900 dark:text-slate-100">Tizim audit jurnali</h2>
        <div className="flex flex-wrap items-center gap-2">
          <select value={action} onChange={(e) => setAction(e.target.value)} className={filterInputClasses}>
            {ACTION_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
          <select value={entityType} onChange={(e) => setEntityType(e.target.value)} className={filterInputClasses}>
            {ENTITY_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
          <input type="date" value={from} onChange={(e) => setFrom(e.target.value)} className={filterInputClasses} title="Boshlanish sanasi" />
          <span className="text-xs text-gray-400 dark:text-slate-500 font-semibold">—</span>
          <input type="date" value={to} onChange={(e) => setTo(e.target.value)} className={filterInputClasses} title="Tugash sanasi" />
        </div>
      </div>

      {loading ? (
        <SkeletonTable rows={6} cols={1} />
      ) : error ? (
        <ErrorState message={error} onRetry={() => fetchLogs(pageInfo.pageNumber)} />
      ) : logs.length === 0 ? (
        <EmptyState title="Audit jurnali bo'sh" />
      ) : (
        <div className="divide-y divide-gray-50 dark:divide-slate-700 max-h-[600px] overflow-y-auto">
          {logs.map((log) => (
            <div key={log.id} className="p-4 text-xs hover:bg-gray-50 dark:hover:bg-slate-700/40 transition">
              <div className="flex justify-between items-center mb-1 gap-2">
                <span className="font-extrabold text-primary-700 dark:text-primary-300 uppercase bg-primary-50 dark:bg-primary-950 px-2 py-0.5 rounded">
                  {log.action}
                </span>
                <span className="text-gray-400 dark:text-slate-500 shrink-0">{formatDate(log.createdAt)}</span>
              </div>
              <p className="text-gray-700 dark:text-slate-300">
                Entity: <strong className="text-gray-900 dark:text-slate-100">{log.entityType} ({log.entityId})</strong>
              </p>
              {log.userName && (
                <p className="text-gray-500 dark:text-slate-400 mt-0.5">
                  Bajaruvchi: <strong className="text-gray-700 dark:text-slate-300">{log.userName}</strong>
                </p>
              )}
              <AuditLogDiff oldValue={log.oldValue} newValue={log.newValue} />
            </div>
          ))}
        </div>
      )}

      {!loading && !error && logs.length > 0 && (
        <div className="p-4">
          <Pagination pageNumber={pageInfo.pageNumber} totalPages={pageInfo.totalPages} onPageChange={fetchLogs} />
        </div>
      )}
    </Card>
  );
};

export default AuditLogPanel;
