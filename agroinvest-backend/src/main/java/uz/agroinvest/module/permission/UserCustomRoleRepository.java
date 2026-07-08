package uz.agroinvest.module.permission;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.permission.entity.UserCustomRole;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserCustomRoleRepository extends JpaRepository<UserCustomRole, UUID> {
    @EntityGraph(attributePaths = {"customRole"})
    List<UserCustomRole> findByUserId(UUID userId);

    Optional<UserCustomRole> findByUserIdAndCustomRoleId(UUID userId, UUID customRoleId);
}
