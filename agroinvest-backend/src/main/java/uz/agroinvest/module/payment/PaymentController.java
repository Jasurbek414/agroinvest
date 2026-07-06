package uz.agroinvest.module.payment;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {

    private static final Logger logger = LoggerFactory.getLogger(PaymentController.class);
    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    // --- CLICK WEBHOOK ENDPOINTS ---
    // Public by necessity (called by Click's servers, not our own users), so every
    // request's sign_string is cryptographically verified inside PaymentService
    // against click.secret-key before any state changes.

    @PostMapping("/click/prepare")
    public Map<String, Object> clickPrepare(
            @RequestParam("click_trans_id") String clickTransId,
            @RequestParam("service_id") String serviceId,
            @RequestParam("merchant_trans_id") String merchantTransId,
            @RequestParam("amount") String amount,
            @RequestParam(value = "action", defaultValue = "0") String action,
            @RequestParam("sign_time") String signTime,
            @RequestParam("sign_string") String signString
    ) {
        logger.info("Click Prepare received: trans_id={}, merchant_id={}, amount={}", clickTransId, merchantTransId, amount);
        return paymentService.handleClickPrepare(clickTransId, serviceId, merchantTransId, amount, action, signTime, signString);
    }

    @PostMapping("/click/complete")
    public Map<String, Object> clickComplete(
            @RequestParam("click_trans_id") String clickTransId,
            @RequestParam("service_id") String serviceId,
            @RequestParam("merchant_trans_id") String merchantTransId,
            @RequestParam("merchant_prepare_id") String merchantPrepareId,
            @RequestParam("amount") String amount,
            @RequestParam(value = "action", defaultValue = "1") String action,
            @RequestParam("sign_time") String signTime,
            @RequestParam("sign_string") String signString,
            @RequestParam("error") int errorState
    ) {
        logger.info("Click Complete received: trans_id={}, prepare_id={}, error={}", clickTransId, merchantPrepareId, errorState);
        return paymentService.handleClickComplete(clickTransId, serviceId, merchantTransId, merchantPrepareId, amount, action, signTime, signString, errorState);
    }

    // --- PAYME WEBHOOK ENDPOINT ---
    // Public by necessity; authenticated via HTTP Basic auth (Payme's own scheme),
    // verified against payme.secret-key/test-secret-key before dispatch.

    @PostMapping("/payme/webhook")
    @SuppressWarnings("unchecked")
    public Map<String, Object> paymeWebhook(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestBody Map<String, Object> request
    ) {
        if (!paymentService.verifyPaymeAuth(authorizationHeader)) {
            logger.warn("Payme Webhook: authentication failed");
            return Map.of("error", Map.of("code", -32504, "message", "Insufficient privilege to perform this method."));
        }

        String method = (String) request.get("method");
        Map<String, Object> params = (Map<String, Object>) request.get("params");
        logger.info("Payme Webhook received: method={}", method);

        if (method == null || params == null) {
            return Map.of("error", Map.of("code", -32600, "message", "Invalid RPC request"));
        }

        try {
            switch (method) {
                case "CheckPerformTransaction": {
                    Map<String, Object> account = (Map<String, Object>) params.get("account");
                    UUID userId = UUID.fromString((String) account.get("userId"));
                    BigDecimal amount = BigDecimal.valueOf(((Number) params.get("amount")).doubleValue() / 100); // Payme amounts are in tiyin
                    return paymentService.handlePaymeCheckPerformTransaction(userId, amount);
                }
                case "CreateTransaction": {
                    String id = (String) params.get("id");
                    long time = ((Number) params.get("time")).longValue();
                    Map<String, Object> account = (Map<String, Object>) params.get("account");
                    UUID userId = UUID.fromString((String) account.get("userId"));
                    BigDecimal amount = BigDecimal.valueOf(((Number) params.get("amount")).doubleValue() / 100);
                    return paymentService.handlePaymeCreateTransaction(id, time, userId, amount);
                }
                case "PerformTransaction": {
                    String id = (String) params.get("id");
                    long time = ((Number) params.get("time")).longValue();
                    return paymentService.handlePaymePerformTransaction(id, time);
                }
                case "CancelTransaction": {
                    String id = (String) params.get("id");
                    long time = ((Number) params.get("time")).longValue();
                    int reason = ((Number) params.get("reason")).intValue();
                    return paymentService.handlePaymeCancelTransaction(id, time, reason);
                }
                case "CheckTransaction": {
                    // Payme Check Transaction status placeholder
                    String id = (String) params.get("id");
                    return Map.of("result", Map.of("state", 1, "transaction", id));
                }
                default:
                    return Map.of("error", Map.of("code", -32601, "message", "Method not found"));
            }
        } catch (Exception e) {
            logger.error("Payme Webhook failed", e);
            return Map.of("error", Map.of("code", -32500, "message", "Internal server error"));
        }
    }

}
