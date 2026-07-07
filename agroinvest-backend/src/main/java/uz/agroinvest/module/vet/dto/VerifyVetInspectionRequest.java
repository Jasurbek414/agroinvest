package uz.agroinvest.module.vet.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class VerifyVetInspectionRequest {

    @NotNull(message = "Qaror ko'rsatilishi shart")
    private Boolean approve;

    @Size(max = 500, message = "Izoh juda uzun")
    private String comment;
}
