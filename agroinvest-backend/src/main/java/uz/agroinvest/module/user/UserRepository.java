package uz.agroinvest.module.user;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
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
}
