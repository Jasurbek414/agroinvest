package uz.agroinvest.module.project.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import uz.agroinvest.common.enums.AnimalType;
import uz.agroinvest.common.enums.AssetType;
import uz.agroinvest.common.enums.ExpensePolicy;
import uz.agroinvest.common.enums.FundingMode;
import uz.agroinvest.common.enums.RiskLevel;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
public class CreateProjectRequest {

    @NotNull(message = "Aktiv turi tanlanishi shart")
    private AssetType assetType;

    // Required for LIVESTOCK/POULTRY projects (enforced in ProjectService)
    private AnimalType animalType;

    @Min(value = 1, message = "Hayvonlar soni kamida 1 bo'lishi kerak")
    private Integer headcount;

    @DecimalMin(value = "0.01", message = "Bir bosh narxi musbat bo'lishi kerak")
    private BigDecimal pricePerHead;

    // Null -> INVESTOR_FUNDED (backward compatible with old clients)
    private FundingMode fundingMode;

    @DecimalMin(value = "0.0", message = "Fermer hissasi manfiy bo'lolmaydi")
    private BigDecimal farmerContributionValue;

    private String farmerContributionNotes;

    // Null -> INVESTOR_BUDGET
    private ExpensePolicy expensePolicy;

    // Farmer's PROPOSED investor share ("kelishuv asosida") - validated against
    // platform min/max bounds in ProjectService; null -> platform default.
    @DecimalMin(value = "1.0", message = "Investor ulushi juda past")
    @Max(value = 99, message = "Investor ulushi juda yuqori")
    private BigDecimal proposedInvestorSharePct;

    // Farmer-chosen reporting cadence (1 = daily); null -> platform default.
    @Min(value = 1, message = "Hisobot chastotasi kamida 1 kun")
    @Max(value = 14, message = "Hisobot chastotasi ko'pi bilan 14 kun")
    private Integer reportFrequencyDays;

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
