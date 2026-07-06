package uz.agroinvest.module.withdrawal;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.withdrawal.entity.WithdrawalRequest;

import java.util.List;
import java.util.UUID;

@Repository
public interface WithdrawalRepository extends JpaRepository<WithdrawalRequest, UUID> {
    List<WithdrawalRequest> findByUserId(UUID userId);
    Page<WithdrawalRequest> findByUserId(UUID userId, Pageable pageable);
    Page<WithdrawalRequest> findAll(Pageable pageable);
}
