package uz.agroinvest.module.category.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateAssetCategoryRequest {

    @NotBlank(message = "Nomi bo'sh bo'lmasligi kerak")
    private String nameUz;

    private String icon;

    private Integer sortOrder;

    private boolean isActive = true;
}
