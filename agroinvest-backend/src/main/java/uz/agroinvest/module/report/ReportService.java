package uz.agroinvest.module.report;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.NotificationChannel;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.ReportType;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.notification.NotificationService;
import uz.agroinvest.module.project.ProjectRepository;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.report.dto.CreateReportRequest;
import uz.agroinvest.module.report.dto.ReportDto;
import uz.agroinvest.module.report.entity.Report;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class ReportService {

    private final ReportRepository reportRepository;
    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public ReportService(
            ReportRepository reportRepository,
            ProjectRepository projectRepository,
            UserRepository userRepository,
            NotificationService notificationService
    ) {
        this.reportRepository = reportRepository;
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    @Transactional
    public ReportDto submitReport(UUID projectId, CreateReportRequest request, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        User submitter = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        // Authorization: only the assigned farmer or a verifier can submit
        boolean isFarmerOwner = project.getFarmer().getId().equals(principal.getId()) && principal.getRole() == UserRole.FARMER;
        boolean isVerifier = principal.getRole() == UserRole.VERIFIER;

        if (!isFarmerOwner && !isVerifier) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Ushbu loyihaga hisobot yuklash huquqi sizda yo'q");
        }

        // Only active or completed projects can receive reports
        if (project.getStatus() != ProjectStatus.ACTIVE && project.getStatus() != ProjectStatus.FUNDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Loyihaga hozircha hisobot yuklab bo'lmaydi");
        }

        Map<String, Object> metrics = sanitizeMetrics(request.getReportType(), request.getMetrics());

        Report report = Report.builder()
                .project(project)
                .submittedBy(submitter)
                .reportType(request.getReportType())
                .mediaUrls(request.getMediaUrls())
                .geoLat(request.getGeoLat())
                .geoLng(request.getGeoLng())
                .geoAccuracy(request.getGeoAccuracy())
                .notes(request.getNotes())
                .metrics(metrics)
                .isVerified(false)
                .build();

        Report savedReport = reportRepository.save(report);

        // TZ 8.2: an EMERGENCY report must alert staff immediately, not wait for the
        // next admin review pass.
        if (request.getReportType() == ReportType.EMERGENCY) {
            notifyStaffOfEmergencyReport(project, submitter);
        }

        return mapToDto(savedReport);
    }

    // Whitelisted DAILY-log metric keys and their expected shapes. A free-form
    // JSONB column must not become a dumping ground for arbitrary client JSON.
    private static final Set<String> NUMERIC_METRIC_KEYS = Set.of("headcount", "deaths", "feedKg", "avgWeightKg");
    private static final String HEALTH_NOTE_KEY = "healthNote";

    private Map<String, Object> sanitizeMetrics(ReportType reportType, Map<String, Object> raw) {
        if (reportType != ReportType.DAILY) {
            return null; // metrics only carried on daily logs
        }
        if (raw == null || raw.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Kunlik hisobot uchun ko'rsatkichlarni kiriting (bosh soni, o'lim, yem...)");
        }
        Map<String, Object> clean = new LinkedHashMap<>();
        for (String key : NUMERIC_METRIC_KEYS) {
            Object value = raw.get(key);
            if (value == null) continue;
            if (!(value instanceof Number number) || number.doubleValue() < 0) {
                throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                        "Ko'rsatkich noto'g'ri: " + key + " manfiy bo'lmagan son bo'lishi kerak");
            }
            clean.put(key, number);
        }
        Object healthNote = raw.get(HEALTH_NOTE_KEY);
        if (healthNote instanceof String note && !note.isBlank()) {
            if (note.length() > 500) {
                throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Salomatlik izohi juda uzun");
            }
            clean.put(HEALTH_NOTE_KEY, note);
        }
        if (!clean.containsKey("headcount")) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Kunlik hisobotda joriy bosh soni (headcount) majburiy");
        }
        return clean;
    }

    private void notifyStaffOfEmergencyReport(Project project, User submitter) {
        String title = "Favqulodda hisobot";
        String message = submitter.getFullName() + " \"" + project.getTitle() + "\" loyihasi bo'yicha favqulodda hisobot yubordi. Zudlik bilan tekshiring.";

        List<User> staff = userRepository.findByRoleIn(List.of(UserRole.ADMIN, UserRole.SUPERADMIN));
        for (User admin : staff) {
            notificationService.createNotification(admin, "EMERGENCY_REPORT", title, message, NotificationChannel.IN_APP);
            notificationService.createNotification(admin, "EMERGENCY_REPORT", title, message, NotificationChannel.SMS);
            notificationService.createNotification(admin, "EMERGENCY_REPORT", title, message, NotificationChannel.TELEGRAM);
        }
    }

    @Transactional
    public ReportDto verifyReport(UUID reportId, boolean verify, String adminComment, UserPrincipal principal) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Hisobot topilmadi"));

        User admin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        report.setVerified(verify);
        report.setVerifiedBy(admin);
        report.setVerifiedAt(LocalDateTime.now());
        report.setAdminComment(adminComment);

        Report savedReport = reportRepository.save(report);
        return mapToDto(savedReport);
    }

    @Transactional(readOnly = true)
    public Page<ReportDto> getProjectReports(UUID projectId, Pageable pageable) {
        return reportRepository.findByProjectId(projectId, pageable).map(this::mapToDto);
    }

    @Transactional(readOnly = true)
    public Page<ReportDto> getUnverifiedReports(Pageable pageable) {
        return reportRepository.findByIsVerifiedFalse(pageable).map(this::mapToDto);
    }

    private ReportDto mapToDto(Report report) {
        return new ReportDto(
                report.getId(),
                report.getProject().getId(),
                report.getProject().getTitle(),
                report.getSubmittedBy().getId(),
                report.getSubmittedBy().getFullName(),
                report.getReportType(),
                report.getMediaUrls(),
                report.getGeoLat(),
                report.getGeoLng(),
                report.getGeoAccuracy(),
                report.getNotes(),
                report.getMetrics(),
                report.isVerified(),
                report.getAdminComment(),
                report.getCreatedAt()
        );
    }
}
