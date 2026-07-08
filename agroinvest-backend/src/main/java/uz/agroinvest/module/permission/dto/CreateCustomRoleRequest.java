package uz.agroinvest.module.permission.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateCustomRoleRequest {

    @NotBlank(message = "Rol nomi bo'sh bo'lmasligi kerak")
    private String name;

    private String description;
}
