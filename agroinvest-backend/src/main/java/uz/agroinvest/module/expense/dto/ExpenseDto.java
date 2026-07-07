package uz.agroinvest.module.expense.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import uz.agroinvest.common.enums.ExpenseCategory;
import uz.agroinvest.common.enums.ExpenseStatus;
import uz.agroinvest.common.enums.PayerSource;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExpenseDto {
    private UUID id;
    private UUID projectId;
    private String projectTitle;
    private String submittedByName;
    private ExpenseCategory category;
    private BigDecimal amount;
    private String description;
    private List<String> receiptUrls;
    private LocalDate expenseDate;
    private PayerSource payerSource;
    private ExpenseStatus status;
    private String reviewComment;
    private LocalDateTime reviewedAt;
    private LocalDateTime createdAt;
}
