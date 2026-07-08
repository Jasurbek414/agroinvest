package uz.agroinvest.module.category.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "asset_categories")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssetCategory {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private AssetCategory parent;

    @Column(name = "level", nullable = false)
    private Integer level;

    @Column(name = "code", unique = true, nullable = false)
    private String code;

    @Column(name = "name_uz", nullable = false)
    private String nameUz;

    @Column(name = "icon")
    private String icon;

    @Builder.Default
    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder = 0;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
