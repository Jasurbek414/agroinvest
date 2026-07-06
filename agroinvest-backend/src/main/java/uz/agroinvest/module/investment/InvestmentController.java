package uz.agroinvest.module.investment;

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
import uz.agroinvest.module.investment.dto.CreateInvestmentRequest;
import uz.agroinvest.module.investment.dto.InvestmentDto;
import uz.agroinvest.module.agreement.AgreementService;
import uz.agroinvest.security.UserPrincipal;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/investments")
@PreAuthorize("hasRole('INVESTOR')")
public class InvestmentController {

    private final InvestmentService investmentService;
    private final AgreementService agreementService;

    public InvestmentController(InvestmentService investmentService, AgreementService agreementService) {
        this.investmentService = investmentService;
        this.agreementService = agreementService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<InvestmentDto>> createInvestment(
            @Valid @RequestBody CreateInvestmentRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        InvestmentDto dto = investmentService.createInvestment(request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<Void>> cancelInvestment(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        investmentService.cancelInvestment(id, principal);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @GetMapping("/my")
    public ResponseEntity<ApiResponse<PageResponse<InvestmentDto>>> getMyInvestments(
            @AuthenticationPrincipal UserPrincipal principal,
            Pageable pageable
    ) {
        Page<InvestmentDto> page = investmentService.getMyInvestments(principal, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    // Restricted to the project's own farmer or staff roles - see InvestmentService.getProjectInvestments.
    @GetMapping("/project/{projectId}")
    @PreAuthorize("hasAnyRole('FARMER', 'ADMIN', 'MODERATOR', 'SUPERADMIN')")
    public ResponseEntity<ApiResponse<java.util.List<InvestmentDto>>> getProjectInvestments(
            @PathVariable UUID projectId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(ApiResponse.success(investmentService.getProjectInvestments(projectId, principal)));
    }

    @GetMapping("/{id}/agreement")
    public ResponseEntity<byte[]> getAgreementPdf(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        byte[] pdfBytes = agreementService.generateInvestmentAgreementPdf(id, principal.getId());
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDispositionFormData("attachment", "investment-agreement-" + id.toString().substring(0, 8) + ".pdf");
        
        return new ResponseEntity<>(pdfBytes, headers, HttpStatus.OK);
    }
}
