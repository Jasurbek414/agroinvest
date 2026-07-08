package uz.agroinvest.module.category;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.module.category.dto.AssetCategoryDto;
import uz.agroinvest.module.category.entity.AssetCategory;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class AssetCategoryService {

    private final AssetCategoryRepository assetCategoryRepository;

    public AssetCategoryService(AssetCategoryRepository assetCategoryRepository) {
        this.assetCategoryRepository = assetCategoryRepository;
    }

    /**
     * Read-only foundation for now (PLATFORM_ROADMAP.md Phase 0.4) - nothing
     * writes category_id yet (Phase 5) and there's no management CRUD yet
     * (Phase 2's "Kategoriya boshqaruv UI"). Assembles the ~40-row tree from a
     * single flat query instead of one query per level.
     */
    @Transactional(readOnly = true)
    public List<AssetCategoryDto> getCategoryTree() {
        List<AssetCategory> all = assetCategoryRepository.findByIsActiveTrueOrderByLevelAscSortOrderAsc();

        Map<UUID, AssetCategoryDto> dtoById = new LinkedHashMap<>();
        Map<UUID, List<AssetCategoryDto>> childrenByParentId = new LinkedHashMap<>();
        List<AssetCategoryDto> roots = new ArrayList<>();

        for (AssetCategory category : all) {
            AssetCategoryDto dto = AssetCategoryDto.builder()
                    .id(category.getId())
                    .code(category.getCode())
                    .nameUz(category.getNameUz())
                    .level(category.getLevel())
                    .icon(category.getIcon())
                    .children(new ArrayList<>())
                    .build();
            dtoById.put(category.getId(), dto);

            UUID parentId = category.getParent() != null ? category.getParent().getId() : null;
            if (parentId == null) {
                roots.add(dto);
            } else {
                childrenByParentId.computeIfAbsent(parentId, k -> new ArrayList<>()).add(dto);
            }
        }

        for (Map.Entry<UUID, AssetCategoryDto> entry : dtoById.entrySet()) {
            entry.getValue().setChildren(childrenByParentId.getOrDefault(entry.getKey(), List.of()));
        }

        return roots;
    }
}
