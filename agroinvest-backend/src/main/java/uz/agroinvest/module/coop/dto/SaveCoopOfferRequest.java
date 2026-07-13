package uz.agroinvest.module.coop.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.UUID;

public record SaveCoopOfferRequest(
    @NotBlank(message = "Sarlavha bo'sh bo'lmasligi kerak")
    String title,

    @NotBlank(message = "Tavsif bo'sh bo'lmasligi kerak")
    String description,

    @NotBlank(message = "Tur tanlanishi shart")
    String type,

    @NotNull(message = "Summa ko'rsatilishi shart")
    BigDecimal amount,

    @NotBlank(message = "Telefon raqami kiritilishi shart")
    String contactPhone,

    UUID investmentId
) {}
