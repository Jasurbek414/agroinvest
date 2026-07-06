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

    private List<String> documentUrls;
}
