package uz.agroinvest.module.superadmin;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.enums.NotificationChannel;
import uz.agroinvest.common.enums.TransactionStatus;
import uz.agroinvest.common.enums.InvestmentStatus;
import uz.agroinvest.common.enums.TransactionType;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.common.response.PageResponse;
import uz.agroinvest.module.superadmin.dto.AuditLogDto;
import uz.agroinvest.module.superadmin.dto.PlatformSettingsDto;
import uz.agroinvest.module.transaction.dto.TransactionDto;
import uz.agroinvest.module.investment.dto.InvestmentDto;
import uz.agroinvest.module.user.dto.UserDto;
import uz.agroinvest.security.UserPrincipal;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Map;
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
            @RequestParam(required = false) Boolean blocked,
            @RequestParam(required = false) String q,
            Pageable pageable
    ) {
        Page<UserDto> page = superAdminService.getAccounts(role, blocked, q, pageable);
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

    @PatchMapping("/accounts/{id}/password")
    public ResponseEntity<ApiResponse<Void>> resetStaffPassword(
            @PathVariable UUID id,
            @RequestParam String newPassword,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        superAdminService.resetStaffPassword(id, newPassword, principal);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PatchMapping("/accounts/{id}/role")
    public ResponseEntity<ApiResponse<UserDto>> changeStaffRole(
            @PathVariable UUID id,
            @RequestParam UserRole role,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        UserDto user = superAdminService.changeStaffRole(id, role, principal);
        return ResponseEntity.ok(ApiResponse.success(user));
    }

    @GetMapping("/overview")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPlatformOverview() {
        return ResponseEntity.ok(ApiResponse.success(superAdminService.getPlatformOverview()));
    }

    @PostMapping("/broadcast")
    public ResponseEntity<ApiResponse<Map<String, Object>>> broadcastNotification(
            @RequestParam String title,
            @RequestParam String message,
            @RequestParam(required = false) UserRole role,
            @RequestParam(required = false) NotificationChannel channel,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        long sent = superAdminService.broadcastNotification(title, message, role, channel, principal);
        return ResponseEntity.ok(ApiResponse.success(Map.of("recipients", sent)));
    }

    @GetMapping("/transactions")
    public ResponseEntity<ApiResponse<PageResponse<TransactionDto>>> getTransactions(
            @RequestParam(required = false) TransactionType type,
            @RequestParam(required = false) TransactionStatus status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            Pageable pageable
    ) {
        Page<TransactionDto> page = superAdminService.getTransactions(type, status, toStartOfDay(from), toEndOfDay(to), pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @GetMapping("/transactions/export")
    public ResponseEntity<byte[]> exportTransactionsCsv(
            @RequestParam(required = false) TransactionType type,
            @RequestParam(required = false) TransactionStatus status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to
    ) {
        String csv = superAdminService.exportTransactionsCsv(type, status, toStartOfDay(from), toEndOfDay(to));
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"transactions.csv\"")
                .contentType(new MediaType("text", "csv", StandardCharsets.UTF_8))
                .body(csv.getBytes(StandardCharsets.UTF_8));
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<ApiResponse<PageResponse<AuditLogDto>>> getAuditLogs(
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            Pageable pageable
    ) {
        Page<AuditLogDto> page = superAdminService.getAuditLogs(action, entityType, toStartOfDay(from), toEndOfDay(to), pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    // Date filters arrive as whole days; expand them to the day's full [00:00, 23:59:59...] range.
    private static LocalDateTime toStartOfDay(LocalDate date) {
        return date != null ? date.atStartOfDay() : null;
    }

    private static LocalDateTime toEndOfDay(LocalDate date) {
        return date != null ? date.atTime(LocalTime.MAX) : null;
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

    @PutMapping("/investments/{id}/contract")
    public ResponseEntity<ApiResponse<Void>> updateInvestmentContractUrl(
            @PathVariable UUID id,
            @RequestParam String contractUrl,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        superAdminService.updateInvestmentContractUrl(id, contractUrl, principal);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @GetMapping("/investments")
    public ResponseEntity<ApiResponse<PageResponse<InvestmentDto>>> getInvestments(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) InvestmentStatus status,
            Pageable pageable
    ) {
        Page<InvestmentDto> page = superAdminService.getInvestments(q, status, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @PostMapping("/accounts/{userId}/topup")
    public ResponseEntity<ApiResponse<Void>> topUpWallet(
            @PathVariable UUID userId,
            @RequestParam java.math.BigDecimal amount,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        superAdminService.topUpWallet(userId, amount, principal);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
