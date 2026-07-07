package uz.agroinvest.module.report.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import uz.agroinvest.common.enums.ReportType;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ReportDto {
    private UUID id;
    private UUID projectId;
    private String projectTitle;
    private UUID submittedById;
    private String submittedByName;
    private ReportType reportType;
    private List<String> mediaUrls;
    private BigDecimal geoLat;
    private BigDecimal geoLng;
    private Float geoAccuracy;
    private String notes;
    private Map<String, Object> metrics;
    private boolean isVerified;
    private String adminComment;
    private LocalDateTime createdAt;
}
