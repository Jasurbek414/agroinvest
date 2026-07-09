package uz.agroinvest.module.deposit;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.deposit.entity.DepositRequest;

import java.util.UUID;

@Repository
public interface DepositRequestRepository extends JpaRepository<DepositRequest, UUID> {
    @EntityGraph(attributePaths = {"user"})
    Page<DepositRequest> findByUserId(UUID userId, Pageable pageable);

    @Override
    @EntityGraph(attributePaths = {"user"})
    Page<DepositRequest> findAll(Pageable pageable);
}
