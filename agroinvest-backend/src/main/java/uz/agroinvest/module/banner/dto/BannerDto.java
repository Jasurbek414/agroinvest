package uz.agroinvest.module.banner.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import uz.agroinvest.common.enums.BannerAudience;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BannerDto {
    private UUID id;
    private String title;
    private String imageUrl;
    private String linkUrl;
    private BannerAudience targetAudience;
    private boolean isActive;
    private Integer sortOrder;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private LocalDateTime createdAt;
}
