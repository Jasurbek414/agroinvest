package uz.agroinvest.module.user.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateFcmTokenRequest {
    @NotBlank(message = "fcmToken bo'sh bo'lmasligi kerak")
    private String fcmToken;
}
