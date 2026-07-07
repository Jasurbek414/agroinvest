package uz.agroinvest.module.vet;

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
import uz.agroinvest.module.vet.dto.CreateVetInspectionRequest;
import uz.agroinvest.module.vet.dto.VerifyVetInspectionRequest;
import uz.agroinvest.module.vet.dto.VetInspectionDto;
import uz.agroinvest.security.UserPrincipal;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/vet-inspections")
public class VetInspectionController {

    private final VetInspectionService vetInspectionService;

    public VetInspectionController(VetInspectionService vetInspectionService) {
        this.vetInspectionService = vetInspectionService;
    }

    @PostMapping("/project/{projectId}")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<ApiResponse<VetInspectionDto>> submitInspection(
            @PathVariable UUID projectId,
            @Valid @RequestBody CreateVetInspectionRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        VetInspectionDto dto = vetInspectionService.submitInspection(projectId, request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    // Public: anonymous callers see only VERIFIED inspections (trust signal);
    // the owner and staff also see PENDING/REJECTED. See SecurityConfig permitAll.
    @GetMapping("/project/{projectId}")
    public ResponseEntity<ApiResponse<List<VetInspectionDto>>> getProjectInspections(
            @PathVariable UUID projectId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(ApiResponse.success(vetInspectionService.getProjectInspections(projectId, principal)));
    }

    @GetMapping("/pending")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<PageResponse<VetInspectionDto>>> getPendingInspections(Pageable pageable) {
        Page<VetInspectionDto> page = vetInspectionService.getPendingInspections(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @PatchMapping("/{id}/verify")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<VetInspectionDto>> verifyInspection(
            @PathVariable UUID id,
            @Valid @RequestBody VerifyVetInspectionRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        VetInspectionDto dto = vetInspectionService.verifyInspection(id, request.getApprove(), request.getComment(), principal);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }
}
