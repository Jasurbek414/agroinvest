package uz.agroinvest.module.banner.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import uz.agroinvest.common.enums.BannerAudience;
import uz.agroinvest.module.user.entity.User;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "banners")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Banner {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "image_url", nullable = false)
    private String imageUrl;

    @Column(name = "link_url")
    private String linkUrl;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "target_audience", nullable = false)
    private BannerAudience targetAudience = BannerAudience.ALL;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Builder.Default
    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder = 0;

    @Column(name = "start_date")
    private LocalDateTime startDate;

    @Column(name = "end_date")
    private LocalDateTime endDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private User createdBy;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
