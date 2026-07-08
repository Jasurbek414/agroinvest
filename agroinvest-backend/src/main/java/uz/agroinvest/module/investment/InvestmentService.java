package uz.agroinvest.module.investment;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.*;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.investment.dto.CreateInvestmentRequest;
import uz.agroinvest.module.investment.dto.InvestmentDto;
import uz.agroinvest.module.investment.entity.Investment;
import uz.agroinvest.module.project.ProjectRepository;
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
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class InvestmentService {

    private final InvestmentRepository investmentRepository;
    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final PlatformSettingsService platformSettingsService;
    private final AuditLogService auditLogService;

    public InvestmentService(
            InvestmentRepository investmentRepository,
            ProjectRepository projectRepository,
            UserRepository userRepository,
            WalletRepository walletRepository,
            TransactionRepository transactionRepository,
            PlatformSettingsService platformSettingsService,
            AuditLogService auditLogService
    ) {
        this.investmentRepository = investmentRepository;
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
        this.walletRepository = walletRepository;
        this.transactionRepository = transactionRepository;
        this.platformSettingsService = platformSettingsService;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public InvestmentDto createInvestment(CreateInvestmentRequest request, UserPrincipal principal) {
        // Idempotency: a resubmitted request with the same key returns the original
        // result instead of creating a second investment/wallet debit.
        if (request.getIdempotencyKey() != null && !request.getIdempotencyKey().isBlank()) {
            Investment existing = investmentRepository.findByIdempotencyKey(request.getIdempotencyKey()).orElse(null);
            if (existing != null) {
                return mapToDto(existing);
            }
        }

        // KYC gate (legal requirement, TZ section 8): money may only be committed
        // by an identity-verified investor - mirrors the farmer-side check in
        // ProjectService.createProject that was already enforced.
        User investorUser = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));
        if (investorUser.getKycStatus() != KycStatus.VERIFIED) {
            throw new ApiException(ErrorCode.KYC_REQUIRED, HttpStatus.BAD_REQUEST,
                    "Sarmoya kiritish uchun avval shaxsingizni tasdiqlang (KYC)");
        }

        // Lock the project row: two simultaneous investments into the same project
        // must not both read the same "remaining to fund" snapshot and overshoot the target.
        Project project = projectRepository.findByIdForUpdate(request.getProjectId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        // Vetting: only APPROVED or FUNDING projects can accept investments
        if (project.getStatus() != ProjectStatus.APPROVED && project.getStatus() != ProjectStatus.FUNDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Ushbu loyihaga hozirda sarmoya kiritib bo'lmaydi");
        }

        if (project.isFrozen()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Loyiha muzlatilgan, hozircha sarmoya kiritib bo'lmaydi");
        }

        BigDecimal remainingToFund = project.getTargetAmount().subtract(project.getRaisedAmount());
        if (request.getAmount().compareTo(remainingToFund) > 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Loyihani to'liq moliyalashtirish uchun " + remainingToFund + " UZS yetarli");
        }

        // Limit checks
        if (request.getAmount().compareTo(project.getMinInvestment()) < 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Minimal investitsiya summasi: " + project.getMinInvestment() + " UZS");
        }
        if (project.getMaxInvestment() != null && request.getAmount().compareTo(project.getMaxInvestment()) > 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Maksimal investitsiya summasi: " + project.getMaxInvestment() + " UZS");
        }

        // Check wallet (locked: see WalletRepository.findByUserIdForUpdate)
        Wallet wallet = walletRepository.findByUserIdForUpdate(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Hamyon topilmadi"));

        if (wallet.getBalance().compareTo(request.getAmount()) < 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Hamyoningizda yetarli mablag' mavjud emas. Balans: " + wallet.getBalance() + " UZS");
        }

        // Lock/Freeze wallet balance
        wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
        wallet.setFrozen(wallet.getFrozen().add(request.getAmount()));
        walletRepository.save(wallet);

        // Transition project to FUNDING status if it was APPROVED
        if (project.getStatus() == ProjectStatus.APPROVED) {
            project.setStatus(ProjectStatus.FUNDING);
        }

        // Update project raised amount
        project.setRaisedAmount(project.getRaisedAmount().add(request.getAmount()));
        project.setTotalInvestors(project.getTotalInvestors() + 1);

        // Calculate share percentage: (amount / targetAmount) * investorSharePct
        BigDecimal sharePct = request.getAmount()
                .divide(project.getTargetAmount(), 10, RoundingMode.HALF_UP)
                .multiply(project.getInvestorSharePct());

        User investor = investorUser; // fetched above for the KYC gate

        // Create Investment
        Investment investment = Investment.builder()
                .project(project)
                .investor(investor)
                .amount(request.getAmount())
                .sharePct(sharePct)
                .status(InvestmentStatus.CONFIRMED)
                .idempotencyKey(request.getIdempotencyKey())
                .build();

        Investment savedInvestment = investmentRepository.save(investment);

        // Record IMMUTABLE transaction
        Transaction transaction = Transaction.builder()
                .user(investor)
                .project(project)
                .investment(savedInvestment)
                .type(TransactionType.DEPOSIT)
                .amount(request.getAmount())
                .paymentProvider(PaymentProvider.INTERNAL)
                .status(TransactionStatus.COMPLETED)
                .idempotencyKey(request.getIdempotencyKey())
                .build();

        transactionRepository.save(transaction);

        // Working-capital advances to the farmer per TZ 7.1: half the target once 50%
        // is raised, the rest once fully funded. Must run before the ACTIVE-transition
        // check below so milestone 2 sees the just-updated raisedAmount.
        releaseFarmerMilestoneIfDue(project);

        // Auto transition to ACTIVE if project is fully funded
        if (project.getRaisedAmount().compareTo(project.getTargetAmount()) == 0) {
            project.setStatus(ProjectStatus.ACTIVE);
            project.setStartDate(LocalDate.now());
            project.setEndDate(LocalDate.now().plusDays(project.getDurationDays()));
        }
        projectRepository.save(project);

        auditLogService.log(investor, "CREATE_INVESTMENT", "Investment", savedInvestment.getId().toString(),
                null, "{\"projectId\": \"" + project.getId() + "\", \"amount\": \"" + request.getAmount() + "\"}");

        return mapToDto(savedInvestment);
    }

    private void releaseFarmerMilestoneIfDue(Project project) {
        BigDecimal half = project.getTargetAmount().multiply(BigDecimal.valueOf(0.5));

        if (project.getFarmerMilestone1PaidAt() == null && project.getRaisedAmount().compareTo(half) >= 0) {
            payFarmerMilestone(project, half, "MILESTONE_1");
            project.setFarmerMilestone1PaidAt(LocalDateTime.now());
        }

        if (project.getFarmerMilestone2PaidAt() == null && project.getRaisedAmount().compareTo(project.getTargetAmount()) >= 0) {
            BigDecimal remaining = project.getTargetAmount().subtract(half);
            payFarmerMilestone(project, remaining, "MILESTONE_2");
            project.setFarmerMilestone2PaidAt(LocalDateTime.now());
        }
    }

    private void payFarmerMilestone(Project project, BigDecimal amount, String stage) {
        Wallet farmerWallet = walletRepository.findByUserIdForUpdate(project.getFarmer().getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Fermer hamyoni topilmadi"));

        farmerWallet.setBalance(farmerWallet.getBalance().add(amount));
        walletRepository.save(farmerWallet);

        Transaction txn = Transaction.builder()
                .user(project.getFarmer())
                .project(project)
                .type(TransactionType.FARMER_PAYOUT)
                .amount(amount)
                .status(TransactionStatus.COMPLETED)
                .metadata("{\"stage\": \"" + stage + "\"}")
                .build();
        transactionRepository.save(txn);
    }

    @Transactional
    public void cancelInvestment(UUID investmentId, UserPrincipal principal) {
        Investment investment = investmentRepository.findById(investmentId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Investitsiya topilmadi"));

        if (!investment.getInvestor().getId().equals(principal.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN);
        }

        if (investment.getStatus() != InvestmentStatus.CONFIRMED) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Ushbu investitsiyani bekor qilib bo'lmaydi");
        }

        // Locked for consistency with createInvestment/PayoutService: without this, a
        // cancel racing a concurrent createInvestment/payout on the same project could
        // both read the same pre-update raisedAmount and overwrite each other's change.
        Project project = projectRepository.findByIdForUpdate(investment.getProject().getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));
        if (project.getStatus() != ProjectStatus.FUNDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Loyiha moliyalashtirish bosqichida bo'lmagani uchun investitsiyani bekor qilish imkonsiz");
        }

        // Once the farmer has already been advanced working capital against the
        // current raised amount (see releaseFarmerMilestoneIfDue), unwinding any
        // investment would leave the project under-collateralized against that advance.
        if (project.getFarmerMilestone1PaidAt() != null) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Loyihaga fermerga mablag' chiqarilgani sababli investitsiyani endi bekor qilib bo'lmaydi");
        }

        // Cancellation window is platform-configurable (default 24h) - see PlatformSettingsService.
        long cancelWindowHours = platformSettingsService.getMaxInvestmentCancelHours();
        if (investment.getCreatedAt().plusHours(cancelWindowHours).isBefore(LocalDateTime.now())) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Investitsiyani bekor qilish muddati (" + cancelWindowHours + " soat) tugagan");
        }

        Wallet wallet = walletRepository.findByUserIdForUpdate(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        // Unfreeze wallet balance
        wallet.setFrozen(wallet.getFrozen().subtract(investment.getAmount()));
        wallet.setBalance(wallet.getBalance().add(investment.getAmount()));
        walletRepository.save(wallet);

        // Reduce project raised amount
        project.setRaisedAmount(project.getRaisedAmount().subtract(investment.getAmount()));
        project.setTotalInvestors(Math.max(0, project.getTotalInvestors() - 1));
        
        // If project transitions back to empty raised amount and was funding, keep it funding or change to approved
        if (project.getRaisedAmount().compareTo(BigDecimal.ZERO) == 0) {
            project.setStatus(ProjectStatus.APPROVED);
        }
        projectRepository.save(project);

        // Cancel investment status
        investment.setStatus(InvestmentStatus.CANCELLED);
        investment.setCancelledAt(LocalDateTime.now());
        investment.setCancelReason("Investor tomonidan bekor qilindi");
        investmentRepository.save(investment);

        // Record IMMUTABLE REFUND transaction
        Transaction transaction = Transaction.builder()
                .user(investment.getInvestor())
                .project(project)
                .investment(investment)
                .type(TransactionType.REFUND)
                .amount(investment.getAmount())
                .paymentProvider(PaymentProvider.INTERNAL)
                .status(TransactionStatus.COMPLETED)
                .build();

        transactionRepository.save(transaction);

        auditLogService.log(investment.getInvestor(), "CANCEL_INVESTMENT", "Investment", investment.getId().toString(),
                "{\"status\": \"CONFIRMED\"}", "{\"status\": \"CANCELLED\", \"amount\": \"" + investment.getAmount() + "\"}");
    }

    @Transactional(readOnly = true)
    public Page<InvestmentDto> getMyInvestments(UserPrincipal principal, Pageable pageable) {
        return investmentRepository.findByInvestorId(principal.getId(), pageable).map(this::mapToDto);
    }

    @Transactional(readOnly = true)
    public java.util.List<InvestmentDto> getProjectInvestments(UUID projectId, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        boolean isOwnProject = project.getFarmer().getId().equals(principal.getId());
        boolean isStaff = principal.getRole() == UserRole.ADMIN
                || principal.getRole() == UserRole.MODERATOR
                || principal.getRole() == UserRole.SUPERADMIN;
        if (!isOwnProject && !isStaff) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Ushbu loyiha investorlarini ko'rishga ruxsatingiz yo'q");
        }

        return investmentRepository.findByProjectId(projectId).stream().map(this::mapToDto).toList();
    }

    private InvestmentDto mapToDto(Investment investment) {
        return new InvestmentDto(
                investment.getId(),
                investment.getProject().getId(),
                investment.getProject().getTitle(),
                investment.getInvestor().getId(),
                investment.getInvestor().getFullName(),
                investment.getAmount(),
                investment.getSharePct(),
                investment.getContractUrl(),
                investment.getStatus(),
                investment.getCreatedAt()
        );
    }
}
