package uz.agroinvest.module.dashboard;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.ExpenseStatus;
import uz.agroinvest.common.enums.InvestmentStatus;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.ReportType;
import uz.agroinvest.common.enums.VetInspectionStatus;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.expense.ExpenseRepository;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.investment.entity.Investment;
import uz.agroinvest.module.project.ProjectRepository;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.report.ReportRepository;
import uz.agroinvest.module.report.entity.Report;
import uz.agroinvest.module.vet.VetInspectionRepository;
import uz.agroinvest.module.wallet.WalletRepository;
import uz.agroinvest.module.wallet.entity.Wallet;
import uz.agroinvest.security.UserPrincipal;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Role-aware aggregates for the mobile/web home dashboard. Follows the
 * AdminService pattern: DB-side aggregation into a Map payload, no new DTO
 * hierarchy for what is fundamentally a read-only stats surface.
 */
@Service
public class DashboardService {

    private final InvestmentRepository investmentRepository;
    private final ProjectRepository projectRepository;
    private final WalletRepository walletRepository;
    private final ReportRepository reportRepository;
    private final ExpenseRepository expenseRepository;
    private final VetInspectionRepository vetInspectionRepository;

    public DashboardService(
            InvestmentRepository investmentRepository,
            ProjectRepository projectRepository,
            WalletRepository walletRepository,
            ReportRepository reportRepository,
            ExpenseRepository expenseRepository,
            VetInspectionRepository vetInspectionRepository
    ) {
        this.investmentRepository = investmentRepository;
        this.projectRepository = projectRepository;
        this.walletRepository = walletRepository;
        this.reportRepository = reportRepository;
        this.expenseRepository = expenseRepository;
        this.vetInspectionRepository = vetInspectionRepository;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getMyDashboard(UserPrincipal principal) {
        return switch (principal.getRole()) {
            case INVESTOR -> investorDashboard(principal);
            case FARMER -> farmerDashboard(principal);
            default -> throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN,
                    "Dashboard faqat investor va fermerlar uchun");
        };
    }

