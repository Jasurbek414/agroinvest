package uz.agroinvest.module.permission;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.permission.entity.Permission;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PermissionRepository extends JpaRepository<Permission, UUID> {
    boolean existsByCode(String code);
    Optional<Permission> findByCode(String code);
}
