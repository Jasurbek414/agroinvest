package uz.agroinvest.module.category;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.module.category.dto.AssetCategoryDto;
import uz.agroinvest.module.category.dto.CreateAssetCategoryRequest;
import uz.agroinvest.module.category.dto.UpdateAssetCategoryRequest;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/categories")
public class AssetCategoryController {

    private final AssetCategoryService assetCategoryService;

    public AssetCategoryController(AssetCategoryService assetCategoryService) {
        this.assetCategoryService = assetCategoryService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<AssetCategoryDto>>> getCategoryTree() {
        return ResponseEntity.ok(ApiResponse.success(assetCategoryService.getCategoryTree()));
    }

    @GetMapping("/all")
    @PreAuthorize("@authz.has('category.manage')")
    public ResponseEntity<ApiResponse<List<AssetCategoryDto>>> getAllCategoriesTree() {
        return ResponseEntity.ok(ApiResponse.success(assetCategoryService.getAllCategoriesTree()));
    }

    @PostMapping
    @PreAuthorize("@authz.has('category.manage')")
    public ResponseEntity<ApiResponse<AssetCategoryDto>> createCategory(@Valid @RequestBody CreateAssetCategoryRequest request) {
        AssetCategoryDto dto = assetCategoryService.createCategory(request);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    @PatchMapping("/{id}")
    @PreAuthorize("@authz.has('category.manage')")
    public ResponseEntity<ApiResponse<Void>> updateCategory(@PathVariable UUID id, @Valid @RequestBody UpdateAssetCategoryRequest request) {
        assetCategoryService.updateCategory(id, request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
