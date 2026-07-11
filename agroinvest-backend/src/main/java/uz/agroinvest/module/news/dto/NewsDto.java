package uz.agroinvest.module.news.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Builder
public class NewsDto {
    private UUID id;
    private String title;
    private String body;
    private String imageUrl;
    private boolean isActive;
    private LocalDateTime createdAt;
}
