package uz.agroinvest.module.review.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ReviewDto {
    private UUID id;
    private UUID projectId;
    private String projectTitle;
    private UUID investorId;
    private String investorName;
    private UUID farmerId;
    private Integer rating;
    private String comment;
    private LocalDateTime createdAt;
}
