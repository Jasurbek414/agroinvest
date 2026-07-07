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

    // Backs the admin KYC/Accounts tabs' role filter + name/phone search - both
    // params are optional (null = "any").
    @Query("select u from User u where "
            + "(:role is null or u.role = :role) and "
            + "(:q is null or lower(u.fullName) like lower(concat('%', :q, '%')) or u.phoneNumber like concat('%', :q, '%'))")
    Page<User> search(@Param("role") UserRole role, @Param("q") String q, Pageable pageable);

    // Backs SuperAdminService#getAccounts - restricts the listing to staff roles
    // (admin/moderator/verifier/superadmin) so it's a genuinely separate view from
    // the investor/farmer end-user list, rather than reusing the same generic query.
    @Query("select u from User u where u.role in :roles and "
            + "(:q is null or lower(u.fullName) like lower(concat('%', :q, '%')) or u.phoneNumber like concat('%', :q, '%'))")
    Page<User> searchByRoles(@Param("roles") List<UserRole> roles, @Param("q") String q, Pageable pageable);
}
