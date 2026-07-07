package uz.agroinvest.module.project.dto;

import lombok.Getter;
import lombok.Setter;
import uz.agroinvest.common.enums.AssetType;
import uz.agroinvest.common.enums.RiskLevel;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
public class UpdateProjectRequest {
    private AssetType assetType;
    private String title;
    private String description;
    private String region;
    private String locationDetails;
    private BigDecimal targetAmount;
    private BigDecimal minInvestment;
    private BigDecimal maxInvestment;
    private BigDecimal expectedReturnPct;
    private Integer durationDays;
    private RiskLevel riskLevel;
    private List<String> mediaUrls;
}
