package uz.agroinvest.module.category.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class CreateAssetCategoryRequest {

    private UUID parentId; // null = root-level category

    @NotBlank(message = "Kod bo'sh bo'lmasligi kerak")
    private String code;

    @NotBlank(message = "Nomi bo'sh bo'lmasligi kerak")
    private String nameUz;

    private String icon;

    private Integer sortOrder = 0;
}
