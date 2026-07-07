package uz.agroinvest.module.expense.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import uz.agroinvest.common.enums.ExpenseCategory;
import uz.agroinvest.common.enums.PayerSource;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
public class CreateExpenseRequest {

    @NotNull(message = "Harajat toifasi tanlanishi shart")
    private ExpenseCategory category;

    @NotNull(message = "Harajat summasi kiritilishi shart")
    @DecimalMin(value = "0.01", message = "Harajat summasi musbat bo'lishi kerak")
    private BigDecimal amount;

    @Size(max = 2000, message = "Tavsif juda uzun")
    private String description;

    private List<String> receiptUrls;

    @NotNull(message = "Harajat sanasi kiritilishi shart")
    private LocalDate expenseDate;

    // Only honored when the project's expensePolicy is MIXED; otherwise the
    // server derives the payer from the policy and ignores this field.
    private PayerSource payerSource;
}
