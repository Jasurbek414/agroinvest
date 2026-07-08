package uz.agroinvest.module.permission;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.module.permission.entity.RolePermission;

import java.util.List;
import java.util.UUID;

@Repository
public interface RolePermissionRepository extends JpaRepository<RolePermission, UUID> {
    List<RolePermission> findByRole(UserRole role);
    boolean existsByRoleAndPermissionCode(UserRole role, String permissionCode);
    void deleteByRoleAndPermissionCode(UserRole role, String permissionCode);
}
