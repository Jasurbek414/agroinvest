package uz.agroinvest.module.project.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import uz.agroinvest.common.enums.AnimalType;
import uz.agroinvest.common.enums.AssetType;
import uz.agroinvest.common.enums.ExpensePolicy;
import uz.agroinvest.common.enums.FundingMode;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.RiskLevel;
import uz.agroinvest.common.util.JsonListConverter;
import uz.agroinvest.module.user.entity.User;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "projects")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Project {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "farmer_id", nullable = false)
    private User farmer;

    @Enumerated(EnumType.STRING)
    @Column(name = "asset_type", nullable = false)
    private AssetType assetType;

    // Structured animal detail for LIVESTOCK/POULTRY projects (V10). Nullable for
    // other asset types and for legacy rows.
    @Enumerated(EnumType.STRING)
    @Column(name = "animal_type")
    private AnimalType animalType;

    @Column(name = "headcount")
    private Integer headcount;

    @Column(name = "price_per_head")
    private BigDecimal pricePerHead;

    // How the project's assets are financed: investor money, the farmer's own
    // animals (valued below, verified at approval), or both.
    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "funding_mode", nullable = false)
    private FundingMode fundingMode = FundingMode.INVESTOR_FUNDED;

    // UZS valuation of the farmer's own contributed animals/assets. Counts as
    // capital in the payout waterfall (returned before profit split).
    @Builder.Default
    @Column(name = "farmer_contribution_value", nullable = false)
    private BigDecimal farmerContributionValue = BigDecimal.ZERO;

    @Column(name = "farmer_contribution_notes", columnDefinition = "TEXT")
    private String farmerContributionNotes;

    // Set by the admin at approval time - approving a project attests the
    // declared contribution valuation.
    @Column(name = "farmer_contribution_verified_at")
    private LocalDateTime farmerContributionVerifiedAt;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "expense_policy", nullable = false)
    private ExpensePolicy expensePolicy = ExpensePolicy.INVESTOR_BUDGET;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(name = "region")
    private String region;

    @Column(name = "location_details")
    private String locationDetails;

    @Column(name = "target_amount", nullable = false)
    private BigDecimal targetAmount;

    @Builder.Default
    @Column(name = "raised_amount")
    private BigDecimal raisedAmount = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "min_investment")
    private BigDecimal minInvestment = BigDecimal.valueOf(100000);

    @Column(name = "max_investment")
    private BigDecimal maxInvestment;

    @Column(name = "expected_return_pct", nullable = false)
    private BigDecimal expectedReturnPct;

    @Builder.Default
    @Column(name = "commission_pct")
    private BigDecimal commissionPct = BigDecimal.valueOf(10);

    @Builder.Default
    @Column(name = "investor_share_pct")
    private BigDecimal investorSharePct = BigDecimal.valueOf(70);

    @Builder.Default
    @Column(name = "farmer_share_pct")
    private BigDecimal farmerSharePct = BigDecimal.valueOf(30);

    @Column(name = "duration_days", nullable = false)
    private Integer durationDays;

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "risk_level", nullable = false)
    private RiskLevel riskLevel;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private ProjectStatus status = ProjectStatus.PENDING;

    @Column(name = "rejection_reason")
    private String rejectionReason;

    @Convert(converter = JsonListConverter.class)
    @Column(name = "media_urls", columnDefinition = "jsonb")
    private List<String> mediaUrls;

    @Builder.Default
    @Column(name = "total_investors")
    private Integer totalInvestors = 0;

    @Builder.Default
    @Column(name = "report_frequency_days")
    private Integer reportFrequencyDays = 14;

    @Column(name = "admin_notes", columnDefinition = "TEXT")
    private String adminNotes;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    private User approvedBy;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "final_amount")
    private BigDecimal finalAmount;

    // Working-capital advances to the farmer during funding - see InvestmentService's
    // milestone release logic. Null = not yet paid; set once, never reset.
    @Column(name = "farmer_milestone1_paid_at")
    private LocalDateTime farmerMilestone1PaidAt;

    @Column(name = "farmer_milestone2_paid_at")
    private LocalDateTime farmerMilestone2PaidAt;

    // Optimistic lock: prevents a payout/status-transition from being run twice
    // concurrently (e.g. a double-clicked "distribute payout" admin action).
    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
