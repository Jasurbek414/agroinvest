package uz.agroinvest.module.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class VerifyOtpRequest {

    @NotBlank(message = "Telefon raqami bo'sh bo'lmasligi kerak")
    @Pattern(regexp = "^\\+998\\d{9}$", message = "Telefon raqami +998XXXXXXXXX formatida bo'lishi kerak")
    private String phoneNumber;

    @NotBlank(message = "OTP tasdiqlash kodi bo'sh bo'lmasligi kerak")
    @Pattern(regexp = "^\\d{6}$", message = "OTP kodi roppa-rosa 6 ta raqam bo'lishi kerak")
    private String code;

    @NotBlank(message = "OTP maqsadi bo'sh bo'lmasligi kerak")
    private String purpose;
}
