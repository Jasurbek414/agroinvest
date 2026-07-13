package uz.agroinvest.module.news.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

// Shared by create and update, following the SaveBannerRequest pattern.
@Getter
@Setter
public class SaveNewsRequest {

    @NotBlank(message = "Sarlavha kiritilishi shart")
    private String title;

    @NotBlank(message = "Matn kiritilishi shart")
    private String body;

    private String imageUrl;

    private boolean isActive = true;

    private java.time.LocalDateTime startDate;

    private java.time.LocalDateTime endDate;
}
