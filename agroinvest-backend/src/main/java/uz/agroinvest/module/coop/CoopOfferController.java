package uz.agroinvest.module.coop;

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
import uz.agroinvest.module.coop.dto.CoopOfferDto;
import uz.agroinvest.module.coop.dto.SaveCoopOfferRequest;
import uz.agroinvest.security.UserPrincipal;

import java.util.UUID;

@RestController
public class CoopOfferController {

    private final CoopOfferService service;

    public CoopOfferController(CoopOfferService service) {
        this.service = service;
    }

    /** Public feed of approved coop offers (contracts/offers/ideas) */
    @GetMapping("/api/v1/coop-offers")
    public ResponseEntity<ApiResponse<PageResponse<CoopOfferDto>>> getActiveOffers(
            @RequestParam(required = false) String type,
            Pageable pageable
    ) {
        Page<CoopOfferDto> page = service.getActiveOffers(type, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    /** Users post new cooperative/investment proposal */
    @PostMapping("/api/v1/coop-offers")
    public ResponseEntity<ApiResponse<CoopOfferDto>> createOffer(
            @Valid @RequestBody SaveCoopOfferRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        CoopOfferDto dto = service.createOffer(request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    /** SuperAdmin moderating queue */
    @GetMapping("/api/v1/superadmin/coop-offers")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<ApiResponse<PageResponse<CoopOfferDto>>> getAllOffers(Pageable pageable) {
        Page<CoopOfferDto> page = service.getAllOffers(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    /** SuperAdmin moderating status update (APPROVE / REJECT) */
    @PatchMapping("/api/v1/superadmin/coop-offers/{id}/status")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<ApiResponse<CoopOfferDto>> updateOfferStatus(
            @PathVariable UUID id,
            @RequestParam String status
    ) {
        CoopOfferDto dto = service.updateOfferStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    /** SuperAdmin delete offer */
    @DeleteMapping("/api/v1/superadmin/coop-offers/{id}")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteOffer(@PathVariable UUID id) {
        service.deleteOffer(id);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
