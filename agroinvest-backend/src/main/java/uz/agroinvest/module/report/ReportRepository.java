package uz.agroinvest.module.report;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
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
    Optional<Report> findFirstByProjectIdOrderByCreatedAtDesc(UUID projectId);
}
