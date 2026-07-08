package uz.agroinvest.module.permission.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import uz.agroinvest.module.user.entity.User;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A SuperAdmin-defined named role (e.g. "Katta Moderator") bundling arbitrary
 * permission codes, assignable to specific users on top of their fixed base
 * role (UserRole). Does NOT replace or touch users.role.
 */
@Entity
@Table(name = "custom_roles")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomRole {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "name", unique = true, nullable = false)
    private String name;

    @Column(name = "description")
    private String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private User createdBy;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
