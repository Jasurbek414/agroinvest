package uz.agroinvest.module.notification.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import uz.agroinvest.common.enums.NotificationChannel;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDto {
    private UUID id;
    private UUID userId;
    private String type;
    private String title;
    private String message;
    private boolean isRead;
    private NotificationChannel channel;
    private LocalDateTime sentAt;
    private LocalDateTime createdAt;
}
