package uz.agroinvest.module.category;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.category.entity.AssetCategory;

import java.util.List;
import java.util.UUID;

@Repository
public interface AssetCategoryRepository extends JpaRepository<AssetCategory, UUID> {
    // Whole tree is small (~40 rows) and changes rarely - fetched in one query
    // and assembled into a tree in-memory (AssetCategoryService) rather than
    // recursing level by level.
    @EntityGraph(attributePaths = {"parent"})
    List<AssetCategory> findByIsActiveTrueOrderByLevelAscSortOrderAsc();
}
