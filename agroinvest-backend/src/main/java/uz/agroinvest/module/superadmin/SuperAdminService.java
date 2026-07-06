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
import uz.agroinvest.module.superadmin.entity.AuditLog;
import uz.agroinvest.module.superadmin.entity.PlatformSettings;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.UserService;
import uz.agroinvest.module.user.dto.UserDto;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class SuperAdminService {

    private final UserRepository userRepository;
    private final UserService userService;
    private final PlatformSettingsRepository platformSettingsRepository;
    private final AuditLogRepository auditLogRepository;
    private final PasswordEncoder passwordEncoder;

    public SuperAdminService(
            UserRepository userRepository,
            UserService userService,
            PlatformSettingsRepository platformSettingsRepository,
            AuditLogRepository auditLogRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.userService = userService;
        this.platformSettingsRepository = platformSettingsRepository;
        this.auditLogRepository = auditLogRepository;
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

        // Save Audit Log
        AuditLog audit = AuditLog.builder()
                .user(superadmin)
                .action("CREATE_ADMIN_ACCOUNT")
                .entityType("User")
                .entityId(savedUser.getId().toString())
                .newValue("{\"role\": \"" + role.name() + "\", \"phone\": \"" + phone + "\"}")
                .build();
        auditLogRepository.save(audit);

        return userService.getUserDtoById(savedUser.getId());
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

        // Save Audit Log
        AuditLog audit = AuditLog.builder()
                .user(superadmin)
                .action(block ? "BLOCK_ACCOUNT" : "UNBLOCK_ACCOUNT")
                .entityType("User")
                .entityId(user.getId().toString())
                .newValue("{\"blockedReason\": \"" + (reason != null ? reason : "") + "\"}")
                .build();
        auditLogRepository.save(audit);
    }

    // TZ 1.4: platform commission must stay within an 8-15% band regardless of what
    // a SuperAdmin types into the settings UI.
    private static final String COMMISSION_SETTING_KEY = "default_commission_pct";
    private static final java.math.BigDecimal COMMISSION_MIN = java.math.BigDecimal.valueOf(8);
    private static final java.math.BigDecimal COMMISSION_MAX = java.math.BigDecimal.valueOf(15);

    @Transactional
    public PlatformSettings updateSetting(String key, String value, UserPrincipal principal) {
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

        // Save Audit Log
        AuditLog audit = AuditLog.builder()
                .user(superadmin)
                .action("UPDATE_SETTING")
                .entityType("PlatformSettings")
                .entityId(saved.getId().toString())
                .oldValue("{\"value\": \"" + oldVal + "\"}")
                .newValue("{\"value\": \"" + value + "\"}")
                .build();
        auditLogRepository.save(audit);

        return saved;
    }

    @Transactional(readOnly = true)
    public Page<AuditLog> getAuditLogs(Pageable pageable) {
        return auditLogRepository.findAll(pageable);
    }

    @Transactional(readOnly = true)
    public Page<PlatformSettings> getSettings(Pageable pageable) {
        return platformSettingsRepository.findAll(pageable);
    }
}
