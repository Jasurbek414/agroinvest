package uz.agroinvest.module.category;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.category.dto.AssetCategoryDto;
import uz.agroinvest.module.category.dto.CreateAssetCategoryRequest;
import uz.agroinvest.module.category.dto.UpdateAssetCategoryRequest;
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
     * Public tree (PLATFORM_ROADMAP.md Phase 0.4) - active categories only.
     * Assembles the ~40-row tree from a single flat query instead of one query per level.
     */
    @Transactional(readOnly = true)
    public List<AssetCategoryDto> getCategoryTree() {
        return buildTree(assetCategoryRepository.findByIsActiveTrueOrderByLevelAscSortOrderAsc());
    }

    /** SuperAdmin management tree (Phase 2) - includes inactive (soft-deleted) categories. */
    @Transactional(readOnly = true)
    public List<AssetCategoryDto> getAllCategoriesTree() {
        return buildTree(assetCategoryRepository.findAllByOrderByLevelAscSortOrderAsc());
    }

    private List<AssetCategoryDto> buildTree(List<AssetCategory> all) {
        Map<UUID, AssetCategoryDto> dtoById = new LinkedHashMap<>();
        Map<UUID, List<AssetCategoryDto>> childrenByParentId = new LinkedHashMap<>();
        List<AssetCategoryDto> roots = new ArrayList<>();

        for (AssetCategory category : all) {
            AssetCategoryDto dto = AssetCategoryDto.builder()
                    .id(category.getId())
                    .parentId(category.getParent() != null ? category.getParent().getId() : null)
                    .code(category.getCode())
                    .nameUz(category.getNameUz())
                    .level(category.getLevel())
                    .icon(category.getIcon())
                    .sortOrder(category.getSortOrder())
                    .isActive(category.isActive())
                    .children(new ArrayList<>())
                    .build();
            dtoById.put(category.getId(), dto);

            UUID parentId = dto.getParentId();
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

    /**
     * Create-only for structure (parentId/code never change after creation): `level`
     * is denormalized (V18), so re-parenting would require recursively recomputing
     * `level` for a whole subtree - out of scope for this MVP management screen.
     */
    @Transactional
    public AssetCategoryDto createCategory(CreateAssetCategoryRequest request) {
        if (assetCategoryRepository.existsByCode(request.getCode())) {
            throw new ApiException(ErrorCode.CONFLICT, HttpStatus.CONFLICT, "Bu kod bilan kategoriya allaqachon mavjud: " + request.getCode());
        }

        AssetCategory parent = null;
        int level = 0;
        if (request.getParentId() != null) {
            parent = assetCategoryRepository.findById(request.getParentId())
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Ota kategoriya topilmadi"));
            level = parent.getLevel() + 1;
        }

        AssetCategory saved = assetCategoryRepository.save(AssetCategory.builder()
                .parent(parent)
                .level(level)
                .code(request.getCode())
                .nameUz(request.getNameUz())
                .icon(request.getIcon())
                .sortOrder(request.getSortOrder() != null ? request.getSortOrder() : 0)
                .isActive(true)
                .build());

        return AssetCategoryDto.builder()
                .id(saved.getId())
                .parentId(request.getParentId())
                .code(saved.getCode())
                .nameUz(saved.getNameUz())
                .level(saved.getLevel())
                .icon(saved.getIcon())
                .sortOrder(saved.getSortOrder())
                .isActive(saved.isActive())
                .children(List.of())
                .build();
    }

    /** Display-field-only edit (name/icon/sort order) + soft-activate/deactivate. */
    @Transactional
    public void updateCategory(UUID id, UpdateAssetCategoryRequest request) {
        AssetCategory category = assetCategoryRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Kategoriya topilmadi"));

        category.setNameUz(request.getNameUz());
        if (request.getIcon() != null) category.setIcon(request.getIcon());
        if (request.getSortOrder() != null) category.setSortOrder(request.getSortOrder());
        category.setActive(request.isActive());
        assetCategoryRepository.save(category);
    }
}
