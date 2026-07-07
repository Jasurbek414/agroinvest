package uz.agroinvest.module.withdrawal;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.withdrawal.entity.WithdrawalRequest;

import java.util.List;
import java.util.UUID;

@Repository
public interface WithdrawalRepository extends JpaRepository<WithdrawalRequest, UUID> {
    // mapToDto reads user.fullName for every row; fetch it eagerly to avoid one
    // extra SELECT per withdrawal request on every paged listing.
    @EntityGraph(attributePaths = {"user"})
    List<WithdrawalRequest> findByUserId(UUID userId);

    @EntityGraph(attributePaths = {"user"})
    Page<WithdrawalRequest> findByUserId(UUID userId, Pageable pageable);

    @Override
    @EntityGraph(attributePaths = {"user"})
    Page<WithdrawalRequest> findAll(Pageable pageable);
}
