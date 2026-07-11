package uz.agroinvest.module.transaction.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import uz.agroinvest.common.enums.PaymentProvider;
import uz.agroinvest.common.enums.TransactionStatus;
import uz.agroinvest.common.enums.TransactionType;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionDto {
    private UUID id;
    private UUID userId;
    // Populated only by the SuperAdmin platform-wide listing, where rows belong to
    // many different users; the per-user wallet history leaves these null.
    private String userName;
    private String userPhone;
    private UUID projectId;
    private String projectTitle;
    private UUID investmentId;
    private TransactionType type;
    private BigDecimal amount;
    private String currency;
    private PaymentProvider paymentProvider;
    private String externalPaymentId;
    private TransactionStatus status;
    private String metadata;
    private LocalDateTime createdAt;
}
