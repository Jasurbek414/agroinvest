package uz.agroinvest.module.permission.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import uz.agroinvest.module.user.entity.User;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "user_custom_roles")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserCustomRole {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "custom_role_id", nullable = false)
    private CustomRole customRole;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_by")
    private User assignedBy;

    @CreationTimestamp
    @Column(name = "assigned_at", updatable = false)
    private LocalDateTime assignedAt;
}
