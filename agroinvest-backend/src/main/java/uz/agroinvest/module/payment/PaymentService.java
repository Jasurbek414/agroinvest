package uz.agroinvest.module.payment;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.PaymentProvider;
import uz.agroinvest.common.enums.TransactionStatus;
import uz.agroinvest.common.enums.TransactionType;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.transaction.TransactionRepository;
import uz.agroinvest.module.transaction.entity.Transaction;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.module.wallet.WalletRepository;
import uz.agroinvest.module.wallet.entity.Wallet;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class PaymentService {

    private static final Logger logger = LoggerFactory.getLogger(PaymentService.class);

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;

    private final String clickSecretKey;
    private final String paymeSecretKey;
    private final String paymeTestSecretKey;
    private final boolean paymeTestMode;
    private final String clickMerchantId;
    private final String clickServiceId;
    private final String paymeMerchantId;

    public PaymentService(
            UserRepository userRepository,
            WalletRepository walletRepository,
            TransactionRepository transactionRepository,
            @Value("${click.secret-key:}") String clickSecretKey,
            @Value("${payme.secret-key:}") String paymeSecretKey,
            @Value("${payme.test-secret-key:}") String paymeTestSecretKey,
            @Value("${payme.test-mode:true}") boolean paymeTestMode,
            @Value("${click.merchant-id:}") String clickMerchantId,
            @Value("${click.service-id:}") String clickServiceId,
            @Value("${payme.merchant-id:}") String paymeMerchantId
    ) {
        this.userRepository = userRepository;
        this.walletRepository = walletRepository;
        this.transactionRepository = transactionRepository;
        this.clickSecretKey = clickSecretKey;
        this.paymeSecretKey = paymeSecretKey;
        this.paymeTestSecretKey = paymeTestSecretKey;
        this.paymeTestMode = paymeTestMode;
        this.clickMerchantId = clickMerchantId;
        this.clickServiceId = clickServiceId;
        this.paymeMerchantId = paymeMerchantId;
    }

    // --- SIGNATURE / AUTH VERIFICATION ---

    /**
     * Click's documented signature scheme: md5(click_trans_id + service_id + secret_key
     * + merchant_trans_id [+ merchant_prepare_id] + amount + action + sign_time).
     * merchantPrepareId is null for the Prepare step and present for Complete.
     */
    boolean verifyClickSignature(String clickTransId, String serviceId, String merchantTransId,
                                  String merchantPrepareId, String amount, String action,
                                  String signTime, String signString) {
        if (clickSecretKey == null || clickSecretKey.isBlank() || signString == null) {
            return false;
        }
        StringBuilder raw = new StringBuilder()
                .append(clickTransId).append(serviceId).append(clickSecretKey).append(merchantTransId);
        if (merchantPrepareId != null) {
            raw.append(merchantPrepareId);
        }
        raw.append(amount).append(action).append(signTime);
        String expected = md5Hex(raw.toString());
        return constantTimeEquals(expected, signString);
    }

    /**
     * Payme authenticates webhooks via HTTP Basic auth: base64("Paycom:" + secretKey"),
     * not a per-request signature field.
     */
    boolean verifyPaymeAuth(String authorizationHeader) {
        String secret = paymeTestMode ? paymeTestSecretKey : paymeSecretKey;
        if (authorizationHeader == null || !authorizationHeader.startsWith("Basic ") || secret == null || secret.isBlank()) {
            return false;
        }
        String expected = "Basic " + Base64.getEncoder().encodeToString(("Paycom:" + secret).getBytes(StandardCharsets.UTF_8));
        return constantTimeEquals(expected, authorizationHeader);
    }

    private String md5Hex(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] digest = md.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    private boolean constantTimeEquals(String a, String b) {
        return MessageDigest.isEqual(
                a.toLowerCase().getBytes(StandardCharsets.UTF_8),
                b.toLowerCase().getBytes(StandardCharsets.UTF_8)
        );
    }

    // --- CLICK WEBHOOK ACTIONS ---

    @Transactional
    public Map<String, Object> handleClickPrepare(
            String clickTransId,
            String serviceId,
            String merchantTransId,
            String amount,
            String action,
            String signTime,
            String signString
    ) {
        Map<String, Object> response = new HashMap<>();

        if (!verifyClickSignature(clickTransId, serviceId, merchantTransId, null, amount, action, signTime, signString)) {
            logger.warn("Click Prepare: invalid signature for trans_id={}", clickTransId);
            response.put("error", -1); // SIGN CHECK FAILED
            response.put("error_note", "SIGN CHECK FAILED");
            return response;
        }

        try {
            UUID userId = UUID.fromString(merchantTransId);
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isEmpty()) {
                response.put("error", -5); // User not found
                response.put("error_note", "User not found");
                return response;
            }

            // Check if transaction already exists
            Optional<Transaction> txnOpt = transactionRepository.findByExternalPaymentIdAndPaymentProvider(clickTransId, PaymentProvider.CLICK);
            if (txnOpt.isPresent()) {
                response.put("error", -4); // Transaction already exists
                response.put("error_note", "Transaction already exists");
                return response;
            }

            BigDecimal parsedAmount = new BigDecimal(amount);

            // Save PENDING Click Deposit Transaction
            Transaction transaction = Transaction.builder()
                    .user(userOpt.get())
                    .type(TransactionType.DEPOSIT)
                    .amount(parsedAmount)
                    .paymentProvider(PaymentProvider.CLICK)
                    .externalPaymentId(clickTransId)
                    .status(TransactionStatus.PENDING)
                    .build();

            Transaction savedTxn;
            try {
                savedTxn = transactionRepository.save(transaction);
            } catch (DataIntegrityViolationException dup) {
                // Two concurrent "prepare" deliveries for the same click_trans_id race here;
                // the DB unique index (external_payment_id, payment_provider) is the final guard.
                response.put("error", -4);
                response.put("error_note", "Transaction already exists");
                return response;
            }

            response.put("error", 0);
            response.put("error_note", "Success");
            response.put("click_trans_id", clickTransId);
            response.put("merchant_trans_id", merchantTransId);
            response.put("merchant_prepare_id", savedTxn.getId().toString());
        } catch (Exception e) {
            logger.error("Click Prepare failed", e);
            response.put("error", -9); // Unknown error
            response.put("error_note", "Server error");
        }
        return response;
    }

    @Transactional
    public Map<String, Object> handleClickComplete(
            String clickTransId,
            String serviceId,
            String merchantTransId,
            String merchantPrepareId,
            String amount,
            String action,
            String signTime,
            String signString,
            int errorState
    ) {
        Map<String, Object> response = new HashMap<>();

        if (!verifyClickSignature(clickTransId, serviceId, merchantTransId, merchantPrepareId, amount, action, signTime, signString)) {
            logger.warn("Click Complete: invalid signature for trans_id={}", clickTransId);
            response.put("error", -1); // SIGN CHECK FAILED
            response.put("error_note", "SIGN CHECK FAILED");
            return response;
        }

        try {
            UUID txnId = UUID.fromString(merchantPrepareId);
            Transaction transaction = transactionRepository.findById(txnId)
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
            // Captured before any compare-and-swap below clears the persistence context,
            // which would otherwise detach `transaction` and risk a lazy-load failure.
            // Named creditAmount (not `amount`) because this method already has an
            // `amount` parameter (the un-trusted amount string on this webhook request).
            UUID userId = transaction.getUser().getId();
            BigDecimal creditAmount = transaction.getAmount();

            if (errorState < 0) {
                // Only a still-PENDING transaction can be marked FAILED; if a concurrent
                // delivery already completed it, this delivery must not downgrade it.
                transactionRepository.compareAndSetStatus(txnId, TransactionStatus.PENDING, TransactionStatus.FAILED);
                response.put("error", -9);
                response.put("error_note", "Transaction failed from Click side");
                return response;
            }

            if (transaction.getStatus() == TransactionStatus.COMPLETED) {
                response.put("error", 0);
                response.put("error_note", "Already completed");
                response.put("click_trans_id", clickTransId);
                response.put("merchant_trans_id", merchantTransId);
                response.put("merchant_confirm_id", merchantPrepareId);
                return response;
            }

            // Atomically claim the PENDING -> COMPLETED transition. Click retries this
            // webhook on network failure, so two deliveries can arrive concurrently;
            // only the caller that wins this compare-and-swap may credit the wallet,
            // otherwise both would read the pre-update status and both credit it.
            int updated = transactionRepository.compareAndSetStatus(txnId, TransactionStatus.PENDING, TransactionStatus.COMPLETED);
            if (updated == 0) {
                Transaction current = transactionRepository.findById(txnId)
                        .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
                if (current.getStatus() == TransactionStatus.COMPLETED) {
                    response.put("error", 0);
                    response.put("error_note", "Already completed");
                } else {
                    response.put("error", -9);
                    response.put("error_note", "Transaction is not in a completable state");
                }
                response.put("click_trans_id", clickTransId);
                response.put("merchant_trans_id", merchantTransId);
                response.put("merchant_confirm_id", merchantPrepareId);
                return response;
            }

            // Credit Wallet using the amount recorded at Prepare time (never the amount
            // on this request) so a tampered Complete call can't credit more than what
            // was actually reserved.
            Wallet wallet = walletRepository.findByUserIdForUpdate(userId)
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

            wallet.setBalance(wallet.getBalance().add(creditAmount));
            wallet.setTotalEarned(wallet.getTotalEarned().add(creditAmount));
            walletRepository.save(wallet);

            response.put("error", 0);
            response.put("error_note", "Success");
            response.put("click_trans_id", clickTransId);
            response.put("merchant_trans_id", merchantTransId);
            response.put("merchant_confirm_id", merchantPrepareId);
        } catch (Exception e) {
            logger.error("Click Complete failed", e);
            response.put("error", -9);
            response.put("error_note", "Server error");
        }
        return response;
    }

    // --- PAYME WEBHOOK ACTIONS (JSON-RPC 2.0) ---

    @Transactional
    public Map<String, Object> handlePaymeCheckPerformTransaction(UUID userId, BigDecimal amount) {
        Map<String, Object> result = new HashMap<>();
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            result.put("error", Map.of("code", -31050, "message", "User not found"));
            return result;
        }
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            result.put("error", Map.of("code", -31011, "message", "Invalid amount"));
            return result;
        }

        result.put("result", Map.of("allow", true));
        return result;
    }

    @Transactional
    public Map<String, Object> handlePaymeCreateTransaction(
            String paymeTxnId,
            long time,
            UUID userId,
            BigDecimal amount
    ) {
        Map<String, Object> result = new HashMap<>();
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            result.put("error", Map.of("code", -31050, "message", "User not found"));
            return result;
        }

        Optional<Transaction> existingOpt = transactionRepository.findByExternalPaymentIdAndPaymentProvider(paymeTxnId, PaymentProvider.PAYME);
        if (existingOpt.isPresent()) {
            Transaction txn = existingOpt.get();
            if (txn.getStatus() == TransactionStatus.PENDING) {
                result.put("result", Map.of(
                        "create_time", time,
                        "transaction", txn.getId().toString(),
                        "state", 1
                ));
            } else if (txn.getStatus() == TransactionStatus.COMPLETED) {
                result.put("result", Map.of(
                        "create_time", time,
                        "transaction", txn.getId().toString(),
                        "state", 2
                ));
            } else {
                result.put("error", Map.of("code", -31008, "message", "Transaction already cancelled"));
            }
            return result;
        }

        // Create PENDING transaction
        Transaction transaction = Transaction.builder()
                .user(userOpt.get())
                .type(TransactionType.DEPOSIT)
                .amount(amount)
                .paymentProvider(PaymentProvider.PAYME)
                .externalPaymentId(paymeTxnId)
                .status(TransactionStatus.PENDING)
                .build();

        Transaction savedTxn;
        try {
            savedTxn = transactionRepository.save(transaction);
        } catch (DataIntegrityViolationException dup) {
            // Concurrent CreateTransaction retries race here; DB unique index is the final guard.
            Transaction existing = transactionRepository.findByExternalPaymentIdAndPaymentProvider(paymeTxnId, PaymentProvider.PAYME)
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
            result.put("result", Map.of(
                    "create_time", time,
                    "transaction", existing.getId().toString(),
                    "state", existing.getStatus() == TransactionStatus.COMPLETED ? 2 : 1
            ));
            return result;
        }

        result.put("result", Map.of(
                "create_time", time,
                "transaction", savedTxn.getId().toString(),
                "state", 1
        ));
        return result;
    }

    @Transactional
    public Map<String, Object> handlePaymePerformTransaction(String paymeTxnId, long time) {
        Map<String, Object> result = new HashMap<>();
        Transaction transaction = transactionRepository.findByExternalPaymentIdAndPaymentProvider(paymeTxnId, PaymentProvider.PAYME)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Transaction not found"));
        UUID txnId = transaction.getId();
        UUID userId = transaction.getUser().getId();
        BigDecimal amount = transaction.getAmount();

        if (transaction.getStatus() == TransactionStatus.COMPLETED) {
            result.put("result", Map.of(
                    "perform_time", time,
                    "transaction", txnId.toString(),
                    "state", 2
            ));
            return result;
        }

        if (transaction.getStatus() != TransactionStatus.PENDING) {
            result.put("error", Map.of("code", -31008, "message", "Cannot perform cancelled transaction"));
            return result;
        }

        // Atomically claim the PENDING -> COMPLETED transition so a concurrently
        // retried PerformTransaction call can't also credit the wallet.
        int updated = transactionRepository.compareAndSetStatus(txnId, TransactionStatus.PENDING, TransactionStatus.COMPLETED);
        if (updated == 0) {
            Transaction current = transactionRepository.findById(txnId)
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
            if (current.getStatus() == TransactionStatus.COMPLETED) {
                result.put("result", Map.of("perform_time", time, "transaction", txnId.toString(), "state", 2));
            } else {
                result.put("error", Map.of("code", -31008, "message", "Cannot perform cancelled transaction"));
            }
            return result;
        }

        Wallet wallet = walletRepository.findByUserIdForUpdate(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        wallet.setBalance(wallet.getBalance().add(amount));
        wallet.setTotalEarned(wallet.getTotalEarned().add(amount));
        walletRepository.save(wallet);

        result.put("result", Map.of(
                "perform_time", time,
                "transaction", txnId.toString(),
                "state", 2
        ));
        return result;
    }

    @Transactional
    public Map<String, Object> handlePaymeCancelTransaction(String paymeTxnId, long time, int reason) {
        Map<String, Object> result = new HashMap<>();
        Transaction transaction = transactionRepository.findByExternalPaymentIdAndPaymentProvider(paymeTxnId, PaymentProvider.PAYME)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Transaction not found"));
        UUID txnId = transaction.getId();
        UUID userId = transaction.getUser().getId();
        BigDecimal amount = transaction.getAmount();

        if (transaction.getStatus() == TransactionStatus.CANCELLED || transaction.getStatus() == TransactionStatus.FAILED) {
            result.put("result", Map.of(
                    "cancel_time", time,
                    "transaction", txnId.toString(),
                    "state", -1
            ));
            return result;
        }

        if (transaction.getStatus() == TransactionStatus.COMPLETED) {
            // Two concurrent Cancel deliveries for the same completed transaction must
            // not both debit the wallet. The wallet's pessimistic lock serializes them;
            // the balance check is safe to do first (amount is immutable), but the
            // actual debit is strictly gated behind winning the compare-and-swap below -
            // whichever delivery loses that race skips the debit entirely.
            Wallet wallet = walletRepository.findByUserIdForUpdate(userId)
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

            if (wallet.getBalance().compareTo(amount) < 0) {
                // Cannot cancel because user already spent the money!
                result.put("error", Map.of("code", -31007, "message", "Insufficient balance to cancel transaction"));
                return result;
            }

            int updated = transactionRepository.compareAndSetStatus(txnId, TransactionStatus.COMPLETED, TransactionStatus.CANCELLED);
            if (updated == 0) {
                // A concurrent request already moved this transaction out of COMPLETED;
                // do not debit again.
                result.put("result", Map.of("cancel_time", time, "transaction", txnId.toString(), "state", -1));
                return result;
            }

            wallet.setBalance(wallet.getBalance().subtract(amount));
            walletRepository.save(wallet);

            result.put("result", Map.of(
                    "cancel_time", time,
                    "transaction", txnId.toString(),
                    "state", -1
            ));
            return result;
        }

        // PENDING -> CANCELLED: no wallet interaction, so a plain compare-and-swap
        // (rather than round-tripping through a lock) is enough to keep this idempotent.
        transactionRepository.compareAndSetStatus(txnId, TransactionStatus.PENDING, TransactionStatus.CANCELLED);

        result.put("result", Map.of(
                "cancel_time", time,
                "transaction", txnId.toString(),
                "state", -1
        ));
        return result;
    }

    /**
     * Reports the real, current status of a Payme transaction (state 1=pending,
     * 2=completed, -1/-2=cancelled) instead of a hardcoded placeholder - Payme's
     * reconciliation flow depends on this reflecting the actual ledger state.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> handlePaymeCheckTransaction(String paymeTxnId) {
        Map<String, Object> result = new HashMap<>();
        Transaction transaction = transactionRepository.findByExternalPaymentIdAndPaymentProvider(paymeTxnId, PaymentProvider.PAYME)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Transaction not found"));

        int state = switch (transaction.getStatus()) {
            case PENDING -> 1;
            case COMPLETED -> 2;
            case CANCELLED, FAILED -> -1;
        };

        long createTimeMillis = transaction.getCreatedAt()
                .atZone(java.time.ZoneId.systemDefault())
                .toInstant()
                .toEpochMilli();

        Map<String, Object> resultBody = new HashMap<>();
        resultBody.put("create_time", createTimeMillis);
        resultBody.put("perform_time", state == 2 ? createTimeMillis : 0);
        resultBody.put("cancel_time", state == -1 ? createTimeMillis : 0);
        resultBody.put("transaction", transaction.getId().toString());
        resultBody.put("state", state);
        resultBody.put("reason", null);
        result.put("result", resultBody);
        return result;
    }

    /**
     * Builds the redirect URL to the provider's own hosted checkout page - the
     * mobile app's payment_webview_page.dart loads this directly in a WebView.
     * INFRASTRUCTURE ONLY: with clickMerchantId/clickServiceId/paymeMerchantId
     * left unconfigured (the default), this produces a URL that will not
     * actually complete a real payment - same "safe until configured" pattern
     * as FcmPushService. Wallets are credited via the superadmin-approved
     * deposit-request flow (DepositRequestService) until real merchant
     * credentials exist.
     */
    public String buildCheckoutUrl(PaymentProvider provider, UUID userId, BigDecimal amount) {
        if (provider == PaymentProvider.CLICK) {
            return "https://my.click.uz/services/pay?service_id=" + clickServiceId
                    + "&merchant_id=" + clickMerchantId
                    + "&amount=" + amount.toPlainString()
                    + "&transaction_param=" + userId;
        }
        if (provider == PaymentProvider.PAYME) {
            String raw = "m=" + paymeMerchantId
                    + ";ac.userId=" + userId
                    + ";a=" + amount.multiply(BigDecimal.valueOf(100)).toBigInteger();
            String encoded = Base64.getEncoder().encodeToString(raw.getBytes(StandardCharsets.UTF_8));
            return "https://checkout.paycom.uz/" + encoded;
        }
        throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Noma'lum to'lov provayderi");
    }
}
