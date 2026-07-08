package uz.agroinvest.module.permission;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.permission.entity.CustomRolePermission;

import java.util.List;
import java.util.UUID;

@Repository
public interface CustomRolePermissionRepository extends JpaRepository<CustomRolePermission, UUID> {
    List<CustomRolePermission> findByCustomRoleId(UUID customRoleId);
    boolean existsByCustomRoleIdAndPermissionCode(UUID customRoleId, String permissionCode);

    // All permission codes granted by every custom role currently assigned to
    // a user - the join PermissionService needs to compute the custom-role
    // half of a user's effective permission set in one query.
    @Query("select distinct crp.permissionCode from CustomRolePermission crp "
            + "where crp.customRole.id in (select ucr.customRole.id from UserCustomRole ucr where ucr.user.id = :userId and ucr.customRole.active = true)")
    List<String> findPermissionCodesForUser(@Param("userId") UUID userId);
}
