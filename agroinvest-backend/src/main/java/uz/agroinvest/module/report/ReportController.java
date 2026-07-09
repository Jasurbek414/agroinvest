package uz.agroinvest.module.report;

import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.common.response.PageResponse;
import uz.agroinvest.module.report.dto.CreateReportRequest;
import uz.agroinvest.module.report.dto.ReportDto;
import uz.agroinvest.security.UserPrincipal;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/reports")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @PostMapping("/project/{projectId}")
    @PreAuthorize("@authz.has('report.submit')")
    public ResponseEntity<ApiResponse<ReportDto>> submitReport(
            @PathVariable UUID projectId,
            @Valid @RequestBody CreateReportRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        ReportDto dto = reportService.submitReport(projectId, request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    @GetMapping("/project/{projectId}")
    public ResponseEntity<ApiResponse<PageResponse<ReportDto>>> getProjectReports(
            @PathVariable UUID projectId,
            Pageable pageable
    ) {
        Page<ReportDto> page = reportService.getProjectReports(projectId, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @PatchMapping("/{id}/verify")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<ReportDto>> verifyReport(
            @PathVariable UUID id,
            @RequestParam boolean verify,
            @RequestParam(required = false) String adminComment,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        ReportDto dto = reportService.verifyReport(id, verify, adminComment, principal);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @GetMapping("/unverified")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<PageResponse<ReportDto>>> getUnverifiedReports(Pageable pageable) {
        Page<ReportDto> page = reportService.getUnverifiedReports(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }
}
