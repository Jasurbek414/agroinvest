package uz.agroinvest.module.superadmin;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import uz.agroinvest.module.superadmin.entity.AuditLog;
import uz.agroinvest.module.user.entity.User;

/**
 * Single write path for the immutable audit_logs table. Previously only SuperAdminService
 * wrote to it, so ordinary admin/moderator actions (resolving a dispute, approving a
 * withdrawal, deciding a KYC application) left no audit trail beyond the entity's own
 * processedBy/verifiedBy column - which isn't filterable or exportable the way the
 * SuperAdmin audit log view is.
 *
 * ipAddress/userAgent are pulled from the current request here rather than threaded
 * through every service/controller signature that calls log() - every call site so far
 * runs on an HTTP request thread (never from ReportMonitoringScheduler or another
 * background job), so RequestContextHolder is always populated.
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
                .ipAddress(currentIpAddress())
                .userAgent(currentUserAgent())
                .build();
        auditLogRepository.save(audit);
    }

    private HttpServletRequest currentRequest() {
        var attrs = RequestContextHolder.getRequestAttributes();
        return attrs instanceof ServletRequestAttributes servletAttrs ? servletAttrs.getRequest() : null;
    }

    private String currentIpAddress() {
        HttpServletRequest request = currentRequest();
        if (request == null) {
            return null;
        }
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            return forwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private String currentUserAgent() {
        HttpServletRequest request = currentRequest();
        return request != null ? request.getHeader("User-Agent") : null;
    }
}
