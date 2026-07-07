package uz.agroinvest.module.admin;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.module.project.ProjectRepository;
import uz.agroinvest.module.user.UserRepository;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class AdminService {

    private final UserRepository userRepository;
    private final ProjectRepository projectRepository;

    public AdminService(UserRepository userRepository, ProjectRepository projectRepository) {
        this.userRepository = userRepository;
        this.projectRepository = projectRepository;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getDashboardStats() {
        Map<String, Object> stats = new HashMap<>();

        // Computed with COUNT/SUM in the DB rather than pulling every user/project row
        // into memory (as findAll().stream().filter()/.map().reduce() previously did),
        // which would get slower and more memory-hungry as the platform grows.
        long totalUsers = userRepository.count();
        long activeProjects = projectRepository.countByStatus(ProjectStatus.ACTIVE);
        long pendingVetting = userRepository.countByKycStatusAndRole(KycStatus.PENDING, UserRole.FARMER);
        long pendingProjects = projectRepository.countByStatus(ProjectStatus.PENDING);
        BigDecimal totalRaised = projectRepository.sumRaisedAmount();

        stats.put("totalUsers", totalUsers);
        stats.put("activeProjects", activeProjects);
        stats.put("pendingVetting", pendingVetting);
        stats.put("pendingProjects", pendingProjects);
        stats.put("totalRaised", totalRaised);

        return stats;
    }

    // Feeds AssetTypeBarChart - one entry per AssetType with its project count.
    @Transactional(readOnly = true)
    public Map<String, Long> getAssetTypeBreakdown() {
        Map<String, Long> breakdown = new LinkedHashMap<>();
        for (ProjectRepository.AssetTypeCount row : projectRepository.countGroupedByAssetType()) {
            breakdown.put(row.getAssetType().name(), row.getCount());
        }
        return breakdown;
    }

    // Feeds ProjectStatusPieChart - one entry per ProjectStatus with its count.
    @Transactional(readOnly = true)
    public Map<String, Long> getProjectStatusBreakdown() {
        Map<String, Long> breakdown = new LinkedHashMap<>();
        for (ProjectRepository.StatusCount row : projectRepository.countGroupedByStatus()) {
            breakdown.put(row.getStatus().name(), row.getCount());
        }
        return breakdown;
    }
}
