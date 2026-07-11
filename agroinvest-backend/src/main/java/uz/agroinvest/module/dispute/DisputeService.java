package uz.agroinvest.module.dispute;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.DisputeStatus;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.dispute.dto.CreateDisputeRequest;
import uz.agroinvest.module.dispute.dto.DisputeDto;
import uz.agroinvest.module.dispute.entity.Dispute;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.project.ProjectRepository;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.superadmin.AuditLogService;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class DisputeService {

    private final DisputeRepository disputeRepository;
    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final InvestmentRepository investmentRepository;
    private final AuditLogService auditLogService;

    public DisputeService(
            DisputeRepository disputeRepository,
            ProjectRepository projectRepository,
            UserRepository userRepository,
            InvestmentRepository investmentRepository,
            AuditLogService auditLogService
    ) {
        this.disputeRepository = disputeRepository;
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
        this.investmentRepository = investmentRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public DisputeDto fileDispute(CreateDisputeRequest request, UserPrincipal principal) {
        User filer = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        Project project = null;
        if (request.getProjectId() != null) {
            project = projectRepository.findById(request.getProjectId())
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

            // A dispute can only be raised by someone with an actual stake in the project -
            // its farmer, or an investor who has put money into it - not any authenticated user.
            boolean isProjectFarmer = project.getFarmer().getId().equals(filer.getId());
            boolean isProjectInvestor = investmentRepository.existsByProjectIdAndInvestorId(project.getId(), filer.getId());
            if (!isProjectFarmer && !isProjectInvestor) {
                throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Ushbu loyiha bo'yicha shikoyat ochish uchun unda ishtirokingiz bo'lishi kerak");
            }
        }

        User against = null;
        if (request.getAgainstUserId() != null) {
            against = userRepository.findById(request.getAgainstUserId())
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Shikoyat qilinayotgan foydalanuvchi topilmadi"));
        }

        Dispute dispute = Dispute.builder()
                .project(project)
                .filedBy(filer)
                .againstUser(against)
                .disputeType(request.getDisputeType())
                .description(request.getDescription())
                .status(DisputeStatus.OPEN)
                .build();

        Dispute savedDispute = disputeRepository.save(dispute);
        return mapToDto(savedDispute);
    }

    @Transactional
    public DisputeDto startInvestigation(UUID disputeId, UserPrincipal principal) {
        Dispute dispute = disputeRepository.findById(disputeId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Nizo topilmadi"));

        if (dispute.getStatus() != DisputeStatus.OPEN) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat OPEN holatidagi nizoni tekshiruvga olish mumkin");
        }

        dispute.setStatus(DisputeStatus.INVESTIGATING);
        Dispute savedDispute = disputeRepository.save(dispute);
        return mapToDto(savedDispute);
    }

    @Transactional
    public DisputeDto resolveDispute(UUID disputeId, String resolution, UserPrincipal principal) {
        Dispute dispute = disputeRepository.findById(disputeId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Nizo topilmadi"));

        // Only an OPEN or INVESTIGATING dispute can be resolved - without this guard,
        // an already RESOLVED/CLOSED dispute's resolution/resolvedBy/resolvedAt could be
        // silently overwritten at any later time, destroying the audit trail of who
        // actually resolved it and when.
        if (dispute.getStatus() != DisputeStatus.OPEN && dispute.getStatus() != DisputeStatus.INVESTIGATING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Ushbu nizo allaqachon hal qilingan yoki yopilgan");
        }

        User admin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        dispute.setStatus(DisputeStatus.RESOLVED);
        dispute.setResolution(resolution);
        dispute.setResolvedBy(admin);
        dispute.setResolvedAt(LocalDateTime.now());

        Dispute savedDispute = disputeRepository.save(dispute);
        auditLogService.log(admin, "RESOLVE_DISPUTE", "Dispute", savedDispute.getId().toString(),
                null, "{\"resolution\": \"" + resolution + "\"}");
        return mapToDto(savedDispute);
    }

    @Transactional
    public DisputeDto closeDispute(UUID disputeId, UserPrincipal principal) {
        Dispute dispute = disputeRepository.findById(disputeId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Nizo topilmadi"));

        if (dispute.getStatus() != DisputeStatus.RESOLVED) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat RESOLVED holatidagi nizoni yopish mumkin");
        }

        dispute.setStatus(DisputeStatus.CLOSED);
        Dispute savedDispute = disputeRepository.save(dispute);
        return mapToDto(savedDispute);
    }

    @Transactional(readOnly = true)
    public List<DisputeDto> getProjectDisputes(UUID projectId) {
        return disputeRepository.findByProjectId(projectId).stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<DisputeDto> getAllDisputes(Pageable pageable) {
        return disputeRepository.findAll(pageable).map(this::mapToDto);
    }

    @Transactional(readOnly = true)
    public Page<DisputeDto> getMyDisputes(UUID userId, Pageable pageable) {
        return disputeRepository.findByFiledById(userId, pageable).map(this::mapToDto);
    }

    private DisputeDto mapToDto(Dispute dispute) {
        return new DisputeDto(
                dispute.getId(),
                dispute.getProject() != null ? dispute.getProject().getId() : null,
                dispute.getProject() != null ? dispute.getProject().getTitle() : "Platforma (Umumiy)",
                dispute.getFiledBy().getId(),
                dispute.getFiledBy().getFullName(),
                dispute.getAgainstUser() != null ? dispute.getAgainstUser().getId() : null,
                dispute.getAgainstUser() != null ? dispute.getAgainstUser().getFullName() : "Platforma",
                dispute.getDisputeType(),
                dispute.getDescription(),
                dispute.getStatus(),
                dispute.getResolution(),
                dispute.getCreatedAt()
        );
    }
}
