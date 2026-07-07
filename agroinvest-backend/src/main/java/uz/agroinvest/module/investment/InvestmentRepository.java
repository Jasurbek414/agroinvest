package uz.agroinvest.module.investment;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.common.enums.InvestmentStatus;
import uz.agroinvest.module.investment.entity.Investment;

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
    Optional<Investment> findByIdempotencyKey(String idempotencyKey);
    boolean existsByProjectIdAndInvestorId(UUID projectId, UUID investorId);
}
