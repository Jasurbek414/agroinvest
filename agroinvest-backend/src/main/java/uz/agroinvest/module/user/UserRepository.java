package uz.agroinvest.module.user;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.module.user.entity.User;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByPhoneNumber(String phoneNumber);
    Optional<User> findByEmail(String email);
    boolean existsByPhoneNumber(String phoneNumber);
    boolean existsByEmail(String email);
    List<User> findByRoleIn(List<UserRole> roles);

    // Used by AdminService's dashboard stats instead of findAll().stream().filter().count().
    long countByKycStatusAndRole(KycStatus kycStatus, UserRole role);

    // Backs the public landing page's trust stat tiles.
    long countByRole(UserRole role);

    // SuperAdmin overview tab: blocked-account tile.
    long countByIsBlockedTrue();

    // Backs the admin KYC/Accounts tabs' role filter + name/phone search - both
    // params are optional (null = "any"). Every bind parameter is explicitly cast to
    // string, including the bare "IS NULL" checks - Postgres cannot infer a type for
    // a parameter used only in `? IS NULL` (zero type context) and fails with "could
    // not determine data type of parameter" (or "function lower(bytea) does not
    // exist" for the ones inside lower(...)) on any request that omits that filter.
    @Query("select u from User u where "
            + "(cast(:role as string) is null or u.role = :role) and "
            + "(cast(:q as string) is null or lower(u.fullName) like lower(concat('%', cast(:q as string), '%')) or u.phoneNumber like concat('%', cast(:q as string), '%'))")
    Page<User> search(@Param("role") UserRole role, @Param("q") String q, Pageable pageable);

    // Backs SuperAdminService#getAccounts - restricts the listing to staff roles
    // (admin/moderator/verifier/superadmin) so it's a genuinely separate view from
    // the investor/farmer end-user list, rather than reusing the same generic query.
    @Query("select u from User u where u.role in :roles and "
            + "(cast(:q as string) is null or lower(u.fullName) like lower(concat('%', cast(:q as string), '%')) or u.phoneNumber like concat('%', cast(:q as string), '%'))")
    Page<User> searchByRoles(@Param("roles") List<UserRole> roles, @Param("q") String q, Pageable pageable);
}
