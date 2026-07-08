package uz.agroinvest.module.permission.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "permissions")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Permission {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "code", unique = true, nullable = false)
    private String code;

    @Column(name = "description", nullable = false)
    private String description;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
