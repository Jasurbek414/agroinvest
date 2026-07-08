package uz.agroinvest.module.superadmin;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.superadmin.dto.AuditLogDto;
import uz.agroinvest.module.superadmin.dto.PlatformSettingsDto;
import uz.agroinvest.module.superadmin.entity.AuditLog;
import uz.agroinvest.module.superadmin.entity.PlatformSettings;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.UserService;
import uz.agroinvest.module.user.dto.UserDto;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class SuperAdminService {

    private final UserRepository userRepository;
    private final UserService userService;
    private final PlatformSettingsRepository platformSettingsRepository;
    private final AuditLogRepository auditLogRepository;
    private final AuditLogService auditLogService;
    private final PasswordEncoder passwordEncoder;

    public SuperAdminService(
            UserRepository userRepository,
            UserService userService,
            PlatformSettingsRepository platformSettingsRepository,
            AuditLogRepository auditLogRepository,
            AuditLogService auditLogService,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.userService = userService;
        this.platformSettingsRepository = platformSettingsRepository;
        this.auditLogRepository = auditLogRepository;
        this.auditLogService = auditLogService;
        this.passwordEncoder = passwordEncoder;
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
    public Page<UserDto> getAccounts(UserRole role, String q, Pageable pageable) {
        List<UserRole> roles = role != null ? List.of(role) : STAFF_ROLES;
        String normalizedQ = (q == null || q.isBlank()) ? null : q.trim();
        return userRepository.searchByRoles(roles, normalizedQ, pageable).map(userService::mapToDto);
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
    public Page<AuditLogDto> getAuditLogs(String action, Pageable pageable) {
        Page<AuditLog> page = (action != null && !action.isBlank())
                ? auditLogRepository.findByAction(action, pageable)
                : auditLogRepository.findAll(pageable);
        return page.map(this::mapToDto);
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
}
