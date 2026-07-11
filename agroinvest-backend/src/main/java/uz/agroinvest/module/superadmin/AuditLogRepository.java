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

    // Audit tab's combined filter (action + entity type + date range) - every optional
    // string param is cast for the "? IS NULL" checks (see UserRepository for why
    // Postgres requires this), and date params use cast(:p as timestamp) likewise.
    @EntityGraph(attributePaths = {"user"})
    @org.springframework.data.jpa.repository.Query("select l from AuditLog l where "
            + "(cast(:action as string) is null or l.action = :action) and "
            + "(cast(:entityType as string) is null or l.entityType = :entityType) and "
            + "(cast(:from as timestamp) is null or l.createdAt >= :from) and "
            + "(cast(:to as timestamp) is null or l.createdAt <= :to)")
    Page<AuditLog> search(
            @org.springframework.data.repository.query.Param("action") String action,
            @org.springframework.data.repository.query.Param("entityType") String entityType,
            @org.springframework.data.repository.query.Param("from") java.time.LocalDateTime from,
            @org.springframework.data.repository.query.Param("to") java.time.LocalDateTime to,
            Pageable pageable
    );
}
