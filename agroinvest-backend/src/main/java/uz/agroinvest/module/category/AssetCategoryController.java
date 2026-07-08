package uz.agroinvest.module.category;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.module.category.dto.AssetCategoryDto;

import java.util.List;

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
}
