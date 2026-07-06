package uz.agroinvest.module.project;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.module.project.entity.Project;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProjectRepository extends JpaRepository<Project, UUID>, JpaSpecificationExecutor<Project> {
    Page<Project> findByStatus(ProjectStatus status, Pageable pageable);
    List<Project> findByFarmerId(UUID farmerId);
    Page<Project> findByFarmerId(UUID farmerId, Pageable pageable);

    /**
     * Locks the project row for the duration of the transaction. Used wherever a
     * status transition or payout depends on the project's current state, so two
     * concurrent calls (e.g. a double-clicked "distribute payout") can't both act on
     * the same pre-transition snapshot.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Project p where p.id = :id")
    Optional<Project> findByIdForUpdate(@Param("id") UUID id);
}
