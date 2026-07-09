package uz.agroinvest.module.deposit;

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
import uz.agroinvest.module.deposit.dto.CreateDepositRequest;
import uz.agroinvest.module.deposit.dto.DepositRequestDto;
import uz.agroinvest.security.UserPrincipal;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/deposit-requests")
public class DepositRequestController {

    private final DepositRequestService depositRequestService;

    public DepositRequestController(DepositRequestService depositRequestService) {
        this.depositRequestService = depositRequestService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<DepositRequestDto>> createDepositRequest(
            @Valid @RequestBody CreateDepositRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        DepositRequestDto dto = depositRequestService.createDepositRequest(request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    @GetMapping("/my")
    public ResponseEntity<ApiResponse<PageResponse<DepositRequestDto>>> getMyDepositRequests(
            @AuthenticationPrincipal UserPrincipal principal,
            Pageable pageable
    ) {
        Page<DepositRequestDto> page = depositRequestService.getMyDepositRequests(principal, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @GetMapping
    @PreAuthorize("@authz.has('deposit.review')")
    public ResponseEntity<ApiResponse<PageResponse<DepositRequestDto>>> getAllDepositRequests(Pageable pageable) {
        Page<DepositRequestDto> page = depositRequestService.getAllDepositRequests(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @PatchMapping("/{id}")
    @PreAuthorize("@authz.has('deposit.review')")
    public ResponseEntity<ApiResponse<DepositRequestDto>> approveOrReject(
            @PathVariable UUID id,
            @RequestParam boolean approve,
            @RequestParam(required = false) String adminComment,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        DepositRequestDto dto = depositRequestService.approveOrReject(id, approve, adminComment, principal);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }
}
