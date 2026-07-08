package uz.agroinvest.module.permission.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "custom_role_permissions")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomRolePermission {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "custom_role_id", nullable = false)
    private CustomRole customRole;

    @Column(name = "permission_code", nullable = false)
    private String permissionCode;
}
