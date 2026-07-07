package uz.agroinvest.module.project.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * One co-investor row in a project's public investors list. Name is MASKED in
 * ProjectService (e.g. "Jasurbek M.") - full names never leave the server here.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ProjectInvestorDto {
    private String maskedName;
    private BigDecimal amount;
    private BigDecimal sharePct;
    private LocalDateTime investedAt;
}
