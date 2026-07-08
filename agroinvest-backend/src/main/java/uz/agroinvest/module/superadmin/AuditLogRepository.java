package uz.agroinvest.module.superadmin;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.superadmin.entity.AuditLog;

import java.util.UUID;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, UUID> {
    // open-in-view is disabled - user must be fetched eagerly here, or the
    // service-layer DTO mapper hits a LazyInitializationException (or a silent
    // N+1) once the transaction/Hibernate session has already closed.
    @EntityGraph(attributePaths = {"user"})
    @Override
    Page<AuditLog> findAll(Pageable pageable);

    @EntityGraph(attributePaths = {"user"})
    Page<AuditLog> findByUserId(UUID userId, Pageable pageable);

    @EntityGraph(attributePaths = {"user"})
    Page<AuditLog> findByAction(String action, Pageable pageable);
}
