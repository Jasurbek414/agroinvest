package uz.agroinvest.module.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import uz.agroinvest.common.enums.UserRole;

@Getter
@Setter
public class RegisterRequest {

    @NotBlank(message = "Foydalanuvchi to'liq ismi bo'sh bo'lmasligi kerak")
    private String fullName;

    @NotBlank(message = "Telefon raqami bo'sh bo'lmasligi kerak")
    @Pattern(regexp = "^\\+998\\d{9}$", message = "Telefon raqami +998XXXXXXXXX formatida bo'lishi kerak")
    private String phoneNumber;

    @Email(message = "Email manzili noto'g'ri formatda")
    private String email;

    @NotBlank(message = "Parol bo'sh bo'lmasligi kerak")
    @Size(min = 8, message = "Parol kamida 8 belgidan iborat bo'lishi kerak")
    @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d).+$", message = "Parolda kamida bitta harf va bitta raqam bo'lishi shart")
    private String password;

    @NotNull(message = "Foydalanuvchi roli tanlanishi shart")
    private UserRole role; // Only INVESTOR or FARMER can be registered publicly
}
