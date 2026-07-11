package uz.agroinvest.module.dispute.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class CreateDisputeRequest {

    private UUID projectId;

    private UUID againstUserId;

    @NotBlank(message = "Shikoyat turi bo'sh bo'lmasligi kerak")
    private String disputeType;

    @NotBlank(message = "Tafsilotlar yozilishi shart")
    private String description;
}
