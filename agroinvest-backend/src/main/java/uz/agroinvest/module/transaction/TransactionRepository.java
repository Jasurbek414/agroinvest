package uz.agroinvest.module.transaction;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.common.enums.TransactionStatus;
import uz.agroinvest.module.transaction.entity.Transaction;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, UUID> {
    // WalletService.getTransactionHistory reads project.title for every row; fetch it
    // eagerly to avoid one extra SELECT per transaction on every paged listing.
    @EntityGraph(attributePaths = {"project"})
    List<Transaction> findByUserId(UUID userId);

    @EntityGraph(attributePaths = {"project"})
    Page<Transaction> findByUserId(UUID userId, Pageable pageable);

    Optional<Transaction> findByIdempotencyKey(String idempotencyKey);
    Optional<Transaction> findByExternalPaymentIdAndPaymentProvider(String externalPaymentId, uz.agroinvest.common.enums.PaymentProvider paymentProvider);

    /**
     * Atomic compare-and-swap on transaction status. Payment provider webhooks (Click
     * Complete, Payme Perform/Cancel) can arrive twice concurrently for the same
     * transaction; a plain read-then-write would let both requests observe the old
     * status and both credit the wallet. Callers must branch on the returned row
     * count: 0 means another request already won the race and no wallet mutation
     * should happen here.
     */
    @Modifying(clearAutomatically = true)
    @Query("update Transaction t set t.status = :newStatus where t.id = :id and t.status = :expectedStatus")
    int compareAndSetStatus(@Param("id") UUID id, @Param("expectedStatus") TransactionStatus expectedStatus, @Param("newStatus") TransactionStatus newStatus);
}
