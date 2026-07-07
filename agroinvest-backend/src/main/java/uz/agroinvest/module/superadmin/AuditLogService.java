package uz.agroinvest.module.superadmin;

import org.springframework.stereotype.Service;
import uz.agroinvest.module.superadmin.entity.AuditLog;
import uz.agroinvest.module.user.entity.User;

/**
 * Single write path for the immutable audit_logs table. Previously only SuperAdminService
 * wrote to it, so ordinary admin/moderator actions (resolving a dispute, approving a
 * withdrawal, deciding a KYC application) left no audit trail beyond the entity's own
 * processedBy/verifiedBy column - which isn't filterable or exportable the way the
 * SuperAdmin audit log view is.
 */
@Service
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;

    public AuditLogService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    public void log(User actor, String action, String entityType, String entityId, String oldValue, String newValue) {
        AuditLog audit = AuditLog.builder()
                .user(actor)
                .action(action)
                .entityType(entityType)
                .entityId(entityId)
                .oldValue(oldValue)
                .newValue(newValue)
                .build();
        auditLogRepository.save(audit);
    }
}
