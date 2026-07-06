package uz.agroinvest.integration.telegram;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.HashMap;
import java.util.Map;

@Service
public class TelegramService {

    private static final Logger logger = LoggerFactory.getLogger(TelegramService.class);
    private final WebClient webClient;

    @Value("${telegram.bot-token:}")
    private String botToken;

    public TelegramService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.baseUrl("https://api.telegram.org").build();
    }

    public void sendTelegramMessage(Long chatId, String text) {
        logger.info("Sending Telegram message to chat {}: {}", chatId, text);

        if (botToken == null || botToken.isBlank()) {
            logger.info("Telegram Bot Token is empty. Running in MOCK mode.");
            return;
        }

        try {
            Map<String, Object> body = new HashMap<>();
            body.put("chat_id", chatId);
            body.put("text", text);
            body.put("parse_mode", "HTML");

            webClient.post()
                    .uri("/bot" + botToken + "/sendMessage")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .subscribe(
                            response -> logger.info("Telegram message sent successfully, response: {}", response),
                            error -> logger.error("Failed to send Telegram message to chat {}", chatId, error)
                    );
        } catch (Exception e) {
            logger.error("Failed to execute sendTelegramMessage to chat " + chatId, e);
        }
    }
}
