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

        long totalUsers = userRepository.count();
        long activeProjects = projectRepository.findAll().stream()
                .filter(p -> p.getStatus() == ProjectStatus.ACTIVE)
                .count();

        long pendingVetting = userRepository.findAll().stream()
                .filter(u -> u.getKycStatus() == KycStatus.PENDING && u.getRole() == UserRole.FARMER)
                .count();

        long pendingProjects = projectRepository.findAll().stream()
                .filter(p -> p.getStatus() == ProjectStatus.PENDING)
                .count();

        BigDecimal totalRaised = projectRepository.findAll().stream()
                .map(p -> p.getRaisedAmount() != null ? p.getRaisedAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        stats.put("totalUsers", totalUsers);
        stats.put("activeProjects", activeProjects);
        stats.put("pendingVetting", pendingVetting);
        stats.put("pendingProjects", pendingProjects);
        stats.put("totalRaised", totalRaised);

        return stats;
    }
}
