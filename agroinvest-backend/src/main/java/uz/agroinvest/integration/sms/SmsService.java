package uz.agroinvest.integration.sms;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.HashMap;
import java.util.Map;

@Service
public class SmsService {

    private static final Logger logger = LoggerFactory.getLogger(SmsService.class);
    private final WebClient webClient;

    @Value("${sms.email:}")
    private String email;

    @Value("${sms.password:}")
    private String password;

    public SmsService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.baseUrl("https://notify.eskiz.uz/api").build();
    }

    public void sendSms(String phoneNumber, String message) {
        // Log in development / fallback mode
        logger.info("Sending SMS to {}: {}", phoneNumber, message);

        if (email == null || email.isBlank() || password == null || password.isBlank()) {
            logger.info("Eskiz.uz credentials are empty. Running in MOCK mode.");
            return;
        }

        try {
            // In real system, we authenticate first to get token, then send message.
            // Under mock/sandbox we log it to console.
            Map<String, String> body = new HashMap<>();
            body.put("mobile_phone", phoneNumber.replace("+", ""));
            body.put("message", message);
            body.put("from", "4546");

            // Perform async request to Eskiz.uz API
            webClient.post()
                    .uri("/message/sms/send")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .subscribe(
                            response -> logger.info("SMS sent successfully to {}, response: {}", phoneNumber, response),
                            error -> logger.error("Failed to send SMS to {}", phoneNumber, error)
                    );
        } catch (Exception e) {
            logger.error("Failed to execute sendSms to " + phoneNumber, e);
        }
    }
}
