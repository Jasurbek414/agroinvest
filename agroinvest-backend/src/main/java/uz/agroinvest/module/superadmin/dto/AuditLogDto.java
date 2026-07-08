package uz.agroinvest.module.superadmin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuditLogDto {
    private UUID id;
    private UUID userId;
    private String userName;
    private String action;
    private String entityType;
    private String entityId;
    private String oldValue;
    private String newValue;
    private String ipAddress;
    private String userAgent;
    private LocalDateTime createdAt;
}
