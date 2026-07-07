package uz.agroinvest.module.expense;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.common.enums.ExpenseStatus;
import uz.agroinvest.common.enums.PayerSource;
import uz.agroinvest.module.expense.entity.Expense;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Repository
public interface ExpenseRepository extends JpaRepository<Expense, UUID> {

    @EntityGraph(attributePaths = {"submittedBy"})
    List<Expense> findByProjectIdOrderByExpenseDateDescCreatedAtDesc(UUID projectId);

    @EntityGraph(attributePaths = {"project", "submittedBy"})
    Page<Expense> findByStatusOrderByCreatedAtAsc(ExpenseStatus status, Pageable pageable);

    long countByProjectIdAndStatus(UUID projectId, ExpenseStatus status);

    long countByStatus(ExpenseStatus status);

    // Farmer dashboard: how many of MY submitted expenses still await review.
    long countBySubmittedByIdAndStatus(UUID submittedById, ExpenseStatus status);

    // Payout waterfall input: total APPROVED farmer-paid expenses of a project.
    @Query("select coalesce(sum(e.amount), 0) from Expense e "
            + "where e.project.id = :projectId and e.status = :status and e.payerSource = :payerSource")
    BigDecimal sumByProjectAndStatusAndPayer(@Param("projectId") UUID projectId,
                                             @Param("status") ExpenseStatus status,
                                             @Param("payerSource") PayerSource payerSource);

    @Query("select coalesce(sum(e.amount), 0) from Expense e "
            + "where e.project.id = :projectId and e.status = :status")
    BigDecimal sumByProjectAndStatus(@Param("projectId") UUID projectId, @Param("status") ExpenseStatus status);
}
