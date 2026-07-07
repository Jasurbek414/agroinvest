package uz.agroinvest.module.review;

import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.common.response.PageResponse;
import uz.agroinvest.module.review.dto.CreateReviewRequest;
import uz.agroinvest.module.review.dto.ReviewDto;
import uz.agroinvest.security.UserPrincipal;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/reviews")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ReviewDto>> createReview(
            @Valid @RequestBody CreateReviewRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        ReviewDto dto = reviewService.createReview(request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    // Public: a farmer's reviews are shown on their projects' public detail pages,
    // same visibility level as the project listing itself.
    @GetMapping("/farmer/{farmerId}")
    public ResponseEntity<ApiResponse<PageResponse<ReviewDto>>> getFarmerReviews(
            @PathVariable UUID farmerId,
            Pageable pageable
    ) {
        Page<ReviewDto> page = reviewService.getFarmerReviews(farmerId, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }
}
