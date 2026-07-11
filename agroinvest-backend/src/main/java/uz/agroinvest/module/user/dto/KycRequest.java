package uz.agroinvest.module.user.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;

@Data
public class KycRequest {
    @NotBlank(message = "Pasport seriyasi va raqami majburiy")
    private String passportNumber;

    @NotBlank(message = "JSHSHIR (PINFL) majburiy")
    private String pinfl;

    private String birthDate;

    @NotBlank(message = "O'zining rasmi majburiy")
    private String selfieUrl;

    @NotBlank(message = "Pasport rasmi majburiy")
    private String passportPhotoUrl;

    @NotBlank(message = "Aniq manzil majburiy")
    private String currentAddress;

    @NotBlank(message = "Pasport bo'yicha ro'yxatdan o'tgan manzil majburiy")
    private String registrationAddress;

    private String additionalPhone;

    @NotBlank(message = "Otangizning ismi va familiyasi majburiy")
    private String fatherName;

    @NotBlank(message = "Hozirgi ish joyi yoki faoliyat turi majburiy")
    private String occupation;

    private String workExperience;

    @NotBlank(message = "Ma'lumotingiz haqida ma'lumot majburiy")
    private String education;

    private List<String> documentUrls;
}
