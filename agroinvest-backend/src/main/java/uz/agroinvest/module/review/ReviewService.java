package uz.agroinvest.module.review;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.InvestmentStatus;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.investment.entity.Investment;
import uz.agroinvest.module.review.dto.CreateReviewRequest;
import uz.agroinvest.module.review.dto.ReviewDto;
import uz.agroinvest.module.review.entity.Review;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.UUID;

@Service
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final InvestmentRepository investmentRepository;
    private final UserRepository userRepository;

    public ReviewService(
            ReviewRepository reviewRepository,
            InvestmentRepository investmentRepository,
            UserRepository userRepository
    ) {
        this.reviewRepository = reviewRepository;
        this.investmentRepository = investmentRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public ReviewDto createReview(CreateReviewRequest request, UserPrincipal principal) {
        Investment investment = investmentRepository.findById(request.getInvestmentId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Investitsiya topilmadi"));

        if (!investment.getInvestor().getId().equals(principal.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Faqat o'z investitsiyangiz uchun sharh qoldirishingiz mumkin");
        }

        // PAID_OUT is set by PayoutService only once the project's payout has actually
        // been distributed - reviewing before that would let an investor rate a farmer
        // before the outcome (profit/loss) of the project is even known.
        if (investment.getStatus() != InvestmentStatus.PAID_OUT) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Sharh faqat yakunlanib to'lovi qilingan investitsiya uchun qoldiriladi");
        }

        if (reviewRepository.existsByInvestmentId(investment.getId())) {
            throw new ApiException(ErrorCode.CONFLICT, HttpStatus.CONFLICT, "Bu investitsiya uchun sharh allaqachon qoldirilgan");
        }

        User farmer = investment.getProject().getFarmer();

        Review review = Review.builder()
                .project(investment.getProject())
                .investment(investment)
                .investor(investment.getInvestor())
                .farmer(farmer)
                .rating(request.getRating())
                .comment(request.getComment())
                .build();

        Review saved = reviewRepository.save(review);
        recalculateFarmerRating(farmer.getId());
        return mapToDto(saved);
    }

    private void recalculateFarmerRating(UUID farmerId) {
        Double avg = reviewRepository.findAverageRatingByFarmerId(farmerId);
        User farmer = userRepository.findById(farmerId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
        farmer.setRating(avg == null ? BigDecimal.ZERO : BigDecimal.valueOf(avg).setScale(2, RoundingMode.HALF_UP));
        userRepository.save(farmer);
    }

    @Transactional(readOnly = true)
    public Page<ReviewDto> getFarmerReviews(UUID farmerId, Pageable pageable) {
        return reviewRepository.findByFarmerIdOrderByCreatedAtDesc(farmerId, pageable).map(this::mapToDto);
    }

    private ReviewDto mapToDto(Review review) {
        return new ReviewDto(
                review.getId(),
                review.getProject().getId(),
                review.getProject().getTitle(),
                review.getInvestor().getId(),
                review.getInvestor().getFullName(),
                review.getFarmer().getId(),
                review.getRating(),
                review.getComment(),
                review.getCreatedAt()
        );
    }
}
