package uz.agroinvest.module.dispute.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class CreateDisputeRequest {

    @NotNull(message = "Loyiha tanlanishi shart")
    private UUID projectId;

    @NotNull(message = "Shikoyat qilinayotgan foydalanuvchi tanlanishi shart")
    private UUID againstUserId;

    @NotBlank(message = "Shikoyat turi bo'sh bo'lmasligi kerak")
    private String disputeType;

    @NotBlank(message = "Tafsilotlar yozilishi shart")
    private String description;
}
