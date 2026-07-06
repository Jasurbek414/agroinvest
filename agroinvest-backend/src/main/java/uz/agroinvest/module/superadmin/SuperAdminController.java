package uz.agroinvest.module.superadmin;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.common.response.PageResponse;
import uz.agroinvest.module.superadmin.entity.AuditLog;
import uz.agroinvest.module.superadmin.entity.PlatformSettings;
import uz.agroinvest.module.user.dto.UserDto;
import uz.agroinvest.security.UserPrincipal;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/superadmin")
@PreAuthorize("hasRole('SUPERADMIN')")
public class SuperAdminController {

    private final SuperAdminService superAdminService;

    public SuperAdminController(SuperAdminService superAdminService) {
        this.superAdminService = superAdminService;
    }

    @PostMapping("/accounts")
    public ResponseEntity<ApiResponse<UserDto>> createAdminAccount(
            @RequestParam String phone,
            @RequestParam String name,
            @RequestParam String password,
            @RequestParam UserRole role,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        UserDto user = superAdminService.createAdminAccount(phone, name, password, role, principal);
        return new ResponseEntity<>(ApiResponse.success(user), HttpStatus.CREATED);
    }

    @PatchMapping("/accounts/{id}/block")
    public ResponseEntity<ApiResponse<Void>> blockAccount(
            @PathVariable UUID id,
            @RequestParam boolean block,
            @RequestParam(required = false) String reason,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        superAdminService.blockAccount(id, block, reason, principal);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<ApiResponse<PageResponse<AuditLog>>> getAuditLogs(Pageable pageable) {
        Page<AuditLog> page = superAdminService.getAuditLogs(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @GetMapping("/settings")
    public ResponseEntity<ApiResponse<PageResponse<PlatformSettings>>> getSettings(Pageable pageable) {
        Page<PlatformSettings> page = superAdminService.getSettings(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @PatchMapping("/settings")
    public ResponseEntity<ApiResponse<PlatformSettings>> updateSetting(
            @RequestParam String key,
            @RequestParam String value,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        PlatformSettings setting = superAdminService.updateSetting(key, value, principal);
        return ResponseEntity.ok(ApiResponse.success(setting));
    }
}
