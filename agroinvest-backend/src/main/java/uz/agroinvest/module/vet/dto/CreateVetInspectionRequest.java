package uz.agroinvest.module.vet.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;
import uz.agroinvest.common.enums.VetHealthStatus;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
public class CreateVetInspectionRequest {

    @NotBlank(message = "Veterinar ismi kiritilishi shart")
    @Size(max = 200)
    private String vetName;

    @Size(max = 100)
    private String vetLicenseNo;

    @NotNull(message = "Tekshiruv sanasi kiritilishi shart")
    @PastOrPresent(message = "Tekshiruv sanasi kelajakda bo'lolmaydi")
    private LocalDate inspectionDate;

    @NotEmpty(message = "Kamida bitta hujjat (PDF/foto) yuklang")
    private List<String> documentUrls;

    @Size(max = 2000)
    private String conclusion;

    @NotNull(message = "Hayvonlar salomatlik holatini tanlang")
    private VetHealthStatus healthStatus;
}
