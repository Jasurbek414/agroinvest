package uz.agroinvest.integration.fcm;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;

/**
 * Push notification delivery - FCM HTTP v1 API integration using Firebase Admin SDK.
 * Reads firebase-service-account.json from classpath to authenticate requests.
 * If credentials are not present, runs in mock mode, logging what would have been sent.
 */
@Service
public class FcmPushService {

    private static final Logger logger = LoggerFactory.getLogger(FcmPushService.class);
    private boolean initialized = false;

    @PostConstruct
    public void init() {
        try {
            ClassPathResource resource = new ClassPathResource("firebase-service-account.json");
            if (!resource.exists()) {
                logger.warn("firebase-service-account.json not found in classpath. Push notifications will run in MOCK mode.");
                return;
            }
            try (InputStream is = resource.getInputStream()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(is))
                        .build();

                if (FirebaseApp.getApps().isEmpty()) {
                    FirebaseApp.initializeApp(options);
                }
                initialized = true;
                logger.info("Firebase Admin SDK successfully initialized for Cloud Messaging V1 API.");
            }
        } catch (Exception e) {
            logger.error("Failed to initialize Firebase App", e);
        }
    }

    public void sendPush(String fcmToken, String title, String body) {
        logger.info("Sending push to token={}: {} - {}", fcmToken, title, body);

        if (fcmToken == null || fcmToken.isBlank()) {
            logger.warn("Recipient FCM token is blank. Skipping push notification.");
            return;
        }

        if (!initialized) {
            logger.info("Firebase SDK not initialized (mock mode). Push notification logged but not sent.");
            return;
        }

        try {
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            com.google.firebase.messaging.AndroidNotification androidNotification =
                    com.google.firebase.messaging.AndroidNotification.builder()
                            .setColor("#0e5c42")
                            .build();

            com.google.firebase.messaging.AndroidConfig androidConfig =
                    com.google.firebase.messaging.AndroidConfig.builder()
                            .setNotification(androidNotification)
                            .build();

            Message message = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(notification)
                    .setAndroidConfig(androidConfig)
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            logger.info("Push notification successfully sent to Google FCM! Message ID: {}", response);
        } catch (Exception e) {
            logger.error("Failed to send push notification via Firebase Admin SDK to " + fcmToken, e);
        }
    }
}
