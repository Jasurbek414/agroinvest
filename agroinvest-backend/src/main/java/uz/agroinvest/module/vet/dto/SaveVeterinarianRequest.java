package uz.agroinvest.module.vet.dto;

import jakarta.validation.constraints.NotBlank;

public record SaveVeterinarianRequest(
    @NotBlank(message = "Veterinar ismi bo'sh bo'lmasligi kerak")
    String name,

    @NotBlank(message = "Litsenziya raqami bo'sh bo'lmasligi kerak")
    String licenseNo,

    String phone,
    String specialty
) {}
