package uz.agroinvest.module.project;

import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.enums.AnimalType;
import uz.agroinvest.common.enums.AssetType;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.common.response.PageResponse;
import uz.agroinvest.module.project.dto.CreateProjectRequest;
import uz.agroinvest.module.project.dto.ProjectDto;
import uz.agroinvest.module.project.dto.ProjectInvestorDto;
import uz.agroinvest.module.project.dto.UpdateProjectRequest;
import uz.agroinvest.security.UserPrincipal;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/projects")
public class ProjectController {

    private final ProjectService projectService;
    private final PayoutService payoutService;

    public ProjectController(ProjectService projectService, PayoutService payoutService) {
        this.projectService = projectService;
        this.payoutService = payoutService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ProjectDto>>> getProjects(
            @RequestParam(required = false) ProjectStatus status,
            @RequestParam(required = false) AssetType assetType,
            @RequestParam(required = false) AnimalType animalType,
            @RequestParam(required = false) String q,
            Pageable pageable
    ) {
        Page<ProjectDto> page = projectService.getProjects(status, assetType, animalType, q, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProjectDto>> getProjectById(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        ProjectDto dto = projectService.getProjectById(id, principal);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    // Co-investor transparency: masked names + share % (mask applied server-side)
    @GetMapping("/{id}/investors")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<ProjectInvestorDto>>> getProjectInvestors(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(projectService.getProjectInvestors(id)));
    }

    @PostMapping
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<ApiResponse<ProjectDto>> createProject(
            @Valid @RequestBody CreateProjectRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        ProjectDto dto = projectService.createProject(request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    @PatchMapping("/{id}")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<ApiResponse<ProjectDto>> updateProject(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateProjectRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        ProjectDto dto = projectService.updateProject(id, request, principal);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<ApiResponse<Void>> deleteProject(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        projectService.deleteProject(id, principal);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<ProjectDto>> changeStatus(
            @PathVariable UUID id,
            @RequestParam ProjectStatus status,
            @RequestParam(required = false) String rejectionReason,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        ProjectDto dto = projectService.changeStatus(id, status, rejectionReason, principal);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @PostMapping("/{id}/submit")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<ApiResponse<ProjectDto>> submitProject(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        ProjectDto dto = projectService.submitProject(id, principal);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @PatchMapping("/{id}/freeze")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<ApiResponse<ProjectDto>> setFrozen(
            @PathVariable UUID id,
            @RequestParam boolean frozen,
            @RequestParam(required = false) String reason,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        ProjectDto dto = projectService.setFrozen(id, frozen, reason, principal);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @GetMapping("/my")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<ApiResponse<PageResponse<ProjectDto>>> getMyProjects(
            @AuthenticationPrincipal UserPrincipal principal,
            Pageable pageable
    ) {
        Page<ProjectDto> page = projectService.getFarmerProjects(principal.getId(), pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @PostMapping("/{id}/payout")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<ApiResponse<Void>> distributePayout(
            @PathVariable UUID id,
            @RequestParam BigDecimal salePrice,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        payoutService.distributePayout(id, salePrice, principal);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
