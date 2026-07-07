package uz.agroinvest.module.expense.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ReviewExpenseRequest {

    @NotNull(message = "Qaror ko'rsatilishi shart")
    private Boolean approve;

    @Size(max = 500, message = "Izoh juda uzun")
    private String comment;
}
