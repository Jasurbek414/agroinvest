package uz.agroinvest.module.investment.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import uz.agroinvest.common.enums.InvestmentStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class InvestmentDto {
    private UUID id;
    private UUID projectId;
    private String projectTitle;
    private UUID investorId;
    private String investorName;
    private BigDecimal amount;
    private BigDecimal sharePct;
    private String contractUrl;
    private InvestmentStatus status;
    private LocalDateTime createdAt;
}
