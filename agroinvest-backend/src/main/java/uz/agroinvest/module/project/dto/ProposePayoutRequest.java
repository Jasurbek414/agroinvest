package uz.agroinvest.module.project.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
public class ProposePayoutRequest {
    @NotNull(message = "Sotuv narxi kiritilishi shart")
    private BigDecimal proposedSalePrice;

    private List<String> saleDocuments;
}
