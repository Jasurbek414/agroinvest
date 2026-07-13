package uz.agroinvest.module.news;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.news.entity.News;

import java.time.LocalDateTime;
import java.util.UUID;

@Repository
public interface NewsRepository extends JpaRepository<News, UUID> {
    // Public feed: only published items, newest first, and scheduled dates matching
    @Query("select n from News n where n.isActive = true "
            + "and (n.startDate is null or n.startDate <= :now) "
            + "and (n.endDate is null or n.endDate >= :now) "
            + "order by n.createdAt desc")
    Page<News> findActiveNews(@Param("now") LocalDateTime now, Pageable pageable);

    // Admin console: everything, including drafts/deactivated.
    Page<News> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
