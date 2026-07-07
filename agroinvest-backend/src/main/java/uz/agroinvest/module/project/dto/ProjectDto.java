package uz.agroinvest.module.project.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import uz.agroinvest.common.enums.AnimalType;
import uz.agroinvest.common.enums.AssetType;
import uz.agroinvest.common.enums.ExpensePolicy;
import uz.agroinvest.common.enums.FundingMode;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.RiskLevel;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProjectDto {
    private UUID id;
    private UUID farmerId;
    private String farmerName;
    private BigDecimal farmerRating;
    private Integer farmerTotalProjects;
    private boolean farmerVerified;
    private AssetType assetType;
    private AnimalType animalType;
    private Integer headcount;
    private BigDecimal pricePerHead;
    private FundingMode fundingMode;
    private BigDecimal farmerContributionValue;
    private String farmerContributionNotes;
    private LocalDateTime farmerContributionVerifiedAt;
    private ExpensePolicy expensePolicy;
    private String title;
    private String description;
    private String region;
    private String locationDetails;
    private BigDecimal targetAmount;
    private BigDecimal raisedAmount;
    private BigDecimal minInvestment;
    private BigDecimal maxInvestment;
    private BigDecimal expectedReturnPct;
    private BigDecimal commissionPct;
    private BigDecimal investorSharePct;
    private BigDecimal farmerSharePct;
    private Integer durationDays;
    private LocalDate startDate;
    private LocalDate endDate;
    private RiskLevel riskLevel;
    private ProjectStatus status;
    private String rejectionReason;
    private List<String> mediaUrls;
    private Integer totalInvestors;
    private Integer reportFrequencyDays;
    private LocalDateTime createdAt;
}
