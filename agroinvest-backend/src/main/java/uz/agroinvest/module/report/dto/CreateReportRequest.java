package uz.agroinvest.module.report.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import uz.agroinvest.common.enums.ReportType;

import java.math.BigDecimal;
import java.util.List;

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
}
