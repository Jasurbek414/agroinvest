package uz.agroinvest.module.user;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.common.util.EncryptionUtil;
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

    public UserService(UserRepository userRepository, EncryptionUtil encryptionUtil, ObjectMapper objectMapper) {
        this.userRepository = userRepository;
        this.encryptionUtil = encryptionUtil;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public UserDto getUserDtoById(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));
        return mapToDto(user);
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

    @Transactional(readOnly = true)
    public Page<UserDto> getAllUsers(Pageable pageable) {
        return userRepository.findAll(pageable).map(this::mapToDto);
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
    }

    @Transactional
    public UserDto updateKycStatus(UUID id, KycStatus status, String rejectedReason, User verifiedBy) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));

        user.setKycStatus(status);
        user.setKycVerifiedBy(verifiedBy);
        user.setKycVerifiedAt(LocalDateTime.now());
        if (status == KycStatus.REJECTED) {
            user.setKycRejectedReason(rejectedReason);
        } else {
            user.setKycRejectedReason(null);
        }

        User saved = userRepository.save(user);
        return mapToDto(saved);
    }

    private UserDto mapToDto(User user) {
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
