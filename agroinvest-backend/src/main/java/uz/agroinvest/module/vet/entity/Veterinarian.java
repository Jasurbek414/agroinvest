package uz.agroinvest.module.vet.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "veterinarians")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Veterinarian {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "license_no", nullable = false, unique = true)
    private String licenseNo;

    @Column(name = "phone")
    private String phone;

    @Column(name = "specialty")
    private String specialty;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
