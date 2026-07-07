package uz.agroinvest.module.withdrawal.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import uz.agroinvest.common.enums.WithdrawalStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class WithdrawalDto {
    private UUID id;
    private UUID userId;
    private String userName;
    private BigDecimal amount;
    private WithdrawalStatus status;
    private String bankName;
    private String cardNumber;
    private String adminComment;
    private LocalDateTime createdAt;
}
