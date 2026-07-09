package uz.agroinvest.module.banner.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import uz.agroinvest.common.enums.BannerAudience;

import java.time.LocalDateTime;

// Shared by create and update - a banner's shape doesn't change between the two,
// unlike DepositRequest/AssetCategory which have genuinely different create-vs-edit fields.
@Getter
@Setter
public class SaveBannerRequest {

    @NotBlank(message = "Sarlavha kiritilishi shart")
    private String title;

    @NotBlank(message = "Rasm havolasi kiritilishi shart")
    private String imageUrl;

    private String linkUrl;

    @NotNull(message = "Auditoriya tanlanishi shart")
    private BannerAudience targetAudience;

    private boolean isActive = true;

    private Integer sortOrder = 0;

    private LocalDateTime startDate;

    private LocalDateTime endDate;
}
