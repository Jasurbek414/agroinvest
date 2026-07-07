package uz.agroinvest.module.notification;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.NotificationChannel;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.integration.fcm.FcmPushService;
import uz.agroinvest.integration.sms.SmsService;
import uz.agroinvest.integration.telegram.TelegramService;
import uz.agroinvest.module.notification.dto.NotificationDto;
import uz.agroinvest.module.notification.entity.Notification;
import uz.agroinvest.module.user.entity.User;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class NotificationService {

    private static final Logger logger = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final SmsService smsService;
    private final TelegramService telegramService;
    private final FcmPushService fcmPushService;

    public NotificationService(
            NotificationRepository notificationRepository,
            SmsService smsService,
            TelegramService telegramService,
            FcmPushService fcmPushService
    ) {
        this.notificationRepository = notificationRepository;
        this.smsService = smsService;
        this.telegramService = telegramService;
        this.fcmPushService = fcmPushService;
    }

    @Transactional(readOnly = true)
    public Page<NotificationDto> getNotifications(UUID userId, Pageable pageable) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(this::mapToDto);
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(UUID userId) {
        return notificationRepository.countByUserIdAndIsReadFalse(userId);
    }

    @Transactional
    public void markAsRead(UUID id, UUID userId) {
        Notification notif = notificationRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Bildirishnoma topilmadi"));

        if (!notif.getUser().getId().equals(userId)) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Ruxsat etilmagan amal");
        }

        notif.setRead(true);
        notificationRepository.save(notif);
    }

    @Transactional
    public void markAllAsRead(UUID userId) {
        notificationRepository.markAllAsReadForUser(userId);
    }

    @Transactional
    public NotificationDto createNotification(
            User user,
            String type,
            String title,
            String message,
            NotificationChannel channel
    ) {
        Notification notif = Notification.builder()
                .user(user)
                .type(type)
                .title(title)
                .message(message)
                .isRead(false)
                .channel(channel)
                .sentAt(LocalDateTime.now())
                .build();

        Notification saved = notificationRepository.save(notif);

        // Deliver notification to external channels asynchronously or sequentially
        try {
            if (channel == NotificationChannel.SMS) {
                smsService.sendSms(user.getPhoneNumber(), message);
            } else if (channel == NotificationChannel.TELEGRAM) {
                if (user.getTelegramChatId() != null) {
                    telegramService.sendTelegramMessage(user.getTelegramChatId(), "<b>" + title + "</b>\n" + message);
                } else {
                    logger.warn("Telegram channel requested, but user {} has no telegramChatId configured", user.getId());
                }
            } else if (channel == NotificationChannel.EMAIL) {
                logger.info("Email delivery is in MOCK mode for user: {}", user.getEmail());
            } else if (channel == NotificationChannel.PUSH) {
                if (user.getFcmToken() != null && !user.getFcmToken().isBlank()) {
                    fcmPushService.sendPush(user.getFcmToken(), title, message);
                } else {
                    logger.warn("Push channel requested, but user {} has no fcmToken registered", user.getId());
                }
            }
        } catch (Exception e) {
            logger.error("Failed to deliver notification {} to channel {}", saved.getId(), channel, e);
        }

        return mapToDto(saved);
    }

    private NotificationDto mapToDto(Notification notif) {
        return NotificationDto.builder()
                .id(notif.getId())
                .userId(notif.getUser().getId())
                .type(notif.getType())
                .title(notif.getTitle())
                .message(notif.getMessage())
                .isRead(notif.isRead())
                .channel(notif.getChannel())
                .sentAt(notif.getSentAt())
                .createdAt(notif.getCreatedAt())
                .build();
    }
}
