package uz.agroinvest.module.superadmin;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.DepositStatus;
import uz.agroinvest.common.enums.DisputeStatus;
import uz.agroinvest.common.enums.ExpenseStatus;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.NotificationChannel;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.TransactionStatus;
import uz.agroinvest.common.enums.InvestmentStatus;
import uz.agroinvest.common.enums.TransactionType;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.enums.VetInspectionStatus;
import uz.agroinvest.common.enums.WithdrawalStatus;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.deposit.DepositRequestRepository;
import uz.agroinvest.module.dispute.DisputeRepository;
import uz.agroinvest.module.expense.ExpenseRepository;
import uz.agroinvest.module.notification.NotificationService;
import uz.agroinvest.module.project.ProjectRepository;
import uz.agroinvest.module.report.ReportRepository;
import uz.agroinvest.module.superadmin.dto.AuditLogDto;
import uz.agroinvest.module.superadmin.dto.PlatformSettingsDto;
import uz.agroinvest.module.superadmin.entity.AuditLog;
import uz.agroinvest.module.superadmin.entity.PlatformSettings;
import uz.agroinvest.module.transaction.TransactionRepository;
import uz.agroinvest.module.transaction.dto.TransactionDto;
import uz.agroinvest.module.transaction.entity.Transaction;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.UserService;
import uz.agroinvest.module.user.dto.UserDto;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.module.vet.VetInspectionRepository;
import uz.agroinvest.module.wallet.WalletRepository;
import uz.agroinvest.module.wallet.entity.Wallet;
import uz.agroinvest.module.withdrawal.WithdrawalRepository;
import uz.agroinvest.security.UserPrincipal;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.investment.entity.Investment;
import uz.agroinvest.module.investment.dto.InvestmentDto;
import uz.agroinvest.module.coop.CoopOfferRepository;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class SuperAdminService {

    private final UserRepository userRepository;
    private final UserService userService;
    private final PlatformSettingsRepository platformSettingsRepository;
    private final AuditLogRepository auditLogRepository;
    private final AuditLogService auditLogService;
    private final PasswordEncoder passwordEncoder;
    private final ProjectRepository projectRepository;
    private final WalletRepository walletRepository;
    private final WithdrawalRepository withdrawalRepository;
    private final DepositRequestRepository depositRequestRepository;
    private final DisputeRepository disputeRepository;
    private final ReportRepository reportRepository;
    private final ExpenseRepository expenseRepository;
    private final VetInspectionRepository vetInspectionRepository;
    private final TransactionRepository transactionRepository;
    private final NotificationService notificationService;
    private final InvestmentRepository investmentRepository;

    @Autowired
    @Lazy
    private CoopOfferRepository coopOfferRepository;

    public SuperAdminService(
            UserRepository userRepository,
            UserService userService,
            PlatformSettingsRepository platformSettingsRepository,
            AuditLogRepository auditLogRepository,
            AuditLogService auditLogService,
            PasswordEncoder passwordEncoder,
            ProjectRepository projectRepository,
            WalletRepository walletRepository,
            WithdrawalRepository withdrawalRepository,
            DepositRequestRepository depositRequestRepository,
            DisputeRepository disputeRepository,
            ReportRepository reportRepository,
            ExpenseRepository expenseRepository,
            VetInspectionRepository vetInspectionRepository,
            TransactionRepository transactionRepository,
            NotificationService notificationService,
            InvestmentRepository investmentRepository
    ) {
        this.userRepository = userRepository;
        this.userService = userService;
        this.platformSettingsRepository = platformSettingsRepository;
        this.auditLogRepository = auditLogRepository;
        this.auditLogService = auditLogService;
        this.passwordEncoder = passwordEncoder;
        this.projectRepository = projectRepository;
        this.walletRepository = walletRepository;
        this.withdrawalRepository = withdrawalRepository;
        this.depositRequestRepository = depositRequestRepository;
        this.disputeRepository = disputeRepository;
        this.reportRepository = reportRepository;
        this.expenseRepository = expenseRepository;
        this.vetInspectionRepository = vetInspectionRepository;
        this.transactionRepository = transactionRepository;
        this.notificationService = notificationService;
        this.investmentRepository = investmentRepository;
    }

    @Transactional
    public UserDto createAdminAccount(String phone, String name, String password, UserRole role, UserPrincipal principal) {
        if (userRepository.existsByPhoneNumber(phone)) {
            throw new ApiException(ErrorCode.PHONE_ALREADY_EXISTS, HttpStatus.BAD_REQUEST);
        }

        // Restrict role: only administrative roles can be created here
        if (role != UserRole.ADMIN && role != UserRole.MODERATOR && role != UserRole.VERIFIER) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.BAD_REQUEST, "Ushbu rolda akkount yaratib bo'lmaydi");
        }

        User user = User.builder()
                .fullName(name)
                .phoneNumber(phone)
                .passwordHash(passwordEncoder.encode(password))
                .role(role)
                .kycStatus(KycStatus.VERIFIED) // Administrative accounts are auto-verified
                .isActive(true)
                .isBlocked(false)
                .build();

        User savedUser = userRepository.save(user);

        User superadmin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        auditLogService.log(superadmin, "CREATE_ADMIN_ACCOUNT", "User", savedUser.getId().toString(),
                null, "{\"role\": \"" + role.name() + "\", \"phone\": \"" + phone + "\"}");

        return userService.getUserDtoById(savedUser.getId());
    }

    private static final List<UserRole> STAFF_ROLES = List.of(UserRole.ADMIN, UserRole.MODERATOR, UserRole.VERIFIER, UserRole.SUPERADMIN);

    /**
     * Lists administrative accounts only (admin/moderator/verifier/superadmin) - a
     * genuinely separate view from AccountsPanel's previous behavior of reusing the
     * KYC tab's generic getUsers(), which mixed in every investor/farmer too.
     */
    @Transactional(readOnly = true)
    public Page<UserDto> getAccounts(List<UserRole> roles, Boolean blocked, String q, Pageable pageable) {
        List<UserRole> finalRoles = (roles != null && !roles.isEmpty()) ? roles : List.of(UserRole.values());
        String normalizedQ = (q == null || q.isBlank()) ? null : q.trim();
        return userRepository.searchByRoles(finalRoles, blocked, normalizedQ, pageable).map(userService::mapToDto);
    }

    @Transactional
    public void blockAccount(UUID userId, boolean block, String reason, UserPrincipal principal) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));

        // SuperAdmin cannot block their own account
        if (user.getId().equals(principal.getId())) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "O'zingizning akkountingizni bloklay olmaysiz");
        }

        User superadmin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        user.setBlocked(block);
        if (block) {
            user.setBlockedReason(reason);
            user.setBlockedAt(LocalDateTime.now());
            user.setBlockedBy(superadmin);
        } else {
            user.setBlockedReason(null);
            user.setBlockedAt(null);
            user.setBlockedBy(null);
        }
        userRepository.save(user);

        auditLogService.log(superadmin, block ? "BLOCK_ACCOUNT" : "UNBLOCK_ACCOUNT", "User", user.getId().toString(),
                null, "{\"blockedReason\": \"" + (reason != null ? reason : "") + "\"}");
    }

    // TZ 1.4: platform commission must stay within an 8-15% band regardless of what
    // a SuperAdmin types into the settings UI.
    private static final String COMMISSION_SETTING_KEY = "default_commission_pct";
    private static final java.math.BigDecimal COMMISSION_MIN = java.math.BigDecimal.valueOf(8);
    private static final java.math.BigDecimal COMMISSION_MAX = java.math.BigDecimal.valueOf(15);

    // These two settings seed every new project's investor_share_pct/farmer_share_pct,
    // which the DB enforces (V5__platform_constraints.sql) must sum to exactly 100.
    // They can only be changed together via updateInvestorFarmerShares below - editing
    // one alone here would otherwise let the pair drift apart and make every subsequent
    // project-creation request fail against that DB constraint.
    private static final String INVESTOR_SHARE_KEY = "default_investor_share_pct";
    private static final String FARMER_SHARE_KEY = "default_farmer_share_pct";

    @Transactional
    public PlatformSettingsDto updateSetting(String key, String value, UserPrincipal principal) {
        if (INVESTOR_SHARE_KEY.equals(key) || FARMER_SHARE_KEY.equals(key)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Investor va fermer ulushlarini PATCH /api/v1/superadmin/settings/shares orqali birgalikda o'zgartiring");
        }

        PlatformSettings setting = platformSettingsRepository.findBySettingKey(key)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Sozlama topilmadi"));

        if (COMMISSION_SETTING_KEY.equals(key)) {
            java.math.BigDecimal parsed;
            try {
                parsed = new java.math.BigDecimal(value);
            } catch (NumberFormatException e) {
                throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Komissiya foizi raqam bo'lishi kerak");
            }
            if (parsed.compareTo(COMMISSION_MIN) < 0 || parsed.compareTo(COMMISSION_MAX) > 0) {
                throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Komissiya foizi 8% dan 15% gacha oralig'ida bo'lishi shart");
            }
        }

        String oldVal = setting.getSettingValue();
        User superadmin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        setting.setSettingValue(value);
        setting.setUpdatedBy(superadmin);
        PlatformSettings saved = platformSettingsRepository.save(setting);

        auditLogService.log(superadmin, "UPDATE_SETTING", "PlatformSettings", saved.getId().toString(),
                "{\"value\": \"" + oldVal + "\"}", "{\"value\": \"" + value + "\"}");

        return mapToDto(saved);
    }

    /**
     * Atomically updates the investor/farmer default share settings together, so the
     * pair can never be persisted out of sync with the DB's "must sum to 100" constraint.
     */
    @Transactional
    public void updateInvestorFarmerShares(java.math.BigDecimal investorPct, java.math.BigDecimal farmerPct, UserPrincipal principal) {
        if (investorPct == null || farmerPct == null
                || investorPct.compareTo(java.math.BigDecimal.ZERO) < 0
                || farmerPct.compareTo(java.math.BigDecimal.ZERO) < 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Ulush foizlari manfiy bo'lmagan raqam bo'lishi shart");
        }
        if (investorPct.add(farmerPct).compareTo(java.math.BigDecimal.valueOf(100)) != 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Investor va fermer ulushlari yig'indisi aynan 100% bo'lishi shart");
        }

        PlatformSettings investorSetting = platformSettingsRepository.findBySettingKey(INVESTOR_SHARE_KEY)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Sozlama topilmadi"));
        PlatformSettings farmerSetting = platformSettingsRepository.findBySettingKey(FARMER_SHARE_KEY)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Sozlama topilmadi"));

        String oldInvestorVal = investorSetting.getSettingValue();
        String oldFarmerVal = farmerSetting.getSettingValue();

        User superadmin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        investorSetting.setSettingValue(investorPct.toPlainString());
        investorSetting.setUpdatedBy(superadmin);
        platformSettingsRepository.save(investorSetting);

        farmerSetting.setSettingValue(farmerPct.toPlainString());
        farmerSetting.setUpdatedBy(superadmin);
        platformSettingsRepository.save(farmerSetting);

        auditLogService.log(superadmin, "UPDATE_INVESTOR_FARMER_SHARES", "PlatformSettings",
                investorSetting.getId().toString() + "," + farmerSetting.getId().toString(),
                "{\"investorSharePct\": \"" + oldInvestorVal + "\", \"farmerSharePct\": \"" + oldFarmerVal + "\"}",
                "{\"investorSharePct\": \"" + investorPct + "\", \"farmerSharePct\": \"" + farmerPct + "\"}");
    }

    @Transactional(readOnly = true)
    public Page<AuditLogDto> getAuditLogs(String action, String entityType, LocalDateTime from, LocalDateTime to, Pageable pageable) {
        String normalizedAction = (action == null || action.isBlank()) ? null : action.trim();
        String normalizedEntityType = (entityType == null || entityType.isBlank()) ? null : entityType.trim();
        return auditLogRepository.search(normalizedAction, normalizedEntityType, from, to, pageable).map(this::mapToDto);
    }

    /**
     * Overview tab: one aggregated snapshot of the whole platform (user base, money
     * flow, and every pending review queue) so the SuperAdmin lands on a single
     * screen instead of opening eight tabs to see where work is piling up.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getPlatformOverview() {
        Map<String, Object> overview = new LinkedHashMap<>();

        Map<String, Object> users = new LinkedHashMap<>();
        users.put("total", userRepository.count());
        users.put("investors", userRepository.countByRole(UserRole.INVESTOR));
        users.put("farmers", userRepository.countByRole(UserRole.FARMER));
        long staff = userRepository.countByRole(UserRole.ADMIN)
                + userRepository.countByRole(UserRole.MODERATOR)
                + userRepository.countByRole(UserRole.VERIFIER)
                + userRepository.countByRole(UserRole.SUPERADMIN);
        users.put("staff", staff);
        users.put("blocked", userRepository.countByIsBlockedTrue());
        overview.put("users", users);

        Map<String, Object> finance = new LinkedHashMap<>();
        finance.put("totalRaised", projectRepository.sumRaisedAmount());
        finance.put("walletBalance", walletRepository.sumBalances());
        finance.put("completedVolume", transactionRepository.sumAmountByStatus(TransactionStatus.COMPLETED));
        finance.put("pendingTransactions", transactionRepository.countByStatus(TransactionStatus.PENDING));
        overview.put("finance", finance);

        Map<String, Object> queues = new LinkedHashMap<>();
        queues.put("withdrawals", withdrawalRepository.countByStatus(WithdrawalStatus.PENDING));
        queues.put("deposits", depositRequestRepository.countByStatus(DepositStatus.PENDING));
        queues.put("kyc", userRepository.countByKycStatusAndRole(KycStatus.PENDING, UserRole.FARMER));
        queues.put("projects", projectRepository.countByStatus(ProjectStatus.PENDING));
        queues.put("reports", reportRepository.countByIsVerifiedFalse());
        queues.put("expenses", expenseRepository.countByStatus(ExpenseStatus.PENDING));
        queues.put("vetInspections", vetInspectionRepository.countByStatus(VetInspectionStatus.PENDING));
        queues.put("disputes", disputeRepository.countByStatusIn(List.of(DisputeStatus.OPEN, DisputeStatus.INVESTIGATING)));
        queues.put("coop", coopOfferRepository.countByStatus("PENDING"));
        overview.put("queues", queues);

        return overview;
    }

    /**
     * Sends one announcement to every non-blocked user of the given role (or the
     * whole platform when role is null). Delivery is sequential per user via
     * NotificationService, so keep the default channel IN_APP - SMS/Telegram fan-out
     * to thousands of users would hold this request open for the whole send.
     */
    @Transactional
    public long broadcastNotification(
            String title,
            String message,
            UserRole role,
            List<UUID> userIds,
            KycStatus kycStatus,
            Boolean blocked,
            NotificationChannel channel,
            UserPrincipal principal
    ) {
        if (title == null || title.isBlank() || message == null || message.isBlank()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Sarlavha va xabar matni bo'sh bo'lishi mumkin emas");
        }
        NotificationChannel effectiveChannel = channel != null ? channel : NotificationChannel.IN_APP;

        List<User> recipients;
        if (userIds != null && !userIds.isEmpty()) {
            recipients = userRepository.findAllById(userIds);
        } else if (role != null) {
            recipients = userRepository.findByRoleIn(List.of(role));
        } else {
            recipients = userRepository.findAll();
        }

        long sent = 0;
        for (User recipient : recipients) {
            if (blocked != null && recipient.isBlocked() != blocked) continue;
            if (kycStatus != null && recipient.getKycStatus() != kycStatus) continue;
            // Default: if target is all users, skip blocked users unless explicitly asked
            if (blocked == null && recipient.isBlocked()) continue;

            notificationService.createNotification(recipient, "ANNOUNCEMENT", title, message, effectiveChannel);
            sent++;
        }

        User superadmin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
        auditLogService.log(superadmin, "BROADCAST_NOTIFICATION", "Notification", null,
                null, "{\"role\": \"" + (role != null ? role.name() : "ALL") + "\", \"channel\": \"" + effectiveChannel.name()
                        + "\", \"recipients\": " + sent + ", \"title\": \"" + title.replace("\"", "'") + "\"}");

        return sent;
    }

    /** Platform-wide transaction listing with optional type/status/date filters. */
    @Transactional(readOnly = true)
    public Page<TransactionDto> getTransactions(TransactionType type, TransactionStatus status,
                                                LocalDateTime from, LocalDateTime to, Pageable pageable) {
        return transactionRepository.search(type, status, from, to, pageable).map(this::mapToTransactionDto);
    }

    // CSV export is capped so one request can't stream the entire transactions table.
    private static final int TRANSACTION_EXPORT_LIMIT = 5000;

    @Transactional(readOnly = true)
    public String exportTransactionsCsv(TransactionType type, TransactionStatus status,
                                        LocalDateTime from, LocalDateTime to) {
        Pageable limit = org.springframework.data.domain.PageRequest.of(
                0, TRANSACTION_EXPORT_LIMIT, org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "createdAt"));
        StringBuilder csv = new StringBuilder("id,createdAt,userName,userPhone,type,status,amount,currency,provider,projectTitle\n");
        for (Transaction t : transactionRepository.search(type, status, from, to, limit).getContent()) {
            csv.append(csvCell(t.getId()))
                    .append(',').append(csvCell(t.getCreatedAt()))
                    .append(',').append(csvCell(t.getUser() != null ? t.getUser().getFullName() : null))
                    .append(',').append(csvCell(t.getUser() != null ? t.getUser().getPhoneNumber() : null))
                    .append(',').append(csvCell(t.getType()))
                    .append(',').append(csvCell(t.getStatus()))
                    .append(',').append(csvCell(t.getAmount()))
                    .append(',').append(csvCell(t.getCurrency()))
                    .append(',').append(csvCell(t.getPaymentProvider()))
                    .append(',').append(csvCell(t.getProject() != null ? t.getProject().getTitle() : null))
                    .append('\n');
        }
        return csv.toString();
    }

    private String csvCell(Object value) {
        if (value == null) return "";
        String s = value.toString();
        if (s.contains(",") || s.contains("\"") || s.contains("\n")) {
            return "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }

    // Staff roles a SuperAdmin may manage (create/reset password/re-role). Other
    // SUPERADMIN accounts and end users (investor/farmer) are deliberately excluded.
    private static final List<UserRole> MANAGEABLE_STAFF_ROLES = List.of(UserRole.ADMIN, UserRole.MODERATOR, UserRole.VERIFIER);

    @Transactional
    public void resetStaffPassword(UUID userId, String newPassword, UserPrincipal principal) {
        if (newPassword == null || newPassword.length() < 6) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Yangi parol kamida 6 belgidan iborat bo'lishi kerak");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));
        if (!MANAGEABLE_STAFF_ROLES.contains(user.getRole())) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.BAD_REQUEST, "Faqat admin, moderator va verifikator hisoblarining parolini tiklash mumkin");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        User superadmin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
        auditLogService.log(superadmin, "RESET_STAFF_PASSWORD", "User", user.getId().toString(), null, null);
    }

    @Transactional
    public UserDto changeStaffRole(UUID userId, UserRole newRole, UserPrincipal principal) {
        if (!MANAGEABLE_STAFF_ROLES.contains(newRole)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat admin, moderator yoki verifikator roliga o'zgartirish mumkin");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));
        if (!MANAGEABLE_STAFF_ROLES.contains(user.getRole())) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.BAD_REQUEST, "Faqat admin, moderator va verifikator hisoblarining rolini o'zgartirish mumkin");
        }

        UserRole oldRole = user.getRole();
        user.setRole(newRole);
        userRepository.save(user);

        User superadmin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
        auditLogService.log(superadmin, "CHANGE_STAFF_ROLE", "User", user.getId().toString(),
                "{\"role\": \"" + oldRole.name() + "\"}", "{\"role\": \"" + newRole.name() + "\"}");

        return userService.getUserDtoById(user.getId());
    }

    @Transactional
    public void topUpWallet(UUID userId, java.math.BigDecimal amount, UserPrincipal principal) {
        if (amount == null || amount.compareTo(java.math.BigDecimal.ZERO) <= 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "To'ldirish summasi 0 dan katta bo'lishi kerak");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));
        
        Wallet wallet = walletRepository.findByUserIdForUpdate(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Hamyon topilmadi"));

        wallet.setBalance(wallet.getBalance().add(amount));
        walletRepository.save(wallet);

        Transaction transaction = Transaction.builder()
                .user(user)
                .type(TransactionType.DEPOSIT)
                .amount(amount)
                .status(TransactionStatus.COMPLETED)
                .paymentProvider(uz.agroinvest.common.enums.PaymentProvider.MANUAL)
                .metadata("{\"reason\": \"SuperAdmin manual top-up\"}")
                .build();
        transactionRepository.save(transaction);

        User superadmin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
        auditLogService.log(superadmin, "MANUAL_TOPUP_WALLET", "Wallet", wallet.getId().toString(),
                null, "{\"userId\": \"" + userId + "\", \"amount\": \"" + amount + "\"}");
    }


    private TransactionDto mapToTransactionDto(Transaction t) {
        return TransactionDto.builder()
                .id(t.getId())
                .userId(t.getUser() != null ? t.getUser().getId() : null)
                .userName(t.getUser() != null ? t.getUser().getFullName() : null)
                .userPhone(t.getUser() != null ? t.getUser().getPhoneNumber() : null)
                .projectId(t.getProject() != null ? t.getProject().getId() : null)
                .projectTitle(t.getProject() != null ? t.getProject().getTitle() : null)
                .investmentId(t.getInvestment() != null ? t.getInvestment().getId() : null)
                .type(t.getType())
                .amount(t.getAmount())
                .currency(t.getCurrency())
                .paymentProvider(t.getPaymentProvider())
                .externalPaymentId(t.getExternalPaymentId())
                .status(t.getStatus())
                .createdAt(t.getCreatedAt())
                .build();
    }

    @Transactional(readOnly = true)
    public Page<PlatformSettingsDto> getSettings(Pageable pageable) {
        return platformSettingsRepository.findAll(pageable).map(this::mapToDto);
    }

    private AuditLogDto mapToDto(AuditLog log) {
        return AuditLogDto.builder()
                .id(log.getId())
                .userId(log.getUser() != null ? log.getUser().getId() : null)
                .userName(log.getUser() != null ? log.getUser().getFullName() : null)
                .action(log.getAction())
                .entityType(log.getEntityType())
                .entityId(log.getEntityId())
                .oldValue(log.getOldValue())
                .newValue(log.getNewValue())
                .ipAddress(log.getIpAddress())
                .userAgent(log.getUserAgent())
                .createdAt(log.getCreatedAt())
                .build();
    }

    private PlatformSettingsDto mapToDto(PlatformSettings setting) {
        return PlatformSettingsDto.builder()
                .id(setting.getId())
                .settingKey(setting.getSettingKey())
                .settingValue(setting.getSettingValue())
                .description(setting.getDescription())
                .updatedByName(setting.getUpdatedBy() != null ? setting.getUpdatedBy().getFullName() : null)
                .updatedAt(setting.getUpdatedAt())
                .build();
    }

    @Transactional
    public void updateInvestmentContractUrl(UUID investmentId, String contractUrl, UserPrincipal principal) {
        Investment investment = investmentRepository.findById(investmentId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Sarmoya topilmadi"));
        
        User superadmin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        String oldUrl = investment.getContractUrl();
        investment.setContractUrl(contractUrl);
        investmentRepository.save(investment);
        
        auditLogService.log(
                superadmin,
                "UPDATE_CONTRACT",
                "Investment",
                investmentId.toString(),
                oldUrl,
                contractUrl
        );
    }

    @Transactional(readOnly = true)
    public Page<InvestmentDto> getInvestments(String q, InvestmentStatus status, Pageable pageable) {
        Page<Investment> page;
        boolean hasQ = q != null && !q.trim().isEmpty();
        boolean hasStatus = status != null;

        if (hasQ && hasStatus) {
            page = investmentRepository.findByStatusAndSearch(status, q.trim(), pageable);
        } else if (hasStatus) {
            page = investmentRepository.findByStatus(status, pageable);
        } else if (hasQ) {
            page = investmentRepository.findAllWithSearch(q.trim(), pageable);
        } else {
            page = investmentRepository.findAllWithGraph(pageable);
        }
        return page.map(this::mapToInvestmentDto);
    }

    private InvestmentDto mapToInvestmentDto(Investment investment) {
        return new InvestmentDto(
                investment.getId(),
                investment.getProject().getId(),
                investment.getProject().getTitle(),
                investment.getInvestor().getId(),
                investment.getInvestor().getFullName(),
                investment.getAmount(),
                investment.getSharePct(),
                investment.getContractUrl(),
                investment.getContractSignedAt(),
                investment.getStatus(),
                investment.getCreatedAt(),
                false,
                null
        );
    }
}
