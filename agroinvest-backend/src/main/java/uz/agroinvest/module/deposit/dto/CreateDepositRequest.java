package uz.agroinvest.module.deposit.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class CreateDepositRequest {

    @NotNull(message = "Summa kiritilishi shart")
    @DecimalMin(value = "1000.0", message = "Minimal to'ldirish summasi 1,000 UZS bo'lishi shart")
    private BigDecimal amount;

    // To'lov cheki/skrinshoti - ixtiyoriy, lekin admin tasdiqlashini tezlashtiradi.
    private String proofUrl;
}
