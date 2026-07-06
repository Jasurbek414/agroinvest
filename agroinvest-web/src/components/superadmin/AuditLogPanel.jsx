import React from 'react';
import Card from '../ui/Card';
import EmptyState from '../ui/EmptyState';
import { formatDate } from '../../utils/format';

const AuditLogPanel = ({ auditLogs }) => (
  <Card padded={false} className="overflow-hidden h-fit">
    <div className="p-6 border-b border-gray-100">
      <h2 className="text-lg font-bold text-gray-900">Tizim audit jurnali (Audit logs)</h2>
    </div>
    {auditLogs.length === 0 ? (
      <EmptyState title="Audit jurnali bo'sh" />
    ) : (
      <div className="divide-y divide-gray-50 max-h-[600px] overflow-y-auto">
        {auditLogs.map((log) => (
          <div key={log.id} className="p-4 text-xs hover:bg-gray-50 transition">
            <div className="flex justify-between items-center mb-1">
              <span className="font-extrabold text-green-700 uppercase bg-green-50 px-2 py-0.5 rounded">
                {log.action}
              </span>
              <span className="text-gray-400">{formatDate(log.createdAt)}</span>
            </div>
            <p className="text-gray-700">
              Entity: <strong className="text-gray-900">{log.entityType} ({log.entityId})</strong>
            </p>
            {log.newValue && (
              <pre className="mt-1 bg-gray-50 p-2 rounded text-[10px] text-gray-500 font-mono overflow-x-auto">
                {log.newValue}
              </pre>
            )}
          </div>
        ))}
      </div>
    )}
  </Card>
);

export default AuditLogPanel;
