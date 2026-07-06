package uz.agroinvest.module.investment.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import uz.agroinvest.common.enums.InvestmentStatus;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.user.entity.User;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "investments")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Investment {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id", nullable = false)
    private Project project;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "investor_id", nullable = false)
    private User investor;

    @Column(name = "amount", nullable = false)
    private BigDecimal amount;

    @Column(name = "share_pct", nullable = false)
    private BigDecimal sharePct;

    @Column(name = "idempotency_key", unique = true)
    private String idempotencyKey;

    @Column(name = "contract_url")
    private String contractUrl;

    @Column(name = "contract_signed_at")
    private LocalDateTime contractSignedAt;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private InvestmentStatus status = InvestmentStatus.RESERVED;

    @Column(name = "payout_amount")
    private BigDecimal payoutAmount;

    @Column(name = "payout_date")
    private LocalDateTime payoutDate;

    @Column(name = "cancelled_at")
    private LocalDateTime cancelledAt;

    @Column(name = "cancel_reason")
    private String cancelReason;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
