package uz.agroinvest.module.coop.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "coop_offers")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CoopOffer {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(name = "type", nullable = false)
    private String type; // CONTRACT_SALE, INVESTOR_OFFER, BUSINESS_PLAN

    @Column(name = "amount", nullable = false, precision = 19, scale = 2)
    private BigDecimal amount;

    @Builder.Default
    @Column(name = "status", nullable = false)
    private String status = "PENDING"; // PENDING, APPROVED, REJECTED

    @Column(name = "creator_id", nullable = false)
    private UUID creatorId;

    @Column(name = "creator_name", nullable = false)
    private String creatorName;

    @Column(name = "contact_phone", nullable = false)
    private String contactPhone;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
