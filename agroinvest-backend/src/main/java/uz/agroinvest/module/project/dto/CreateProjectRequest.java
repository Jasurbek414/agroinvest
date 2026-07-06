package uz.agroinvest.module.project.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import uz.agroinvest.common.enums.AssetType;
import uz.agroinvest.common.enums.RiskLevel;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
public class CreateProjectRequest {

    @NotNull(message = "Aktiv turi tanlanishi shart")
    private AssetType assetType;

    @NotBlank(message = "Loyiha sarlavhasi bo'sh bo'lmasligi kerak")
    private String title;

    @NotBlank(message = "Loyiha tavsifi bo'sh bo'lmasligi kerak")
    private String description;

    private String region;

    private String locationDetails;

    @NotNull(message = "Kerakli mablag' miqdori kiritilishi shart")
    @DecimalMin(value = "100000.0", message = "Minimal loyiha summasi 100,000 UZS bo'lishi shart")
    private BigDecimal targetAmount;

    // Null means "use the platform default" (see PlatformSettingsService.getMinInvestmentAmount) -
    // previously hardcoded to 100000 here, disconnected from the actual platform_settings value.
    @DecimalMin(value = "1000.0", message = "Minimal investitsiya ulushi 1,000 UZS bo'lishi shart")
    private BigDecimal minInvestment;

    private BigDecimal maxInvestment;

    @NotNull(message = "Kutilayotgan daromad foizi kiritilishi shart")
    @Min(value = 0, message = "Kutilayotgan daromad foizi 0 dan kam bo'lolmaydi")
    private BigDecimal expectedReturnPct;

    @NotNull(message = "Loyiha davomiyligi (kun) kiritilishi shart")
    @Min(value = 1, message = "Loyiha davomiyligi kamida 1 kun bo'lishi shart")
    private Integer durationDays;

    @NotNull(message = "Risk darajasi kiritilishi shart")
    private RiskLevel riskLevel;

    private List<String> mediaUrls;
}
