package uz.agroinvest.module.project;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.common.enums.AnimalType;
import uz.agroinvest.common.enums.AssetType;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.module.project.entity.Project;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProjectRepository extends JpaRepository<Project, UUID>, JpaSpecificationExecutor<Project> {
    // mapToDto reads farmer.fullName for every row; eagerly fetch it here instead of
    // issuing one extra SELECT per project on every paged listing.
    @EntityGraph(attributePaths = {"farmer"})
    Page<Project> findByStatus(ProjectStatus status, Pageable pageable);

    @EntityGraph(attributePaths = {"farmer"})
    List<Project> findByFarmerId(UUID farmerId);

    @EntityGraph(attributePaths = {"farmer"})
    Page<Project> findByFarmerId(UUID farmerId, Pageable pageable);

    @Override
    @EntityGraph(attributePaths = {"farmer"})
    Page<Project> findAll(Pageable pageable);

    // Aggregate counts/sums computed in the DB instead of AdminService pulling every
    // row into memory with findAll().stream().filter()/.map().reduce().
    long countByStatus(ProjectStatus status);

    // Backs the public landing page's "funded projects" stat tile.
    long countByStatusIn(List<ProjectStatus> statuses);

    @Query("select coalesce(sum(p.raisedAmount), 0) from Project p")
    java.math.BigDecimal sumRaisedAmount();

    // Backs both the admin ProjectsTab search/filter and the mobile/web AssetType
    // category filter - status/assetType/q are all optional (null = "any"). Every
    // bind parameter is explicitly cast to string, including the bare "IS NULL"
    // checks - Postgres cannot infer a type for a parameter used only in `? IS NULL`
    // (zero type context) and fails with "could not determine data type of parameter"
    // (or, before the LIKE-clause casts, "function lower(bytea) does not exist") on
    // any request that omits that filter - only ever caught by running against a
    // real Postgres instance, never by a Mockito-backed unit test.
    // p.status <> DRAFT is unconditional (not folded into the :status is-null check
    // below) - this endpoint is shared by public/investor browsing and the admin
    // ProjectsTab, and a farmer's not-yet-submitted draft must never be reachable
    // through either, even by an admin explicitly filtering status=DRAFT.
    @EntityGraph(attributePaths = {"farmer"})
    @Query("select p from Project p where "
            + "p.status <> uz.agroinvest.common.enums.ProjectStatus.DRAFT and "
            + "(cast(:status as string) is null or p.status = :status) and "
            + "(cast(:assetType as string) is null or p.assetType = :assetType) and "
            + "(cast(:animalType as string) is null or p.animalType = :animalType) and "
            + "(cast(:q as string) is null or lower(p.title) like lower(concat('%', cast(:q as string), '%')) or lower(p.region) like lower(concat('%', cast(:q as string), '%')))")
    Page<Project> search(@Param("status") ProjectStatus status, @Param("assetType") AssetType assetType,
                         @Param("animalType") AnimalType animalType, @Param("q") String q, Pageable pageable);

    // Feeds AssetTypeBarChart on the admin dashboard - one row per asset type with its count.
    @Query("select p.assetType as assetType, count(p) as count from Project p group by p.assetType")
    List<AssetTypeCount> countGroupedByAssetType();

    interface AssetTypeCount {
        AssetType getAssetType();
        long getCount();
    }

    // Feeds ProjectStatusPieChart on the admin dashboard - one row per status with its count.
    @Query("select p.status as status, count(p) as count from Project p group by p.status")
    List<StatusCount> countGroupedByStatus();

    interface StatusCount {
        ProjectStatus getStatus();
        long getCount();
    }

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
