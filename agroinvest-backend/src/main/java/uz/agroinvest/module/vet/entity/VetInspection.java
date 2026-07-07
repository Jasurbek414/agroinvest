package uz.agroinvest.module.vet.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import uz.agroinvest.common.enums.VetHealthStatus;
import uz.agroinvest.common.enums.VetInspectionStatus;
import uz.agroinvest.common.util.JsonListConverter;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.user.entity.User;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * A veterinary check-up document uploaded by the farmer (PDF/photo of the
 * vet's conclusion) and verified by staff. VERIFIED inspections are public
 * trust signals on the project page.
 */
@Entity
@Table(name = "vet_inspections")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VetInspection {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id", nullable = false)
    private Project project;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_by", nullable = false)
    private User uploadedBy;

    @Column(name = "vet_name", nullable = false)
    private String vetName;

    @Column(name = "vet_license_no")
    private String vetLicenseNo;

    @Column(name = "inspection_date", nullable = false)
    private LocalDate inspectionDate;

    @Convert(converter = JsonListConverter.class)
    @Column(name = "document_urls", columnDefinition = "jsonb")
    private List<String> documentUrls;

    @Column(name = "conclusion", columnDefinition = "TEXT")
    private String conclusion;

    @Enumerated(EnumType.STRING)
    @Column(name = "health_status", nullable = false)
    private VetHealthStatus healthStatus;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private VetInspectionStatus status = VetInspectionStatus.PENDING;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "verified_by")
    private User verifiedBy;

    @Column(name = "verified_at")
    private LocalDateTime verifiedAt;

    @Column(name = "admin_comment")
    private String adminComment;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
