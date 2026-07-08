package uz.agroinvest.module.vet;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.NotificationChannel;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.enums.VetInspectionStatus;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.notification.NotificationService;
import uz.agroinvest.module.project.ProjectRepository;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.superadmin.AuditLogService;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.module.vet.dto.CreateVetInspectionRequest;
import uz.agroinvest.module.vet.dto.VetInspectionDto;
import uz.agroinvest.module.vet.entity.VetInspection;
import uz.agroinvest.security.UserPrincipal;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class VetInspectionService {

    private static final Set<UserRole> STAFF_ROLES = Set.of(UserRole.SUPERADMIN, UserRole.ADMIN, UserRole.MODERATOR);

    private final VetInspectionRepository vetInspectionRepository;
    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final AuditLogService auditLogService;

    public VetInspectionService(
            VetInspectionRepository vetInspectionRepository,
            ProjectRepository projectRepository,
            UserRepository userRepository,
            NotificationService notificationService,
            AuditLogService auditLogService
    ) {
        this.vetInspectionRepository = vetInspectionRepository;
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public VetInspectionDto submitInspection(UUID projectId, CreateVetInspectionRequest request, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        if (!project.getFarmer().getId().equals(principal.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN,
                    "Faqat loyiha egasi veterinar hujjatini yuklashi mumkin");
        }

        if (project.getStatus() != ProjectStatus.ACTIVE && project.getStatus() != ProjectStatus.FUNDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Veterinar hujjati faqat faol yoki moliyalashtirilayotgan loyihaga yuklanadi");
        }

        User farmer = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        VetInspection inspection = VetInspection.builder()
                .project(project)
                .uploadedBy(farmer)
                .vetName(request.getVetName())
                .vetLicenseNo(request.getVetLicenseNo())
                .inspectionDate(request.getInspectionDate())
                .documentUrls(request.getDocumentUrls())
                .conclusion(request.getConclusion())
                .healthStatus(request.getHealthStatus())
                .status(VetInspectionStatus.PENDING)
                .build();

        return mapToDto(vetInspectionRepository.save(inspection));
    }

    /**
     * VERIFIED inspections are public (trust signal). The farmer-owner and staff
     * additionally see PENDING/REJECTED ones. principal may be null (anonymous).
     */
    @Transactional(readOnly = true)
    public List<VetInspectionDto> getProjectInspections(UUID projectId, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        boolean isOwner = principal != null && project.getFarmer().getId().equals(principal.getId());
        boolean isStaff = principal != null && STAFF_ROLES.contains(principal.getRole());

        List<VetInspection> inspections = (isOwner || isStaff)
                ? vetInspectionRepository.findByProjectIdOrderByInspectionDateDesc(projectId)
                : vetInspectionRepository.findByProjectIdAndStatusOrderByInspectionDateDesc(projectId, VetInspectionStatus.VERIFIED);

        return inspections.stream().map(this::mapToDto).toList();
    }

    @Transactional(readOnly = true)
    public Page<VetInspectionDto> getPendingInspections(Pageable pageable) {
        return vetInspectionRepository.findByStatusOrderByCreatedAtAsc(VetInspectionStatus.PENDING, pageable)
                .map(this::mapToDto);
    }

    @Transactional
    public VetInspectionDto verifyInspection(UUID inspectionId, boolean approve, String comment, UserPrincipal principal) {
        VetInspection inspection = vetInspectionRepository.findById(inspectionId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Hujjat topilmadi"));

        if (inspection.getStatus() != VetInspectionStatus.PENDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Faqat kutilayotgan hujjatni ko'rib chiqish mumkin");
        }

        User reviewer = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        inspection.setStatus(approve ? VetInspectionStatus.VERIFIED : VetInspectionStatus.REJECTED);
        inspection.setVerifiedBy(reviewer);
        inspection.setVerifiedAt(LocalDateTime.now());
        inspection.setAdminComment(comment);
        VetInspection saved = vetInspectionRepository.save(inspection);

        auditLogService.log(reviewer, approve ? "VERIFY_VET_INSPECTION" : "REJECT_VET_INSPECTION", "VetInspection", saved.getId().toString(),
                "{\"status\": \"PENDING\"}",
                "{\"status\": \"" + saved.getStatus() + "\", \"comment\": \"" + (comment != null ? comment : "") + "\"}");

        notificationService.createNotification(
                inspection.getUploadedBy(),
                "VET_INSPECTION_REVIEWED",
                approve ? "Veterinar hujjati tasdiqlandi" : "Veterinar hujjati rad etildi",
                "\"" + inspection.getProject().getTitle() + "\" loyihasidagi veterinar xulosangiz "
                        + (approve ? "tasdiqlandi" : ("rad etildi" + (comment != null && !comment.isBlank() ? ": " + comment : ""))),
                NotificationChannel.IN_APP
        );

        return mapToDto(saved);
    }

    private VetInspectionDto mapToDto(VetInspection inspection) {
        return VetInspectionDto.builder()
                .id(inspection.getId())
                .projectId(inspection.getProject().getId())
                .projectTitle(inspection.getProject().getTitle())
                .vetName(inspection.getVetName())
                .vetLicenseNo(inspection.getVetLicenseNo())
                .inspectionDate(inspection.getInspectionDate())
                .documentUrls(inspection.getDocumentUrls())
                .conclusion(inspection.getConclusion())
                .healthStatus(inspection.getHealthStatus())
                .status(inspection.getStatus())
                .adminComment(inspection.getAdminComment())
                .verifiedAt(inspection.getVerifiedAt())
                .createdAt(inspection.getCreatedAt())
                .build();
    }
}
