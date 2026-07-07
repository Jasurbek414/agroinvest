package uz.agroinvest.module.user.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.UserRole;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "users")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false)
    private UserRole role;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "phone_number", unique = true, nullable = false)
    private String phoneNumber;

    @Column(name = "email", unique = true)
    private String email;

    @Column(name = "password_hash")
    private String passwordHash;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "passport_data", columnDefinition = "TEXT")
    private String passportData; // Encrypted AES-256 JSON

    @Enumerated(EnumType.STRING)
    @Column(name = "kyc_status")
    private KycStatus kycStatus;

    @Column(name = "kyc_rejected_reason")
    private String kycRejectedReason;

    @Column(name = "kyc_verified_at")
    private LocalDateTime kycVerifiedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "kyc_verified_by")
    private User kycVerifiedBy;

    @Column(name = "rating")
    private BigDecimal rating;

    @Column(name = "total_projects")
    private Integer totalProjects;

    @Builder.Default
    @Column(name = "is_active")
    private boolean isActive = true;

    @Builder.Default
    @Column(name = "is_blocked")
    private boolean isBlocked = false;

    @Column(name = "blocked_reason")
    private String blockedReason;

    @Column(name = "blocked_at")
    private LocalDateTime blockedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "blocked_by")
    private User blockedBy;

    @Column(name = "telegram_chat_id")
    private Long telegramChatId;

    @Column(name = "fcm_token")
    private String fcmToken;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
