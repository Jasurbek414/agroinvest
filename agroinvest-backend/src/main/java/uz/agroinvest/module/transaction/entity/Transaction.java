package uz.agroinvest.module.transaction.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import uz.agroinvest.common.enums.PaymentProvider;
import uz.agroinvest.common.enums.TransactionStatus;
import uz.agroinvest.common.enums.TransactionType;
import uz.agroinvest.module.investment.entity.Investment;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.user.entity.User;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "transactions")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id")
    private Project project;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "investment_id")
    private Investment investment;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    private TransactionType type;

    @Column(name = "amount", nullable = false)
    private BigDecimal amount;

    @Builder.Default
    @Column(name = "currency")
    private String currency = "UZS";

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_provider")
    private PaymentProvider paymentProvider;

    @Column(name = "external_payment_id")
    private String externalPaymentId;

    @Column(name = "idempotency_key", unique = true)
    private String idempotencyKey;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private TransactionStatus status = TransactionStatus.PENDING;

    @Column(name = "metadata", columnDefinition = "jsonb")
    private String metadata; // Stored as raw json string

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
