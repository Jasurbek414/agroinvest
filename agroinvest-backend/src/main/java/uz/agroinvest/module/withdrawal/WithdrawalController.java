package uz.agroinvest.module.withdrawal;

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
import uz.agroinvest.module.withdrawal.dto.CreateWithdrawalRequest;
import uz.agroinvest.module.withdrawal.dto.WithdrawalDto;
import uz.agroinvest.security.UserPrincipal;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/withdrawals")
public class WithdrawalController {

    private final WithdrawalService withdrawalService;

    public WithdrawalController(WithdrawalService withdrawalService) {
        this.withdrawalService = withdrawalService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<WithdrawalDto>> requestWithdrawal(
            @Valid @RequestBody CreateWithdrawalRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        WithdrawalDto dto = withdrawalService.requestWithdrawal(request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    @GetMapping("/my")
    public ResponseEntity<ApiResponse<PageResponse<WithdrawalDto>>> getMyWithdrawalRequests(
            @AuthenticationPrincipal UserPrincipal principal,
            Pageable pageable
    ) {
        Page<WithdrawalDto> page = withdrawalService.getMyWithdrawalRequests(principal, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<PageResponse<WithdrawalDto>>> getAllWithdrawalRequests(Pageable pageable) {
        Page<WithdrawalDto> page = withdrawalService.getAllWithdrawalRequests(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @PatchMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<WithdrawalDto>> approveWithdrawal(
            @PathVariable UUID id,
            @RequestParam boolean approve,
            @RequestParam(required = false) String adminComment,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        WithdrawalDto dto = withdrawalService.approveWithdrawal(id, approve, adminComment, principal);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }
}
