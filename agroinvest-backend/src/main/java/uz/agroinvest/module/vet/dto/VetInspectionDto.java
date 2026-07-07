package uz.agroinvest.module.vet.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import uz.agroinvest.common.enums.VetHealthStatus;
import uz.agroinvest.common.enums.VetInspectionStatus;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VetInspectionDto {
    private UUID id;
    private UUID projectId;
    private String projectTitle;
    private String vetName;
    private String vetLicenseNo;
    private LocalDate inspectionDate;
    private List<String> documentUrls;
    private String conclusion;
    private VetHealthStatus healthStatus;
    private VetInspectionStatus status;
    private String adminComment;
    private LocalDateTime verifiedAt;
    private LocalDateTime createdAt;
}
