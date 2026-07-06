package uz.agroinvest.module.project;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.project.dto.CreateProjectRequest;
import uz.agroinvest.module.project.dto.ProjectDto;
import uz.agroinvest.module.project.dto.UpdateProjectRequest;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.superadmin.PlatformSettingsService;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final PlatformSettingsService platformSettingsService;

    public ProjectService(
            ProjectRepository projectRepository,
            UserRepository userRepository,
            PlatformSettingsService platformSettingsService
    ) {
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
        this.platformSettingsService = platformSettingsService;
    }

    @Transactional
    public ProjectDto createProject(CreateProjectRequest request, UserPrincipal principal) {
        User farmer = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Fermer topilmadi"));

        // Vetting check
        if (farmer.getKycStatus() != KycStatus.VERIFIED) {
            throw new ApiException(ErrorCode.KYC_REQUIRED, HttpStatus.BAD_REQUEST, "Loyiya yaratish uchun profilingiz tasdiqlangan bo'lishi shart");
        }

        BigDecimal minInvestment = request.getMinInvestment() != null
                ? request.getMinInvestment()
                : platformSettingsService.getMinInvestmentAmount();

        Project project = Project.builder()
                .farmer(farmer)
                .assetType(request.getAssetType())
                .title(request.getTitle())
                .description(request.getDescription())
                .region(request.getRegion())
                .locationDetails(request.getLocationDetails())
                .targetAmount(request.getTargetAmount())
                .raisedAmount(BigDecimal.ZERO)
                .minInvestment(minInvestment)
                .maxInvestment(request.getMaxInvestment())
                .expectedReturnPct(request.getExpectedReturnPct())
                .commissionPct(platformSettingsService.getCommissionPct())
                .investorSharePct(platformSettingsService.getInvestorSharePct())
                .farmerSharePct(platformSettingsService.getFarmerSharePct())
                .durationDays(request.getDurationDays())
                .riskLevel(request.getRiskLevel())
                .status(ProjectStatus.PENDING)
                .mediaUrls(request.getMediaUrls())
                .totalInvestors(0)
                .reportFrequencyDays(platformSettingsService.getReportFrequencyDays())
                .build();

        Project savedProject = projectRepository.save(project);
        return mapToDto(savedProject);
    }

    @Transactional
    public ProjectDto updateProject(UUID projectId, UpdateProjectRequest request, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        // Only project owner (farmer) can edit, and only in PENDING status
        if (!project.getFarmer().getId().equals(principal.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Ushbu loyihani tahrirlash huquqi sizda yo'q");
        }

        if (project.getStatus() != ProjectStatus.PENDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat kutilayotgan (PENDING) loyihalarni tahrirlash mumkin");
        }

        if (request.getAssetType() != null) project.setAssetType(request.getAssetType());
        if (request.getTitle() != null) project.setTitle(request.getTitle());
        if (request.getDescription() != null) project.setDescription(request.getDescription());
        if (request.getRegion() != null) project.setRegion(request.getRegion());
        if (request.getLocationDetails() != null) project.setLocationDetails(request.getLocationDetails());
        if (request.getTargetAmount() != null) project.setTargetAmount(request.getTargetAmount());
        if (request.getMinInvestment() != null) project.setMinInvestment(request.getMinInvestment());
        if (request.getMaxInvestment() != null) project.setMaxInvestment(request.getMaxInvestment());
        if (request.getExpectedReturnPct() != null) project.setExpectedReturnPct(request.getExpectedReturnPct());
        if (request.getDurationDays() != null) project.setDurationDays(request.getDurationDays());
        if (request.getRiskLevel() != null) project.setRiskLevel(request.getRiskLevel());
        if (request.getMediaUrls() != null) project.setMediaUrls(request.getMediaUrls());

        Project updatedProject = projectRepository.save(project);
        return mapToDto(updatedProject);
    }

    @Transactional
    public void deleteProject(UUID projectId, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        if (!project.getFarmer().getId().equals(principal.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN);
        }

        if (project.getStatus() != ProjectStatus.PENDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat kutilayotgan (PENDING) loyihalarni bekor qilish mumkin");
        }

        projectRepository.delete(project);
    }

    @Transactional
    public ProjectDto changeStatus(UUID projectId, ProjectStatus status, String rejectionReason, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        User admin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        // State Machine validation
        if (status == ProjectStatus.APPROVED) {
            if (project.getStatus() != ProjectStatus.PENDING) {
                throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Loyiha holati PENDING bo'lishi shart");
            }
            project.setStatus(ProjectStatus.APPROVED);
            project.setApprovedBy(admin);
            project.setApprovedAt(LocalDateTime.now());
        } else if (status == ProjectStatus.CANCELLED) {
            if (project.getStatus() != ProjectStatus.PENDING && project.getStatus() != ProjectStatus.APPROVED && project.getStatus() != ProjectStatus.FUNDING) {
                throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Ushbu holatdagi loyihani rad/bekor qilib bo'lmaydi");
            }
            project.setStatus(ProjectStatus.CANCELLED);
            project.setRejectionReason(rejectionReason);
        } else if (status == ProjectStatus.FUNDING) {
            if (project.getStatus() != ProjectStatus.APPROVED) {
                throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST);
            }
            project.setStatus(ProjectStatus.FUNDING);
        } else if (status == ProjectStatus.ACTIVE) {
            if (project.getStatus() != ProjectStatus.FUNDING) {
                throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST);
            }
            project.setStatus(ProjectStatus.ACTIVE);
            project.setStartDate(LocalDate.now());
            project.setEndDate(LocalDate.now().plusDays(project.getDurationDays()));
        } else if (status == ProjectStatus.COMPLETED) {
            if (project.getStatus() != ProjectStatus.ACTIVE) {
                throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST);
            }
            project.setStatus(ProjectStatus.COMPLETED);
            project.setCompletedAt(LocalDateTime.now());
        }

        Project savedProject = projectRepository.save(project);
        return mapToDto(savedProject);
    }

    @Transactional(readOnly = true)
    public ProjectDto getProjectById(UUID projectId) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));
        return mapToDto(project);
    }

    @Transactional(readOnly = true)
    public Page<ProjectDto> getProjects(ProjectStatus status, Pageable pageable) {
        Page<Project> page;
        if (status != null) {
            page = projectRepository.findByStatus(status, pageable);
        } else {
            page = projectRepository.findAll(pageable);
        }
        return page.map(this::mapToDto);
    }

    @Transactional(readOnly = true)
    public Page<ProjectDto> getFarmerProjects(UUID farmerId, Pageable pageable) {
        return projectRepository.findByFarmerId(farmerId, pageable).map(this::mapToDto);
    }

    public ProjectDto mapToDto(Project project) {
        return new ProjectDto(
                project.getId(),
                project.getFarmer().getId(),
                project.getFarmer().getFullName(),
                project.getAssetType(),
                project.getTitle(),
                project.getDescription(),
                project.getRegion(),
                project.getLocationDetails(),
                project.getTargetAmount(),
                project.getRaisedAmount(),
                project.getMinInvestment(),
                project.getMaxInvestment(),
                project.getExpectedReturnPct(),
                project.getCommissionPct(),
                project.getInvestorSharePct(),
                project.getFarmerSharePct(),
                project.getDurationDays(),
                project.getStartDate(),
                project.getEndDate(),
                project.getRiskLevel(),
                project.getStatus(),
                project.getRejectionReason(),
                project.getMediaUrls(),
                project.getTotalInvestors(),
                project.getReportFrequencyDays(),
                project.getCreatedAt()
        );
    }
}
