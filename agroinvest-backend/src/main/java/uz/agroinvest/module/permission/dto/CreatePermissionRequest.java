package uz.agroinvest.module.permission.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreatePermissionRequest {

    @NotBlank(message = "Ruxsat kodi bo'sh bo'lmasligi kerak")
    @Pattern(regexp = "^[a-z0-9]+(\\.[a-z0-9-]+)+$", message = "Kod formati: modul.amal (masalan project.approve)")
    private String code;

    @NotBlank(message = "Tavsif bo'sh bo'lmasligi kerak")
    private String description;
}
