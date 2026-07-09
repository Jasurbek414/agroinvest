package uz.agroinvest.module.banner;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.common.enums.BannerAudience;
import uz.agroinvest.module.banner.entity.Banner;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface BannerRepository extends JpaRepository<Banner, UUID> {
    List<Banner> findAllByOrderBySortOrderAscCreatedAtDesc();

    // Public feed: active, within its optional date window, and either ALL-audience
    // or matching the caller's specific role.
    @Query("select b from Banner b where b.isActive = true "
            + "and (b.startDate is null or b.startDate <= :now) "
            + "and (b.endDate is null or b.endDate >= :now) "
            + "and (b.targetAudience = uz.agroinvest.common.enums.BannerAudience.ALL or b.targetAudience = :audience) "
            + "order by b.sortOrder asc, b.createdAt desc")
    List<Banner> findActiveForAudience(@Param("audience") BannerAudience audience, @Param("now") LocalDateTime now);
}
