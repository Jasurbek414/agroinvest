package uz.agroinvest.module.wallet.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;
import uz.agroinvest.module.user.entity.User;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "wallets")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Wallet {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", unique = true, nullable = false)
    private User user;

    @Builder.Default
    @Column(name = "balance", nullable = false)
    private BigDecimal balance = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "frozen", nullable = false)
    private BigDecimal frozen = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "total_earned", nullable = false)
    private BigDecimal totalEarned = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "total_withdrawn", nullable = false)
    private BigDecimal totalWithdrawn = BigDecimal.ZERO;

    // Optimistic lock: prevents two concurrent requests from reading the same
    // balance and both committing a stale post-balance (lost-update / double-spend).
    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
