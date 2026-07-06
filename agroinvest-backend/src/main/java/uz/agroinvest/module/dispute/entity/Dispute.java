package uz.agroinvest.module.dispute.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import uz.agroinvest.common.enums.DisputeStatus;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.user.entity.User;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "disputes")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Dispute {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id", nullable = false)
    private Project project;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "filed_by", nullable = false)
    private User filedBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "against_user", nullable = false)
    private User againstUser;

    @Column(name = "dispute_type")
    private String disputeType;

    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    private DisputeStatus status = DisputeStatus.OPEN;

    @Column(name = "resolution", columnDefinition = "TEXT")
    private String resolution;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resolved_by")
    private User resolvedBy;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
