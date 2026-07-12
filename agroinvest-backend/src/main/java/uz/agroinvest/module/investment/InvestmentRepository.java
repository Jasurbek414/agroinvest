package uz.agroinvest.module.investment;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.common.enums.InvestmentStatus;
import uz.agroinvest.module.investment.entity.Investment;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface InvestmentRepository extends JpaRepository<Investment, UUID> {
    // mapToDto reads project.title and investor.fullName for every row of a paged
    // list; without this, each page fetches N+1 extra selects (one per lazy assoc).
    @EntityGraph(attributePaths = {"project", "investor"})
    List<Investment> findByInvestorId(UUID investorId);

    @EntityGraph(attributePaths = {"project", "investor"})
    Page<Investment> findByInvestorId(UUID investorId, Pageable pageable);

    @EntityGraph(attributePaths = {"project", "investor"})
    List<Investment> findByProjectId(UUID projectId);

    List<Investment> findByProjectIdAndStatus(UUID projectId, InvestmentStatus status);

    // Payout order must be DETERMINISTIC (createdAt, then id as tiebreaker):
    // the last recipient absorbs the rounding remainder, so ordering decides
    // who gets the extra tiyin - it must not vary between runs.
    List<Investment> findByProjectIdAndStatusOrderByCreatedAtAscIdAsc(UUID projectId, InvestmentStatus status);

    Optional<Investment> findByIdempotencyKey(String idempotencyKey);
    boolean existsByProjectIdAndInvestorId(UUID projectId, UUID investorId);

    // Backs the public landing page's "total invested" stat tile.
    @Query("select coalesce(sum(i.amount), 0) from Investment i where i.status in :statuses")
    BigDecimal sumAmountByStatusIn(@Param("statuses") List<InvestmentStatus> statuses);

    @EntityGraph(attributePaths = {"project", "investor"})
    @Query("select i from Investment i")
    Page<Investment> findAllWithGraph(Pageable pageable);

    @Query("select i from Investment i where " +
           "lower(i.project.title) like lower(concat('%', :q, '%')) or " +
           "lower(i.investor.fullName) like lower(concat('%', :q, '%')) or " +
           "lower(i.investor.phoneNumber) like lower(concat('%', :q, '%'))")
    @EntityGraph(attributePaths = {"project", "investor"})
    Page<Investment> findAllWithSearch(@Param("q") String q, Pageable pageable);

    @EntityGraph(attributePaths = {"project", "investor"})
    Page<Investment> findByStatus(InvestmentStatus status, Pageable pageable);

    @Query("select i from Investment i where " +
           "i.status = :status and (" +
           "lower(i.project.title) like lower(concat('%', :q, '%')) or " +
           "lower(i.investor.fullName) like lower(concat('%', :q, '%')) or " +
           "lower(i.investor.phoneNumber) like lower(concat('%', :q, '%')))")
    @EntityGraph(attributePaths = {"project", "investor"})
    Page<Investment> findByStatusAndSearch(@Param("status") InvestmentStatus status, @Param("q") String q, Pageable pageable);
}
