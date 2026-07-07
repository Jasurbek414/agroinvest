package uz.agroinvest.module.user.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UpdateProfileRequest {
    @NotBlank(message = "Ism bo'sh bo'lishi mumkin emas")
    private String fullName;

    private String email;

    private String avatarUrl;
}
