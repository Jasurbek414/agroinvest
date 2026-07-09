package uz.agroinvest.module.permission;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.module.permission.dto.CreateCustomRoleRequest;
import uz.agroinvest.module.permission.dto.CreatePermissionRequest;
import uz.agroinvest.module.permission.dto.CustomRoleDto;
import uz.agroinvest.module.permission.dto.PermissionDto;
import uz.agroinvest.security.UserPrincipal;

import java.util.List;
import java.util.UUID;

/**
 * SuperAdmin-only permission/custom-role management - the "SuperAdmin creates
 * roles and permissions dynamically" requirement, implemented as custom roles
 * layered on the fixed 6 base roles (see PLATFORM_ROADMAP.md decision #1).
 * Gated by the legacy hasRole('SUPERADMIN') check for now, consistent with the
 * rest of SuperAdminController - not yet self-hosted on @authz.has(...).
 */
@RestController
@RequestMapping("/api/v1/superadmin/permissions")
@PreAuthorize("hasRole('SUPERADMIN')")
public class PermissionController {

    private final PermissionService permissionService;

    public PermissionController(PermissionService permissionService) {
        this.permissionService = permissionService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<PermissionDto>> createPermission(@Valid @RequestBody CreatePermissionRequest request) {
        PermissionDto permission = permissionService.createPermission(request.getCode(), request.getDescription());
        return new ResponseEntity<>(ApiResponse.success(permission), HttpStatus.CREATED);
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<PermissionDto>>> listPermissions() {
        return ResponseEntity.ok(ApiResponse.success(permissionService.listPermissions()));
    }

    @GetMapping("/roles/{role}")
    public ResponseEntity<ApiResponse<List<String>>> getRolePermissions(@PathVariable UserRole role) {
        return ResponseEntity.ok(ApiResponse.success(permissionService.getRolePermissionCodes(role)));
    }

    @PostMapping("/roles/{role}/grant")
    public ResponseEntity<ApiResponse<Void>> grantToRole(@PathVariable UserRole role, @RequestParam String permissionCode) {
        permissionService.grantToRole(role, permissionCode);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PostMapping("/roles/{role}/revoke")
    public ResponseEntity<ApiResponse<Void>> revokeFromRole(@PathVariable UserRole role, @RequestParam String permissionCode) {
        permissionService.revokeFromRole(role, permissionCode);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PostMapping("/custom-roles")
    public ResponseEntity<ApiResponse<CustomRoleDto>> createCustomRole(
            @Valid @RequestBody CreateCustomRoleRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        CustomRoleDto role = permissionService.createCustomRole(request.getName(), request.getDescription(), principal);
        return new ResponseEntity<>(ApiResponse.success(role), HttpStatus.CREATED);
    }

    @GetMapping("/custom-roles")
    public ResponseEntity<ApiResponse<List<CustomRoleDto>>> listCustomRoles() {
        return ResponseEntity.ok(ApiResponse.success(permissionService.listCustomRoles()));
    }

    @PostMapping("/custom-roles/{customRoleId}/permissions")
    public ResponseEntity<ApiResponse<Void>> addPermissionToCustomRole(
            @PathVariable UUID customRoleId,
            @RequestParam String permissionCode
    ) {
        permissionService.addPermissionToCustomRole(customRoleId, permissionCode);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PostMapping("/custom-roles/{customRoleId}/users/{userId}")
    public ResponseEntity<ApiResponse<Void>> assignCustomRoleToUser(
            @PathVariable UUID customRoleId,
            @PathVariable UUID userId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        permissionService.assignCustomRoleToUser(userId, customRoleId, principal);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @DeleteMapping("/custom-roles/{customRoleId}/users/{userId}")
    public ResponseEntity<ApiResponse<Void>> unassignCustomRoleFromUser(
            @PathVariable UUID customRoleId,
            @PathVariable UUID userId
    ) {
        permissionService.unassignCustomRoleFromUser(userId, customRoleId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
