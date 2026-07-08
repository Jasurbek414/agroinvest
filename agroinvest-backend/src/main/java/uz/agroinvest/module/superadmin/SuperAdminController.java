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
import uz.agroinvest.module.superadmin.dto.AuditLogDto;
import uz.agroinvest.module.superadmin.dto.PlatformSettingsDto;
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

    @GetMapping("/accounts")
    public ResponseEntity<ApiResponse<PageResponse<UserDto>>> getAccounts(
            @RequestParam(required = false) UserRole role,
            @RequestParam(required = false) String q,
            Pageable pageable
    ) {
        Page<UserDto> page = superAdminService.getAccounts(role, q, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
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
    public ResponseEntity<ApiResponse<PageResponse<AuditLogDto>>> getAuditLogs(
            @RequestParam(required = false) String action,
            Pageable pageable
    ) {
        Page<AuditLogDto> page = superAdminService.getAuditLogs(action, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @GetMapping("/settings")
    public ResponseEntity<ApiResponse<PageResponse<PlatformSettingsDto>>> getSettings(Pageable pageable) {
        Page<PlatformSettingsDto> page = superAdminService.getSettings(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @PatchMapping("/settings")
    public ResponseEntity<ApiResponse<PlatformSettingsDto>> updateSetting(
            @RequestParam String key,
            @RequestParam String value,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        PlatformSettingsDto setting = superAdminService.updateSetting(key, value, principal);
        return ResponseEntity.ok(ApiResponse.success(setting));
    }

    @PatchMapping("/settings/shares")
    public ResponseEntity<ApiResponse<Void>> updateInvestorFarmerShares(
            @RequestParam("investorSharePct") java.math.BigDecimal investorSharePct,
            @RequestParam("farmerSharePct") java.math.BigDecimal farmerSharePct,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        superAdminService.updateInvestorFarmerShares(investorSharePct, farmerSharePct, principal);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
