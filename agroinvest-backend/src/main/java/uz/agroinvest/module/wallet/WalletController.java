package uz.agroinvest.module.wallet;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.common.response.PageResponse;
import uz.agroinvest.module.transaction.dto.TransactionDto;
import uz.agroinvest.module.wallet.dto.WalletDto;
import uz.agroinvest.security.UserPrincipal;

@RestController
@RequestMapping("/api/v1/wallet")
@PreAuthorize("isAuthenticated()")
public class WalletController {

    private final WalletService walletService;

    public WalletController(WalletService walletService) {
        this.walletService = walletService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<WalletDto>> getWallet(@AuthenticationPrincipal UserPrincipal principal) {
        WalletDto dto = walletService.getWalletByUserId(principal.getId());
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @GetMapping("/transactions")
    public ResponseEntity<ApiResponse<PageResponse<TransactionDto>>> getTransactionHistory(
            @AuthenticationPrincipal UserPrincipal principal,
            Pageable pageable
    ) {
        Page<TransactionDto> page = walletService.getTransactionHistory(principal.getId(), pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }
}
