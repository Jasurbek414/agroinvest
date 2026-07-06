package uz.agroinvest.module.report.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import uz.agroinvest.common.enums.ReportType;
import uz.agroinvest.common.util.JsonListConverter;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.user.entity.User;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "reports")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Report {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id", nullable = false)
    private Project project;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "submitted_by", nullable = false)
    private User submittedBy;

    @Enumerated(EnumType.STRING)
    @Column(name = "report_type", nullable = false)
    private ReportType reportType;

    @Convert(converter = JsonListConverter.class)
    @Column(name = "media_urls", columnDefinition = "jsonb")
    private List<String> mediaUrls;

    @Column(name = "geo_lat")
    private BigDecimal geoLat;

    @Column(name = "geo_lng")
    private BigDecimal geoLng;

    @Column(name = "geo_accuracy")
    private Float geoAccuracy;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "is_verified")
    private boolean isVerified = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "verified_by")
    private User verifiedBy;

    @Column(name = "verified_at")
    private LocalDateTime verifiedAt;

    @Column(name = "admin_comment", columnDefinition = "TEXT")
    private String adminComment;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
