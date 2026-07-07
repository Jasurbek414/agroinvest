package uz.agroinvest.module.withdrawal.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class CreateWithdrawalRequest {

    @NotNull(message = "Yechish summasi kiritilishi shart")
    @DecimalMin(value = "5000.0", message = "Minimal yechish summasi 5,000 UZS bo'lishi shart")
    private BigDecimal amount;

    @NotBlank(message = "Bank nomi kiritilishi shart")
    private String bankName;

    @NotBlank(message = "Karta raqami kiritilishi shart")
    @Pattern(regexp = "^[0-9]{4}[\\s-]?[0-9]{4}[\\s-]?[0-9]{4}[\\s-]?[0-9]{4}$", message = "Karta raqami 16 xonali bo'lishi shart (masalan: 8600 1234 5678 9012)")
    private String cardNumber;
}
