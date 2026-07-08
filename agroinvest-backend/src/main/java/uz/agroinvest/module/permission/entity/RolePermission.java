package uz.agroinvest.module.permission.entity;

import jakarta.persistence.*;
import lombok.*;
import uz.agroinvest.common.enums.UserRole;

import java.util.UUID;

/**
 * One (base role -> permission code) grant. Base roles are the 6 fixed
 * UserRole enum values - NOT custom_roles, which have their own join table
 * (CustomRolePermission). A user's effective permission set is the union of
 * their base role's RolePermission rows and every assigned custom role's
 * CustomRolePermission rows (see PermissionService).
 */
@Entity
@Table(name = "role_permissions")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RolePermission {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false)
    private UserRole role;

    @Column(name = "permission_code", nullable = false)
    private String permissionCode;
}
