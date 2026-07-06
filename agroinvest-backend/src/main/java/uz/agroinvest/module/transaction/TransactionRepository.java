package uz.agroinvest.module.transaction;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.transaction.entity.Transaction;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, UUID> {
    List<Transaction> findByUserId(UUID userId);
    Page<Transaction> findByUserId(UUID userId, Pageable pageable);
    Optional<Transaction> findByIdempotencyKey(String idempotencyKey);
    Optional<Transaction> findByExternalPaymentIdAndPaymentProvider(String externalPaymentId, uz.agroinvest.common.enums.PaymentProvider paymentProvider);
}
