package uz.agroinvest.module.report.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import uz.agroinvest.common.enums.ReportType;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Getter
@Setter
public class CreateReportRequest {

    @NotNull(message = "Hisobot turi bo'sh bo'lmasligi kerak")
    private ReportType reportType;

    private List<String> mediaUrls;

    private BigDecimal geoLat;

    private BigDecimal geoLng;

    private Float geoAccuracy;

    private String notes;

    // DAILY log metrics: headcount, deaths, feedKg, avgWeightKg (numbers) +
    // healthNote (string). Whitelisted/validated in ReportService.
    private Map<String, Object> metrics;
}
