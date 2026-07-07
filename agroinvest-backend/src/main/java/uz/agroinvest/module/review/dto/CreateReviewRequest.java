package uz.agroinvest.module.review.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class CreateReviewRequest {

    @NotNull(message = "Investitsiya tanlanishi shart")
    private UUID investmentId;

    @NotNull(message = "Baho kiritilishi shart")
    @Min(value = 1, message = "Baho kamida 1 bo'lishi kerak")
    @Max(value = 5, message = "Baho ko'pi bilan 5 bo'lishi kerak")
    private Integer rating;

    private String comment;
}
