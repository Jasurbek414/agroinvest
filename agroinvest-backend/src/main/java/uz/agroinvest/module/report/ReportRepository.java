package uz.agroinvest.module.report;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.common.enums.ReportType;
import uz.agroinvest.module.report.entity.Report;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ReportRepository extends JpaRepository<Report, UUID> {
    List<Report> findByProjectId(UUID projectId);
    Page<Report> findByProjectId(UUID projectId, Pageable pageable);
    List<Report> findByIsVerifiedFalse();
    Page<Report> findByIsVerifiedFalse(Pageable pageable);

    // SuperAdmin overview tab: unverified-reports queue counter.
    long countByIsVerifiedFalse();
    Optional<Report> findFirstByProjectIdOrderByCreatedAtDesc(UUID projectId);

    // Daily-log duty check (dashboard + scheduler): latest DAILY log per project.
    Optional<Report> findFirstByProjectIdAndReportTypeOrderByCreatedAtDesc(UUID projectId, ReportType reportType);

    // Admin/SuperAdmin reports console: the FULL report history (verified and
    // unverified alike), optionally narrowed by type/verification state.
    @EntityGraph(attributePaths = {"project", "submittedBy"})
    @Query("select r from Report r where (cast(:reportType as string) is null or r.reportType = :reportType) " +
            "and (:verified is null or r.isVerified = :verified)")
    Page<Report> findAllFiltered(@Param("reportType") ReportType reportType,
                                 @Param("verified") Boolean verified,
                                 Pageable pageable);

    // Investor dashboard: latest activity across all projects they invested in.
    @EntityGraph(attributePaths = {"project", "submittedBy"})
    List<Report> findTop5ByProjectIdInOrderByCreatedAtDesc(List<UUID> projectIds);

    // Farmer dashboard: one query for "latest report per project" across every
    // project the farmer owns, instead of one findFirstByProjectId... call per
    // project in a loop. Ordered by project then recency, so the caller only
    // needs to keep the first row seen per project id (see DashboardService).
    @Query("select r from Report r where r.project.id in :projectIds order by r.project.id, r.createdAt desc")
    List<Report> findByProjectIdInOrderByProjectIdAndCreatedAtDesc(@Param("projectIds") List<UUID> projectIds);
}
