package uz.agroinvest.module.vet;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.common.enums.VetInspectionStatus;
import uz.agroinvest.module.vet.entity.VetInspection;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VetInspectionRepository extends JpaRepository<VetInspection, UUID> {

    @EntityGraph(attributePaths = {"uploadedBy"})
    List<VetInspection> findByProjectIdOrderByInspectionDateDesc(UUID projectId);

    @EntityGraph(attributePaths = {"uploadedBy"})
    List<VetInspection> findByProjectIdAndStatusOrderByInspectionDateDesc(UUID projectId, VetInspectionStatus status);

    @EntityGraph(attributePaths = {"project", "uploadedBy"})
    Page<VetInspection> findByStatusOrderByCreatedAtAsc(VetInspectionStatus status, Pageable pageable);

    Optional<VetInspection> findFirstByProjectIdAndStatusOrderByInspectionDateDesc(UUID projectId, VetInspectionStatus status);

    // Farmer dashboard: latest verified check-up across all of the farmer's projects.
    Optional<VetInspection> findFirstByProjectFarmerIdAndStatusOrderByInspectionDateDesc(UUID farmerId, VetInspectionStatus status);

    long countByStatus(VetInspectionStatus status);
}
