package uz.agroinvest.module.investment.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
public class CreateInvestmentRequest {

    @NotNull(message = "Loyiha tanlanishi shart")
    private UUID projectId;

    @NotNull(message = "Investitsiya summasi kiritilishi shart")
    @DecimalMin(value = "1000.0", message = "Minimal investitsiya summasi 1,000 UZS bo'lishi shart")
    private BigDecimal amount;

    private String idempotencyKey;
}
