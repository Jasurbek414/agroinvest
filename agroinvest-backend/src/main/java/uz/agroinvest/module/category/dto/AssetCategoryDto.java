package uz.agroinvest.module.category.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssetCategoryDto {
    private UUID id;
    private UUID parentId;
    private String code;
    private String nameUz;
    private Integer level;
    private String icon;
    private Integer sortOrder;
    private boolean isActive;
    private List<AssetCategoryDto> children;
}
