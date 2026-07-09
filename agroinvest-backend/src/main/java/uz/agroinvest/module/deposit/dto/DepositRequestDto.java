package uz.agroinvest.module.deposit.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import uz.agroinvest.common.enums.DepositStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DepositRequestDto {
    private UUID id;
    private UUID userId;
    private String userName;
    private BigDecimal amount;
    private String proofUrl;
    private DepositStatus status;
    private String adminComment;
    private LocalDateTime createdAt;
}