    private Map<String, Object> investorDashboard(UserPrincipal principal) {
        List<Investment> investments = investmentRepository.findByInvestorId(principal.getId());
        Wallet wallet = walletRepository.findByUserId(principal.getId()).orElse(null);

        List<Investment> active = investments.stream()
                .filter(inv -> inv.getStatus() == InvestmentStatus.CONFIRMED)
                .toList();

        BigDecimal portfolioValue = active.stream()
                .map(Investment::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Estimate: capital + capital x expectedReturnPct x investorShare of profit.
        // Clearly an expectation, not a promise - the client labels it "kutilmoqda".
        BigDecimal expectedPayout = active.stream()
                .map(inv -> {
                    Project p = inv.getProject();
                    BigDecimal expectedProfit = inv.getAmount()
                            .multiply(p.getExpectedReturnPct())
                            .multiply(p.getInvestorSharePct())
                            .divide(BigDecimal.valueOf(10000), 2, RoundingMode.HALF_UP);
                    return inv.getAmount().add(expectedProfit);
                })
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Long> byAssetType = new LinkedHashMap<>();
        active.forEach(inv -> byAssetType.merge(inv.getProject().getAssetType().name(), 1L, Long::sum));

        List<UUID_TITLE> investedProjects = active.stream()
                .map(inv -> new UUID_TITLE(inv.getProject().getId(), inv.getProject().getTitle()))
                .distinct()
                .toList();

        List<Map<String, Object>> recentReports = investedProjects.isEmpty() ? List.of()
                : reportRepository.findTop5ByProjectIdInOrderByCreatedAtDesc(
                        investedProjects.stream().map(UUID_TITLE::id).toList()).stream()
                .map(r -> {
                    Map<String, Object> m = new LinkedHashMap<String, Object>();
                    m.put("projectId", r.getProject().getId());
                    m.put("projectTitle", r.getProject().getTitle());
                    m.put("reportType", r.getReportType().name());
                    m.put("createdAt", r.getCreatedAt());
                    return m;
                })
                .toList();

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("role", "INVESTOR");
        result.put("portfolioValue", portfolioValue);
        result.put("activeInvestments", active.size());
        result.put("totalInvestments", investments.size());
        result.put("totalEarned", wallet != null ? wallet.getTotalEarned() : BigDecimal.ZERO);
        result.put("walletBalance", wallet != null ? wallet.getBalance() : BigDecimal.ZERO);
        result.put("expectedPayout", expectedPayout);
        result.put("assetTypeBreakdown", byAssetType);
        result.put("recentReports", recentReports);
        return result;
    }

    private Map<String, Object> farmerDashboard(UserPrincipal principal) {
        List<Project> projects = projectRepository.findByFarmerId(principal.getId());

        long activeCount = projects.stream().filter(p -> p.getStatus() == ProjectStatus.ACTIVE).count();
        long fundingCount = projects.stream().filter(p -> p.getStatus() == ProjectStatus.FUNDING).count();
        long completedCount = projects.stream().filter(p -> p.getStatus() == ProjectStatus.COMPLETED).count();

        BigDecimal totalRaised = projects.stream()
                .map(Project::getRaisedAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Reporting duty: an ACTIVE project owes a DAILY log every calendar day,
        // so it is "due" whenever today's daily log has not been submitted yet.
        // One batched query for "latest report per project" instead of one
        // findFirstByProjectId... call per project in the loop below.
        List<UUID> projectIds = projects.stream().map(Project::getId).toList();
        Map<UUID, LocalDateTime> lastReportByProject = new HashMap<>();
        Map<UUID, LocalDateTime> lastDailyLogByProject = new HashMap<>();
        if (!projectIds.isEmpty()) {
            for (Report r : reportRepository.findByProjectIdInOrderByProjectIdAndCreatedAtDesc(projectIds)) {
                // Rows arrive grouped by project, newest first within each group -
                // the first one seen per project id is its latest report.
                lastReportByProject.putIfAbsent(r.getProject().getId(), r.getCreatedAt());
                if (r.getReportType() == ReportType.DAILY) {
                    lastDailyLogByProject.putIfAbsent(r.getProject().getId(), r.getCreatedAt());
                }
            }
        }

        List<Map<String, Object>> activeProjects = new ArrayList<>();
        int reportsDue = 0;
        for (Project p : projects) {
            if (p.getStatus() != ProjectStatus.ACTIVE && p.getStatus() != ProjectStatus.FUNDING) continue;

            LocalDateTime lastReportAt = lastReportByProject.get(p.getId());

            boolean reportDue = false;
            if (p.getStatus() == ProjectStatus.ACTIVE) {
                LocalDateTime lastDailyAt = lastDailyLogByProject.get(p.getId());
                reportDue = lastDailyAt == null || lastDailyAt.toLocalDate().isBefore(LocalDate.now());
                if (reportDue) reportsDue++;
            }

            Map<String, Object> pm = new LinkedHashMap<>();
            pm.put("id", p.getId());
            pm.put("title", p.getTitle());
            pm.put("status", p.getStatus().name());
            pm.put("targetAmount", p.getTargetAmount());
            pm.put("raisedAmount", p.getRaisedAmount());
            pm.put("reportDue", reportDue);
            pm.put("lastReportAt", lastReportAt);
            activeProjects.add(pm);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("role", "FARMER");
        result.put("totalProjects", projects.size());
        result.put("activeProjects", activeCount);
        result.put("fundingProjects", fundingCount);
        result.put("completedProjects", completedCount);
        result.put("totalRaised", totalRaised);
        result.put("reportsDue", reportsDue);
        result.put("pendingExpenses", expenseRepository.countBySubmittedByIdAndStatus(principal.getId(), ExpenseStatus.PENDING));
        result.put("lastVetInspectionAt", vetInspectionRepository
                .findFirstByProjectFarmerIdAndStatusOrderByInspectionDateDesc(principal.getId(), VetInspectionStatus.VERIFIED)
                .map(v -> v.getInspectionDate())
                .orElse(null));
        result.put("projects", activeProjects);
        return result;
    }

    private record UUID_TITLE(java.util.UUID id, String title) {}
}
