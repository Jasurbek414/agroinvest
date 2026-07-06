package uz.agroinvest.module.wallet;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.wallet.entity.Wallet;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface WalletRepository extends JpaRepository<Wallet, UUID> {
    Optional<Wallet> findByUserId(UUID userId);

    /**
     * Locks the wallet row for the duration of the transaction. Any code path that
     * reads a balance in order to validate-then-debit/credit it MUST use this method
     * instead of findByUserId, otherwise two concurrent requests can both read the
     * same stale balance and both commit (lost update / double-spend).
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select w from Wallet w where w.user.id = :userId")
    Optional<Wallet> findByUserIdForUpdate(@Param("userId") UUID userId);
}
