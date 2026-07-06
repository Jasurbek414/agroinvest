package uz.agroinvest.module.dispute;

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
import uz.agroinvest.module.dispute.dto.CreateDisputeRequest;
import uz.agroinvest.module.dispute.dto.DisputeDto;
import uz.agroinvest.security.UserPrincipal;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/disputes")
public class DisputeController {

    private final DisputeService disputeService;

    public DisputeController(DisputeService disputeService) {
        this.disputeService = disputeService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<DisputeDto>> fileDispute(
            @Valid @RequestBody CreateDisputeRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        DisputeDto dto = disputeService.fileDispute(request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<PageResponse<DisputeDto>>> getAllDisputes(Pageable pageable) {
        Page<DisputeDto> page = disputeService.getAllDisputes(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @GetMapping("/my")
    public ResponseEntity<ApiResponse<PageResponse<DisputeDto>>> getMyDisputes(
            @AuthenticationPrincipal UserPrincipal principal,
            Pageable pageable
    ) {
        Page<DisputeDto> page = disputeService.getMyDisputes(principal.getId(), pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @PatchMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<DisputeDto>> resolveDispute(
            @PathVariable UUID id,
            @RequestParam String resolution,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        DisputeDto dto = disputeService.resolveDispute(id, resolution, principal);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }
}
