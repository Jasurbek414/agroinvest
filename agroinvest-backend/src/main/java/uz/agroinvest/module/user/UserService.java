package uz.agroinvest.module.user;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import uz.agroinvest.module.notification.NotificationService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.common.util.EncryptionUtil;
import uz.agroinvest.module.superadmin.AuditLogService;
import uz.agroinvest.module.user.dto.KycDetailDto;
import uz.agroinvest.module.user.dto.KycRequest;
import uz.agroinvest.module.user.dto.UpdateProfileRequest;
import uz.agroinvest.module.user.dto.UserDto;
import uz.agroinvest.module.user.entity.User;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final EncryptionUtil encryptionUtil;
    private final ObjectMapper objectMapper;
    private final AuditLogService auditLogService;

    @Autowired
    @Lazy
    private NotificationService notificationService;

    public UserService(UserRepository userRepository, EncryptionUtil encryptionUtil, ObjectMapper objectMapper, AuditLogService auditLogService) {
        this.userRepository = userRepository;
        this.encryptionUtil = encryptionUtil;
        this.objectMapper = objectMapper;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public UserDto getUserDtoById(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));
        return mapToDto(user);
    }

    /**
     * Stores the device's FCM registration token - infrastructure for push
     * notifications (see mobile PushNotificationService). The column has
     * existed on `users` since the initial schema; nothing previously wrote to it.
     */
    @Transactional
    public void updateFcmToken(UUID id, String fcmToken) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));
        user.setFcmToken(fcmToken);
        userRepository.save(user);
    }

    @Transactional
    public UserDto updateProfile(UUID id, UpdateProfileRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));

        user.setFullName(request.getFullName());
        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            if (!request.getEmail().equalsIgnoreCase(user.getEmail()) && userRepository.existsByEmail(request.getEmail())) {
                throw new ApiException(ErrorCode.EMAIL_ALREADY_EXISTS, HttpStatus.BAD_REQUEST);
            }
            user.setEmail(request.getEmail());
        }
        if (request.getAvatarUrl() != null) {
            user.setAvatarUrl(request.getAvatarUrl());
        }

        User saved = userRepository.save(user);
        return mapToDto(saved);
    }

    @Transactional
    public UserDto submitKyc(UUID id, KycRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));

        try {
            // Convert request passport fields to JSON string and encrypt it
            String passportJson = objectMapper.writeValueAsString(request);
            String encryptedPassport = encryptionUtil.encrypt(passportJson);
            user.setPassportData(encryptedPassport);
            user.setKycStatus(KycStatus.PENDING);
            user.setKycRejectedReason(null);
        } catch (Exception e) {
            throw new ApiException(ErrorCode.INTERNAL_SERVER_ERROR, HttpStatus.INTERNAL_SERVER_ERROR, "KYC hujjatlarini tayyorlashda xatolik");
        }

        User saved = userRepository.save(user);

        // Notify admins
        try {
            List<User> admins = userRepository.findByRoleIn(List.of(UserRole.ADMIN, UserRole.SUPERADMIN));
            for (User admin : admins) {
                notificationService.createNotification(
                        admin,
                        "KYC_REQUEST",
                        "Yangi KYC vetting arizasi",
                        saved.getFullName() + " shaxsini tasdiqlash uchun ariza topshirdi.",
                        uz.agroinvest.common.enums.NotificationChannel.IN_APP
                );
            }
        } catch (Exception ex) {
            // ignore
        }

        return mapToDto(saved);
    }

    @Transactional(readOnly = true)
    public UserDto getPublicProfile(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));

        // Only return basic public details
        return UserDto.builder()
                .id(user.getId())
                .role(user.getRole())
                .fullName(user.getFullName())
                .avatarUrl(user.getAvatarUrl())
                .rating(user.getRating())
                .totalProjects(user.getTotalProjects())
                .createdAt(user.getCreatedAt())
                .build();
    }

    /**
     * Decrypts and returns the full KYC document details for an admin reviewer.
     * Unlike WithdrawalService's card-number masking, the passport number/PINFL here
     * are returned unmasked on purpose - this endpoint exists specifically so an
     * ADMIN/MODERATOR/SUPERADMIN can verify those values against the uploaded photos,
     * and masking them would defeat the review itself. Access is restricted to those
     * roles at the controller level, and passportData stays AES-encrypted at rest.
     */
    @Transactional(readOnly = true)
    public KycDetailDto getKycDetail(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));

        if (user.getPassportData() == null) {
            return KycDetailDto.builder().build();
        }

        try {
            String decrypted = encryptionUtil.decrypt(user.getPassportData());
            KycRequest kyc = objectMapper.readValue(decrypted, KycRequest.class);
            return KycDetailDto.builder()
                    .passportNumber(kyc.getPassportNumber())
                    .pinfl(kyc.getPinfl())
                    .birthDate(kyc.getBirthDate())
                    .selfieUrl(kyc.getSelfieUrl())
                    .passportPhotoUrl(kyc.getPassportPhotoUrl())
                    .currentAddress(kyc.getCurrentAddress())
                    .registrationAddress(kyc.getRegistrationAddress())
                    .additionalPhone(kyc.getAdditionalPhone())
                    .fatherName(kyc.getFatherName())
                    .occupation(kyc.getOccupation())
                    .workExperience(kyc.getWorkExperience())
                    .education(kyc.getEducation())
                    .documentUrls(kyc.getDocumentUrls())
                    .build();
        } catch (Exception e) {
            throw new ApiException(ErrorCode.INTERNAL_SERVER_ERROR, HttpStatus.INTERNAL_SERVER_ERROR, "KYC ma'lumotlarini o'qishda xatolik");
        }
    }

    @Transactional(readOnly = true)
    public Page<UserDto> getAllUsers(UserRole role, String q, Pageable pageable) {
        String normalizedQ = (q == null || q.isBlank()) ? null : q.trim();
        return userRepository.search(role, normalizedQ, pageable).map(this::mapToDto);
    }

    @Transactional
    public void blockUser(UUID id, boolean block, String reason, User blockedBy) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));

        user.setBlocked(block);
        if (block) {
            user.setBlockedReason(reason);
            user.setBlockedAt(LocalDateTime.now());
            user.setBlockedBy(blockedBy);
        } else {
            user.setBlockedReason(null);
            user.setBlockedAt(null);
            user.setBlockedBy(null);
        }
        userRepository.save(user);
        auditLogService.log(blockedBy, block ? "BLOCK_USER" : "UNBLOCK_USER", "User", user.getId().toString(),
                null, "{\"reason\": \"" + (reason != null ? reason : "") + "\"}");
    }

    @Transactional
    public UserDto updateKycStatus(UUID id, KycStatus status, String rejectedReason, User verifiedBy) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));

        KycStatus oldStatus = user.getKycStatus();
        user.setKycStatus(status);
        user.setKycVerifiedBy(verifiedBy);
        user.setKycVerifiedAt(LocalDateTime.now());
        if (status == KycStatus.REJECTED) {
            user.setKycRejectedReason(rejectedReason);
        } else {
            user.setKycRejectedReason(null);
        }

        User saved = userRepository.save(user);
        auditLogService.log(verifiedBy, "UPDATE_KYC_STATUS", "User", saved.getId().toString(),
                "{\"kycStatus\": \"" + oldStatus + "\"}", "{\"kycStatus\": \"" + status + "\"}");
        return mapToDto(saved);
    }

    // Public so SuperAdminService#getAccounts can reuse the exact same mapping
    // instead of duplicating it for the staff-accounts listing.
    public UserDto mapToDto(User user) {
        return UserDto.builder()
                .id(user.getId())
                .role(user.getRole())
                .fullName(user.getFullName())
                .phoneNumber(user.getPhoneNumber())
                .email(user.getEmail())
                .avatarUrl(user.getAvatarUrl())
                .kycStatus(user.getKycStatus())
                .kycRejectedReason(user.getKycRejectedReason())
                .rating(user.getRating())
                .totalProjects(user.getTotalProjects())
                .isActive(user.isActive())
                .isBlocked(user.isBlocked())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
