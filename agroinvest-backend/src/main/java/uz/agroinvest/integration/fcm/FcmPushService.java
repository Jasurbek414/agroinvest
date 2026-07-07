package uz.agroinvest.integration.fcm;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.Map;

/**
 * Push notification delivery - INFRASTRUCTURE ONLY, following the same
 * mock-by-default pattern as SmsService/TelegramService: until fcm.server-key
 * is configured with a real Firebase Cloud Messaging server key, this only
 * logs what would have been sent. The recipient is User.fcmToken, populated
 * via PATCH /api/v1/users/me/fcm-token once the mobile app's own
 * PushNotificationService is activated against a real Firebase project.
 *
 * Uses FCM's legacy HTTP API (server-key auth) rather than the newer HTTP v1
 * API (which needs a service-account JSON + OAuth2 token exchange) - simpler
 * to stand up for now; migrate to v1 when wiring real credentials if Google
 * has fully sunset the legacy endpoint by then.
 */
@Service
public class FcmPushService {

    private static final Logger logger = LoggerFactory.getLogger(FcmPushService.class);
    private final WebClient webClient;

    @Value("${fcm.server-key:}")
    private String serverKey;

    public FcmPushService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.baseUrl("https://fcm.googleapis.com").build();
    }

    public void sendPush(String fcmToken, String title, String body) {
        logger.info("Sending push to token={}: {} - {}", fcmToken, title, body);

        if (serverKey == null || serverKey.isBlank() || fcmToken == null || fcmToken.isBlank()) {
            logger.info("FCM server key or recipient token missing. Running in MOCK mode.");
            return;
        }

        try {
            Map<String, Object> payload = Map.of(
                    "to", fcmToken,
                    "notification", Map.of("title", title, "body", body)
            );

            webClient.post()
                    .uri("/fcm/send")
                    .header("Authorization", "key=" + serverKey)
                    .bodyValue(payload)
                    .retrieve()
                    .bodyToMono(String.class)
                    .subscribe(
                            response -> logger.info("Push sent, response: {}", response),
                            error -> logger.error("Failed to send push to {}", fcmToken, error)
                    );
        } catch (Exception e) {
            logger.error("Failed to execute sendPush to " + fcmToken, e);
        }
    }
}
