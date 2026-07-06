package uz.agroinvest.module.report;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import uz.agroinvest.common.enums.NotificationChannel;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.module.notification.NotificationService;
import uz.agroinvest.module.project.ProjectRepository;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;

import java.time.LocalDateTime;
import java.util.List;

/**
 * TZ 8.2: "Kechikkan hisobot ogohlantirish | Har 14 kunda majburiy... 2 kun o'tsa -> SMS + Telegram".
 * Runs daily; re-alerts every day a project stays overdue rather than tracking a
 * separate "already alerted" flag - simpler, and keeps nagging admins until the
 * farmer actually submits something or the project is closed out.
 */
@Component
public class ReportMonitoringScheduler {

    private static final Logger logger = LoggerFactory.getLogger(ReportMonitoringScheduler.class);
    private static final int LATE_GRACE_DAYS = 2;

    private final ProjectRepository projectRepository;
    private final ReportRepository reportRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public ReportMonitoringScheduler(
            ProjectRepository projectRepository,
            ReportRepository reportRepository,
            UserRepository userRepository,
            NotificationService notificationService
    ) {
        this.projectRepository = projectRepository;
        this.reportRepository = reportRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    @Scheduled(cron = "0 0 9 * * *") // 09:00 daily
    public void checkLateReports() {
        List<Project> activeProjects = projectRepository.findByStatus(ProjectStatus.ACTIVE, Pageable.unpaged()).getContent();
        LocalDateTime now = LocalDateTime.now();
        int lateCount = 0;

        for (Project project : activeProjects) {
            LocalDateTime lastActivity = reportRepository.findFirstByProjectIdOrderByCreatedAtDesc(project.getId())
                    .map(r -> r.getCreatedAt())
                    .orElseGet(() -> project.getStartDate() != null ? project.getStartDate().atStartOfDay() : project.getCreatedAt());

            int reportFrequencyDays = project.getReportFrequencyDays() != null ? project.getReportFrequencyDays() : 14;
            long dueAfterDays = reportFrequencyDays + LATE_GRACE_DAYS;

            if (lastActivity.plusDays(dueAfterDays).isBefore(now)) {
                notifyAdminsOfLateProject(project, lastActivity);
                lateCount++;
            }
        }

        if (lateCount > 0) {
            logger.info("Late-report check: {} project(s) flagged as overdue", lateCount);
        }
    }

    private void notifyAdminsOfLateProject(Project project, LocalDateTime lastActivity) {
        String title = "Kechikkan hisobot";
        String message = "\"" + project.getTitle() + "\" loyihasi bo'yicha fermer belgilangan muddatda hisobot yuklamadi (oxirgi faoliyat: "
                + lastActivity.toLocalDate() + ").";
        notifyStaff(title, message, "LATE_REPORT");
    }

    private void notifyStaff(String title, String message, String type) {
        List<User> staff = userRepository.findByRoleIn(List.of(UserRole.ADMIN, UserRole.SUPERADMIN));
        for (User admin : staff) {
            try {
                notificationService.createNotification(admin, type, title, message, NotificationChannel.IN_APP);
                notificationService.createNotification(admin, type, title, message, NotificationChannel.SMS);
                notificationService.createNotification(admin, type, title, message, NotificationChannel.TELEGRAM);
            } catch (Exception e) {
                logger.error("Failed to notify admin {} about {}", admin.getId(), type, e);
            }
        }
    }
}
