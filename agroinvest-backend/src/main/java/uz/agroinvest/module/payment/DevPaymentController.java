package uz.agroinvest.module.payment;

import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.security.UserPrincipal;

import java.math.BigDecimal;

/**
 * Dev/staging-only convenience endpoint that fabricates a wallet deposit with no real
 * payment provider involved. {@code @Profile} on the class (not the method - Spring
 * does not honor @Profile on plain @RequestMapping methods) means this whole bean,
 * and therefore this route, does not exist at all unless "dev" or "test" is an active
 * profile - a production deployment (default/prod profile) gets a 404, not a guarded 200.
 */
@RestController
@RequestMapping("/api/v1/payments")
@Profile({"dev", "test"})
public class DevPaymentController {

    private final PaymentService paymentService;

    public DevPaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping("/test-deposit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> testDeposit(
            @RequestParam BigDecimal amount,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        paymentService.testDeposit(principal.getId(), amount);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
