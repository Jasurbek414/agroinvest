package uz.agroinvest.module.user.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.UserRole;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDto {
    private UUID id;
    private UserRole role;
    private String fullName;
    private String phoneNumber;
    private String email;
    private String avatarUrl;
    private KycStatus kycStatus;
    private String kycRejectedReason;
    private BigDecimal rating;
    private Integer totalProjects;
    private boolean isActive;
    private boolean isBlocked;
    private LocalDateTime createdAt;
}
