package uz.agroinvest.module.wallet.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WalletDto {
    private UUID id;
    private UUID userId;
    private BigDecimal balance;
    private BigDecimal frozen;
    private BigDecimal totalEarned;
    private BigDecimal totalWithdrawn;
    private LocalDateTime updatedAt;
}
