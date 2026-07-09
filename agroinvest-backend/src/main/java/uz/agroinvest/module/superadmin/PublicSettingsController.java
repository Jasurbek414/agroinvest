package uz.agroinvest.module.superadmin;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import uz.agroinvest.common.enums.InvestmentStatus;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.project.ProjectRepository;
import uz.agroinvest.module.user.UserRepository;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Public (unauthenticated) subset of platform settings/stats that clients need
 * BEFORE a user is logged in or while building forms: profit-split slider
 * bounds, minimum investment, commission, and coarse platform-wide counters for
 * the marketing landing page. Never expose anything PII/financial-detail here -
 * only aggregate counts and sums.
 */
@RestController
@RequestMapping("/api/v1/settings")
public class PublicSettingsController {

    private static final List<ProjectStatus> FUNDED_PROJECT_STATUSES = List.of(
            ProjectStatus.ACTIVE, ProjectStatus.MONITORING, ProjectStatus.COMPLETED
    );
    private static final List<InvestmentStatus> COMMITTED_INVESTMENT_STATUSES = List.of(
            InvestmentStatus.CONFIRMED, InvestmentStatus.ACTIVE, InvestmentStatus.PAID_OUT
    );

    private final PlatformSettingsService platformSettingsService;
    private final UserRepository userRepository;
    private final ProjectRepository projectRepository;
    private final InvestmentRepository investmentRepository;

    public PublicSettingsController(
            PlatformSettingsService platformSettingsService,
            UserRepository userRepository,
            ProjectRepository projectRepository,
            InvestmentRepository investmentRepository
    ) {
        this.platformSettingsService = platformSettingsService;
        this.userRepository = userRepository;
        this.projectRepository = projectRepository;
        this.investmentRepository = investmentRepository;
    }

    @GetMapping("/public")
    public ResponseEntity<ApiResponse<Map<String, BigDecimal>>> getPublicSettings() {
        Map<String, BigDecimal> settings = new LinkedHashMap<>();
        settings.put("minInvestorSharePct", platformSettingsService.getMinInvestorSharePct());
        settings.put("maxInvestorSharePct", platformSettingsService.getMaxInvestorSharePct());
        settings.put("defaultInvestorSharePct", platformSettingsService.getInvestorSharePct());
        settings.put("minInvestmentAmount", platformSettingsService.getMinInvestmentAmount());
        settings.put("commissionPct", platformSettingsService.getCommissionPct());
        return ResponseEntity.ok(ApiResponse.success(settings));
    }

    /** Backs the public landing page's "trust" stat tiles - coarse counts only. */
    @GetMapping("/public-stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPublicStats() {
        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("totalInvestors", userRepository.countByRole(UserRole.INVESTOR));
        stats.put("totalFarmers", userRepository.countByRole(UserRole.FARMER));
        stats.put("totalFundedProjects", projectRepository.countByStatusIn(FUNDED_PROJECT_STATUSES));
        stats.put("totalInvestedAmount", investmentRepository.sumAmountByStatusIn(COMMITTED_INVESTMENT_STATUSES));
        return ResponseEntity.ok(ApiResponse.success(stats));
    }
}
