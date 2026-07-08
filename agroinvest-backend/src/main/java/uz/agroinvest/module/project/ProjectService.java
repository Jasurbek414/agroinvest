package uz.agroinvest.module.project;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.AnimalType;
import uz.agroinvest.common.enums.AssetType;
import uz.agroinvest.common.enums.ExpensePolicy;
import uz.agroinvest.common.enums.FundingMode;
import uz.agroinvest.common.enums.InvestmentStatus;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.PaymentProvider;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.TransactionStatus;
import uz.agroinvest.common.enums.TransactionType;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.investment.entity.Investment;
import uz.agroinvest.module.project.dto.CreateProjectRequest;
import uz.agroinvest.module.project.dto.ProjectDto;
import uz.agroinvest.module.project.dto.ProjectInvestorDto;
import uz.agroinvest.module.project.dto.UpdateProjectRequest;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.superadmin.AuditLogService;
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
import java.util.Set;
import java.util.UUID;

@Service
public class ProjectService {

    private static final Set<UserRole> STAFF_ROLES = Set.of(UserRole.SUPERADMIN, UserRole.ADMIN, UserRole.MODERATOR);

    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final PlatformSettingsService platformSettingsService;
    private final InvestmentRepository investmentRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final AuditLogService auditLogService;

    public ProjectService(
            ProjectRepository projectRepository,
            UserRepository userRepository,
            PlatformSettingsService platformSettingsService,
            InvestmentRepository investmentRepository,
            WalletRepository walletRepository,
            TransactionRepository transactionRepository,
            AuditLogService auditLogService
    ) {
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
        this.platformSettingsService = platformSettingsService;
        this.investmentRepository = investmentRepository;
        this.walletRepository = walletRepository;
        this.transactionRepository = transactionRepository;
        this.auditLogService = auditLogService;
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

        // Negotiated profit split ("kelishuv asosida"): the farmer proposes the
        // investor share within platform bounds; farmer share is always the
        // complement so the V5 shares-sum CHECK (=100) can never be violated.
        BigDecimal investorSharePct = request.getProposedInvestorSharePct() != null
                ? request.getProposedInvestorSharePct()
                : platformSettingsService.getInvestorSharePct();
        validateInvestorShareBounds(investorSharePct);
        BigDecimal farmerSharePct = BigDecimal.valueOf(100).subtract(investorSharePct);

        validateLivestockFields(request.getAssetType(), request.getAnimalType(), request.getHeadcount());

        FundingMode fundingMode = request.getFundingMode() != null ? request.getFundingMode() : FundingMode.INVESTOR_FUNDED;
        BigDecimal contribution = request.getFarmerContributionValue() != null
                ? request.getFarmerContributionValue() : BigDecimal.ZERO;
        validateContribution(fundingMode, contribution);

        int reportFrequencyDays = request.getReportFrequencyDays() != null
                ? request.getReportFrequencyDays()
                : platformSettingsService.getReportFrequencyDays();

        Project project = Project.builder()
                .farmer(farmer)
                .assetType(request.getAssetType())
                .animalType(request.getAnimalType())
                .headcount(request.getHeadcount())
                .pricePerHead(request.getPricePerHead())
                .fundingMode(fundingMode)
                .farmerContributionValue(contribution)
                .farmerContributionNotes(request.getFarmerContributionNotes())
                .expensePolicy(request.getExpensePolicy() != null ? request.getExpensePolicy() : ExpensePolicy.INVESTOR_BUDGET)
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
                .investorSharePct(investorSharePct)
                .farmerSharePct(farmerSharePct)
                .durationDays(request.getDurationDays())
                .riskLevel(request.getRiskLevel())
                .status(Boolean.TRUE.equals(request.getSaveAsDraft()) ? ProjectStatus.DRAFT : ProjectStatus.PENDING)
                .mediaUrls(request.getMediaUrls())
                .totalInvestors(0)
                .reportFrequencyDays(reportFrequencyDays)
                .build();

        Project savedProject = projectRepository.save(project);
        return mapToDto(savedProject);
    }

