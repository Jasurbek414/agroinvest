package uz.agroinvest.module.news;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.news.entity.News;

import java.util.UUID;

@Repository
public interface NewsRepository extends JpaRepository<News, UUID> {
    // Public feed: only published items, newest first.
    Page<News> findByIsActiveTrueOrderByCreatedAtDesc(Pageable pageable);

    // Admin console: everything, including drafts/deactivated.
    Page<News> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
