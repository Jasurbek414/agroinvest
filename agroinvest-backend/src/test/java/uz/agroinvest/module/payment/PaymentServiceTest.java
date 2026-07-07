package uz.agroinvest.module.payment;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import uz.agroinvest.common.enums.PaymentProvider;
import uz.agroinvest.common.enums.TransactionStatus;
import uz.agroinvest.common.enums.TransactionType;
import uz.agroinvest.module.transaction.TransactionRepository;
import uz.agroinvest.module.transaction.entity.Transaction;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.module.wallet.WalletRepository;
import uz.agroinvest.module.wallet.entity.Wallet;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class PaymentServiceTest {

    private static final String CLICK_SECRET = "test-secret";
    private static final String SERVICE_ID = "service-1";

    private WalletRepository walletRepository;
    private TransactionRepository transactionRepository;
    private PaymentService paymentService;

    @BeforeEach
    void setUp() {
        UserRepository userRepository = mock(UserRepository.class);
        walletRepository = mock(WalletRepository.class);
        transactionRepository = mock(TransactionRepository.class);

        paymentService = new PaymentService(
                userRepository,
                walletRepository,
                transactionRepository,
                CLICK_SECRET,
                "",
                "",
                true,
                "merchant-1",
                SERVICE_ID,
                "payme-merchant-1"
        );
    }

    /**
     * Reproduces the exact race this CAS fix targets: Click retries its Complete
     * webhook, so two deliveries for the same transaction can both read PENDING via
     * findById before either commits. Only one may win the atomic PENDING->COMPLETED
     * update; the loser must re-check the real status and must NOT credit the wallet
     * a second time.
     */
    @Test
    void handleClickComplete_concurrentRetryCreditsWalletExactlyOnce() {
        UUID txnId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        String clickTransId = "click-123";
        String merchantTransId = userId.toString();
        String merchantPrepareId = txnId.toString();
        String amount = "50000";
        String action = "1";
        String signTime = "2026-01-01 00:00:00";
        String signString = clickSign(clickTransId, merchantTransId, merchantPrepareId, amount, action, signTime);

        User investor = User.builder().id(userId).build();
        Transaction pendingTxn = Transaction.builder()
                .id(txnId)
                .user(investor)
                .type(TransactionType.DEPOSIT)
                .amount(BigDecimal.valueOf(50000))
                .paymentProvider(PaymentProvider.CLICK)
                .externalPaymentId(clickTransId)
                .status(TransactionStatus.PENDING)
                .build();
        Transaction completedTxn = Transaction.builder()
                .id(txnId)
                .user(investor)
                .type(TransactionType.DEPOSIT)
                .amount(BigDecimal.valueOf(50000))
                .paymentProvider(PaymentProvider.CLICK)
                .externalPaymentId(clickTransId)
                .status(TransactionStatus.COMPLETED)
                .build();
        Wallet wallet = Wallet.builder().user(investor).balance(BigDecimal.ZERO).totalEarned(BigDecimal.ZERO).build();

        // Both concurrent deliveries read PENDING; only the third read (the CAS
        // loser's post-race re-fetch) sees the row as already COMPLETED.
        when(transactionRepository.findById(txnId))
                .thenReturn(Optional.of(pendingTxn))
                .thenReturn(Optional.of(pendingTxn))
                .thenReturn(Optional.of(completedTxn));
        when(transactionRepository.compareAndSetStatus(txnId, TransactionStatus.PENDING, TransactionStatus.COMPLETED))
                .thenReturn(1)
                .thenReturn(0);
        when(walletRepository.findByUserIdForUpdate(userId)).thenReturn(Optional.of(wallet));

        Map<String, Object> firstResponse = paymentService.handleClickComplete(
                clickTransId, SERVICE_ID, merchantTransId, merchantPrepareId, amount, action, signTime, signString, 0);
        Map<String, Object> secondResponse = paymentService.handleClickComplete(
                clickTransId, SERVICE_ID, merchantTransId, merchantPrepareId, amount, action, signTime, signString, 0);

        assertEquals(0, firstResponse.get("error"));
        assertEquals("Success", firstResponse.get("error_note"));
        assertEquals(0, secondResponse.get("error"));
        assertEquals("Already completed", secondResponse.get("error_note"));

        assertEquals(0, BigDecimal.valueOf(50000).compareTo(wallet.getBalance()), "wallet must be credited exactly once, not twice");
        verify(walletRepository, times(1)).save(any(Wallet.class));
    }

    private String clickSign(String clickTransId, String merchantTransId, String merchantPrepareId,
                              String amount, String action, String signTime) {
        String raw = clickTransId + SERVICE_ID + CLICK_SECRET + merchantTransId + merchantPrepareId + amount + action + signTime;
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] digest = md.digest(raw.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
