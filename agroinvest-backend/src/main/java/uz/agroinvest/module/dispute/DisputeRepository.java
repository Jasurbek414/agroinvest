package uz.agroinvest.module.dispute;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.dispute.entity.Dispute;

import java.util.List;
import java.util.UUID;

@Repository
public interface DisputeRepository extends JpaRepository<Dispute, UUID> {
    // mapToDto reads project/filedBy/againstUser (3 lazy associations) for every row;
    // fetch them eagerly to avoid 3 extra SELECTs per dispute on every listing.
    @EntityGraph(attributePaths = {"project", "filedBy", "againstUser"})
    List<Dispute> findByProjectId(UUID projectId);

    @Override
    @EntityGraph(attributePaths = {"project", "filedBy", "againstUser"})
    Page<Dispute> findAll(Pageable pageable);

    @EntityGraph(attributePaths = {"project", "filedBy", "againstUser"})
    Page<Dispute> findByFiledById(UUID filedById, Pageable pageable);
}
