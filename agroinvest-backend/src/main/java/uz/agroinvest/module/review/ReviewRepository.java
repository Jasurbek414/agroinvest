package uz.agroinvest.module.review;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.review.entity.Review;

import java.util.UUID;

@Repository
public interface ReviewRepository extends JpaRepository<Review, UUID> {

    boolean existsByInvestmentId(UUID investmentId);

    @EntityGraph(attributePaths = {"investor", "project"})
    Page<Review> findByFarmerIdOrderByCreatedAtDesc(UUID farmerId, Pageable pageable);

    @Query("select avg(r.rating) from Review r where r.farmer.id = :farmerId")
    Double findAverageRatingByFarmerId(@Param("farmerId") UUID farmerId);
}