    private void validateInvestorShareBounds(BigDecimal investorSharePct) {
        BigDecimal min = platformSettingsService.getMinInvestorSharePct();
        BigDecimal max = platformSettingsService.getMaxInvestorSharePct();
        if (investorSharePct.compareTo(min) < 0 || investorSharePct.compareTo(max) > 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Investor ulushi " + min.stripTrailingZeros().toPlainString() + "% dan "
                            + max.stripTrailingZeros().toPlainString() + "% gacha bo'lishi kerak");
        }
    }

    private void validateLivestockFields(AssetType assetType, AnimalType animalType, Integer headcount) {
        boolean animalProject = assetType == AssetType.LIVESTOCK || assetType == AssetType.POULTRY;
        if (animalProject && animalType == null) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Chorvachilik/parrandachilik loyihasi uchun hayvon turini tanlang");
        }
        if (animalProject && (headcount == null || headcount < 1)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Hayvonlar sonini (bosh) kiriting");
        }
        if (!animalProject && animalType != null) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Hayvon turi faqat chorvachilik/parrandachilik loyihalarida ko'rsatiladi");
        }
    }

    private void validateContribution(FundingMode fundingMode, BigDecimal contribution) {
        boolean hasContribution = contribution.compareTo(BigDecimal.ZERO) > 0;
        if (fundingMode == FundingMode.INVESTOR_FUNDED && hasContribution) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Investor mablag'iga asoslangan loyihada fermer hissasi 0 bo'lishi kerak");
        }
        if ((fundingMode == FundingMode.FARMER_ASSETS || fundingMode == FundingMode.MIXED) && !hasContribution) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "O'z hayvoni bilan kirishda fermer hissasi qiymatini kiriting");
        }
    }

    @Transactional
    public ProjectDto updateProject(UUID projectId, UpdateProjectRequest request, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        // Only project owner (farmer) can edit, and only in PENDING status
        if (!project.getFarmer().getId().equals(principal.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Ushbu loyihani tahrirlash huquqi sizda yo'q");
        }

        if (project.getStatus() != ProjectStatus.PENDING && project.getStatus() != ProjectStatus.DRAFT) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat kutilayotgan (PENDING) yoki qoralama (DRAFT) loyihalarni tahrirlash mumkin");
        }

        if (request.getAssetType() != null) project.setAssetType(request.getAssetType());
        if (request.getAnimalType() != null) project.setAnimalType(request.getAnimalType());
        if (request.getHeadcount() != null) project.setHeadcount(request.getHeadcount());
        if (request.getPricePerHead() != null) project.setPricePerHead(request.getPricePerHead());
        if (request.getFundingMode() != null) project.setFundingMode(request.getFundingMode());
        if (request.getFarmerContributionValue() != null) project.setFarmerContributionValue(request.getFarmerContributionValue());
        if (request.getFarmerContributionNotes() != null) project.setFarmerContributionNotes(request.getFarmerContributionNotes());
        if (request.getExpensePolicy() != null) project.setExpensePolicy(request.getExpensePolicy());
        if (request.getProposedInvestorSharePct() != null) {
            validateInvestorShareBounds(request.getProposedInvestorSharePct());
            project.setInvestorSharePct(request.getProposedInvestorSharePct());
            project.setFarmerSharePct(BigDecimal.valueOf(100).subtract(request.getProposedInvestorSharePct()));
        }
        if (request.getReportFrequencyDays() != null) project.setReportFrequencyDays(request.getReportFrequencyDays());
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

        // Cross-field consistency must hold for the RESULTING state, whichever
        // subset of fields this partial update touched.
        validateLivestockFields(project.getAssetType(), project.getAnimalType(), project.getHeadcount());
        validateContribution(project.getFundingMode(), project.getFarmerContributionValue());

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

        if (project.getStatus() != ProjectStatus.PENDING && project.getStatus() != ProjectStatus.DRAFT) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat kutilayotgan (PENDING) yoki qoralama (DRAFT) loyihalarni bekor qilish mumkin");
        }

        projectRepository.delete(project);
    }

    /**
     * Farmer's "e'lon qilish" (publish) action: moves a DRAFT project into the
     * normal PENDING review queue. changeStatus() below can't be reused for this -
     * it's staff-only (hasAnyRole ADMIN/SUPERADMIN/MODERATOR).
     */
    @Transactional
    public ProjectDto submitProject(UUID projectId, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        if (!project.getFarmer().getId().equals(principal.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN);
        }

        if (project.getStatus() != ProjectStatus.DRAFT) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat qoralama (DRAFT) loyihalarni ko'rib chiqishga yuborish mumkin");
        }

        project.setStatus(ProjectStatus.PENDING);
        Project saved = projectRepository.save(project);

        auditLogService.log(project.getFarmer(), "SUBMIT_PROJECT", "Project", saved.getId().toString(),
                "{\"status\": \"DRAFT\"}", "{\"status\": \"PENDING\"}");

        return mapToDto(saved);
    }

    /**
     * Freeze/unfreeze sits outside the status state machine entirely (see
     * PLATFORM_ROADMAP.md decision #3) - it can be applied from any status and
     * clearing it never needs to "restore" a prior status, because status itself
     * is never touched.
     */
    @Transactional
    public ProjectDto setFrozen(UUID projectId, boolean frozen, String reason, UserPrincipal principal) {
        Project project = projectRepository.findByIdForUpdate(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        if (project.isFrozen() == frozen) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    frozen ? "Loyiha allaqachon muzlatilgan" : "Loyiha muzlatilmagan");
        }

        User admin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        project.setFrozen(frozen);
        project.setFrozenReason(frozen ? reason : null);
        project.setFrozenAt(frozen ? LocalDateTime.now() : null);
        project.setFrozenBy(frozen ? admin : null);
        Project saved = projectRepository.save(project);

        auditLogService.log(admin, frozen ? "FREEZE_PROJECT" : "UNFREEZE_PROJECT", "Project", saved.getId().toString(),
                null, "{\"reason\": \"" + (reason != null ? reason : "") + "\"}");

        return mapToDto(saved);
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

        ProjectStatus previousStatus = project.getStatus();

        // State Machine validation
        if (status == ProjectStatus.APPROVED) {
            if (project.getStatus() != ProjectStatus.PENDING) {
                throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Loyiha holati PENDING bo'lishi shart");
            }
            project.setStatus(ProjectStatus.APPROVED);
            project.setApprovedBy(admin);
            project.setApprovedAt(LocalDateTime.now());
            // Approving a project with a declared farmer contribution attests the
            // valuation (admin reviewed photos/documents during vetting).
            if (project.getFarmerContributionValue() != null
                    && project.getFarmerContributionValue().compareTo(BigDecimal.ZERO) > 0) {
                project.setFarmerContributionVerifiedAt(LocalDateTime.now());
            }
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
        } else if (status == ProjectStatus.MONITORING) {
            if (project.getStatus() != ProjectStatus.ACTIVE) {
                throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat faol (ACTIVE) loyihalarni kuzatuvga (MONITORING) o'tkazish mumkin");
            }
            project.setStatus(ProjectStatus.MONITORING);
        } else if (status == ProjectStatus.COMPLETED) {
            // Completion must always go through PayoutService.distributePayout (see
            // POST /{id}/payout) so commission/investor/farmer shares are actually
            // distributed and escrowed funds are unfrozen. Allowing it here would let
            // an admin flip a project to COMPLETED with investor money still frozen
            // and no payout ever recorded.
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Loyihani yakunlash faqat /api/v1/projects/{id}/payout endpointi orqali amalga oshiriladi");
        } else {
            // DRAFT/PENDING (and any future value) are not admin-settable targets here:
            // DRAFT/PENDING only ever happen via createProject/submitProject. Without
            // this guard an unrecognized target silently no-ops the transition but the
            // audit call below would still fire, falsely recording a change that never
            // happened.
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Loyiha holatini " + status + " ga o'zgartirib bo'lmaydi");
        }

        Project savedProject = projectRepository.save(project);

        auditLogService.log(admin, "PROJECT_STATUS_" + status.name(), "Project", savedProject.getId().toString(),
                "{\"status\": \"" + previousStatus + "\"}",
                "{\"status\": \"" + status + "\", \"rejectionReason\": \"" + (rejectionReason != null ? rejectionReason : "") + "\"}");

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
    public ProjectDto getProjectById(UUID projectId, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        // This endpoint is public (permitAll) so a DRAFT - the farmer's not-yet-
        // submitted working copy - must be invisible to everyone except its owner
        // and staff, even if the UUID leaks. 404 (not 403) so existence isn't revealed.
        if (project.getStatus() == ProjectStatus.DRAFT) {
            boolean isOwner = principal != null && project.getFarmer().getId().equals(principal.getId());
            boolean isStaff = principal != null && STAFF_ROLES.contains(principal.getRole());
            if (!isOwner && !isStaff) {
                throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi");
            }
        }

        return mapToDto(project);
    }

    @Transactional(readOnly = true)
    public Page<ProjectDto> getProjects(ProjectStatus status, AssetType assetType, AnimalType animalType, String q, Pageable pageable) {
        String normalizedQ = (q == null || q.isBlank()) ? null : q.trim();
        return projectRepository.search(status, assetType, animalType, normalizedQ, pageable).map(this::mapToDto);
    }

    /**
     * Public-facing co-investor list for a project: masked names + share %, so
     * investors can see WHO ELSE is in and at what proportion, without leaking
     * personal data. Masking happens here in the service - never client-side.
     */
    @Transactional(readOnly = true)
    public List<ProjectInvestorDto> getProjectInvestors(UUID projectId) {
        projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));
        return investmentRepository.findByProjectIdAndStatus(projectId, InvestmentStatus.CONFIRMED).stream()
                .map(inv -> new ProjectInvestorDto(
                        maskName(inv.getInvestor().getFullName()),
                        inv.getAmount(),
                        inv.getSharePct(),
                        inv.getCreatedAt()))
                .toList();
    }

    // "Jasurbek Muminov" -> "Jasurbek M." ; single-word names get first letter + "."
    private String maskName(String fullName) {
        if (fullName == null || fullName.isBlank()) return "Investor";
        String[] parts = fullName.trim().split("\\s+");
        if (parts.length == 1) {
            return parts[0].charAt(0) + ".";
        }
        return parts[0] + " " + parts[1].charAt(0) + ".";
    }

    @Transactional(readOnly = true)
    public Page<ProjectDto> getFarmerProjects(UUID farmerId, Pageable pageable) {
        return projectRepository.findByFarmerId(farmerId, pageable).map(this::mapToDto);
    }

    public ProjectDto mapToDto(Project project) {
        return ProjectDto.builder()
                .id(project.getId())
                .farmerId(project.getFarmer().getId())
                .farmerName(project.getFarmer().getFullName())
                .farmerRating(project.getFarmer().getRating())
                .farmerTotalProjects(project.getFarmer().getTotalProjects())
                .farmerVerified(project.getFarmer().getKycStatus() == KycStatus.VERIFIED)
                .assetType(project.getAssetType())
                .animalType(project.getAnimalType())
                .headcount(project.getHeadcount())
                .pricePerHead(project.getPricePerHead())
                .fundingMode(project.getFundingMode())
                .farmerContributionValue(project.getFarmerContributionValue())
                .farmerContributionNotes(project.getFarmerContributionNotes())
                .farmerContributionVerifiedAt(project.getFarmerContributionVerifiedAt())
                .expensePolicy(project.getExpensePolicy())
                .title(project.getTitle())
                .description(project.getDescription())
                .region(project.getRegion())
                .locationDetails(project.getLocationDetails())
                .targetAmount(project.getTargetAmount())
                .raisedAmount(project.getRaisedAmount())
                .minInvestment(project.getMinInvestment())
                .maxInvestment(project.getMaxInvestment())
                .expectedReturnPct(project.getExpectedReturnPct())
                .commissionPct(project.getCommissionPct())
                .investorSharePct(project.getInvestorSharePct())
                .farmerSharePct(project.getFarmerSharePct())
                .durationDays(project.getDurationDays())
                .startDate(project.getStartDate())
                .endDate(project.getEndDate())
                .riskLevel(project.getRiskLevel())
                .status(project.getStatus())
                .rejectionReason(project.getRejectionReason())
                .mediaUrls(project.getMediaUrls())
                .totalInvestors(project.getTotalInvestors())
                .reportFrequencyDays(project.getReportFrequencyDays())
                .frozen(project.isFrozen())
                .frozenReason(project.getFrozenReason())
                .createdAt(project.getCreatedAt())
                .build();
    }
}
