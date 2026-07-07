package uz.agroinvest.module.project;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.AssetType;
import uz.agroinvest.common.enums.InvestmentStatus;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.PaymentProvider;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.TransactionStatus;
import uz.agroinvest.common.enums.TransactionType;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.investment.entity.Investment;
import uz.agroinvest.module.project.dto.CreateProjectRequest;
import uz.agroinvest.module.project.dto.ProjectDto;
import uz.agroinvest.module.project.dto.UpdateProjectRequest;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.superadmin.PlatformSettingsService;
import uz.agroinvest.module.transaction.TransactionRepository;
import uz.agroinvest.module.transaction.entity.Transaction;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.module.wallet.WalletRepository;
import uz.agroinvest.module.wallet.entity.Wallet;
import uz.agroinvest.security.UserPrincipal;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final PlatformSettingsService platformSettingsService;
    private final InvestmentRepository investmentRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;

    public ProjectService(
            ProjectRepository projectRepository,
            UserRepository userRepository,
            PlatformSettingsService platformSettingsService,
            InvestmentRepository investmentRepository,
            WalletRepository walletRepository,
            TransactionRepository transactionRepository
    ) {
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
        this.platformSettingsService = platformSettingsService;
        this.investmentRepository = investmentRepository;
        this.walletRepository = walletRepository;
        this.transactionRepository = transactionRepository;
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
        // Locked for the whole transition: a concurrent second call (double-click,
        // retried request) blocks here until the first commits, instead of both
        // reading the same pre-transition status and both applying their change.
        Project project = projectRepository.findByIdForUpdate(projectId)
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
            // Investors who already committed funds during FUNDING must be made whole
            // before we cancel - a CANCELLED project can never reach the ACTIVE/COMPLETED
            // payout path, so their escrowed (frozen) money would otherwise be locked forever.
            refundConfirmedInvestments(project);
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
            // Completion must always go through PayoutService.distributePayout (see
            // POST /{id}/payout) so commission/investor/farmer shares are actually
            // distributed and escrowed funds are unfrozen. Allowing it here would let
            // an admin flip a project to COMPLETED with investor money still frozen
            // and no payout ever recorded.
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Loyihani yakunlash faqat /api/v1/projects/{id}/payout endpointi orqali amalga oshiriladi");
        }

        Project savedProject = projectRepository.save(project);
        return mapToDto(savedProject);
    }

    /**
     * Refunds every CONFIRMED investment in the project: unfreezes the investor's
     * escrowed balance, marks the investment REFUNDED, and records an immutable
     * REFUND transaction - mirroring InvestmentService#cancelInvestment's single-investment
     * logic, applied to every investor when the whole project is cancelled.
     */
    private void refundConfirmedInvestments(Project project) {
        List<Investment> investments = investmentRepository.findByProjectIdAndStatus(project.getId(), InvestmentStatus.CONFIRMED);
        for (Investment investment : investments) {
            Wallet wallet = walletRepository.findByUserIdForUpdate(investment.getInvestor().getId())
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Investor hamyoni topilmadi"));

            wallet.setFrozen(wallet.getFrozen().subtract(investment.getAmount()));
            wallet.setBalance(wallet.getBalance().add(investment.getAmount()));
            walletRepository.save(wallet);

            investment.setStatus(InvestmentStatus.REFUNDED);
            investment.setCancelledAt(LocalDateTime.now());
            investment.setCancelReason("Loyiha bekor qilingani sababli mablag' qaytarildi");
            investmentRepository.save(investment);

            Transaction refundTxn = Transaction.builder()
                    .user(investment.getInvestor())
                    .project(project)
                    .investment(investment)
                    .type(TransactionType.REFUND)
                    .amount(investment.getAmount())
                    .paymentProvider(PaymentProvider.INTERNAL)
                    .status(TransactionStatus.COMPLETED)
                    .build();
            transactionRepository.save(refundTxn);
        }
    }

    @Transactional(readOnly = true)
    public ProjectDto getProjectById(UUID projectId) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));
        return mapToDto(project);
    }

    @Transactional(readOnly = true)
    public Page<ProjectDto> getProjects(ProjectStatus status, AssetType assetType, String q, Pageable pageable) {
        String normalizedQ = (q == null || q.isBlank()) ? null : q.trim();
        return projectRepository.search(status, assetType, normalizedQ, pageable).map(this::mapToDto);
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
