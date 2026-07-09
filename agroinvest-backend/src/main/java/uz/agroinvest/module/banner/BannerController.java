package uz.agroinvest.module.banner;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.enums.BannerAudience;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.module.banner.dto.BannerDto;
import uz.agroinvest.module.banner.dto.SaveBannerRequest;
import uz.agroinvest.security.UserPrincipal;

import java.util.List;
import java.util.UUID;

@RestController
public class BannerController {

    private final BannerService bannerService;

    public BannerController(BannerService bannerService) {
        this.bannerService = bannerService;
    }

    /** Public feed - mobile "Market" tab and (optionally) the web landing page. */
    @GetMapping("/api/v1/banners")
    public ResponseEntity<ApiResponse<List<BannerDto>>> getActiveBanners(
            @RequestParam(defaultValue = "ALL") BannerAudience audience
    ) {
        return ResponseEntity.ok(ApiResponse.success(bannerService.getActiveBanners(audience)));
    }

    @GetMapping("/api/v1/superadmin/banners")
    @PreAuthorize("@authz.has('banner.manage')")
    public ResponseEntity<ApiResponse<List<BannerDto>>> getAllBanners() {
        return ResponseEntity.ok(ApiResponse.success(bannerService.getAllBanners()));
    }

    @PostMapping("/api/v1/superadmin/banners")
    @PreAuthorize("@authz.has('banner.manage')")
    public ResponseEntity<ApiResponse<BannerDto>> createBanner(
            @Valid @RequestBody SaveBannerRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        BannerDto dto = bannerService.createBanner(request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    @PatchMapping("/api/v1/superadmin/banners/{id}")
    @PreAuthorize("@authz.has('banner.manage')")
    public ResponseEntity<ApiResponse<BannerDto>> updateBanner(@PathVariable UUID id, @Valid @RequestBody SaveBannerRequest request) {
        return ResponseEntity.ok(ApiResponse.success(bannerService.updateBanner(id, request)));
    }

    @DeleteMapping("/api/v1/superadmin/banners/{id}")
    @PreAuthorize("@authz.has('banner.manage')")
    public ResponseEntity<ApiResponse<Void>> deleteBanner(@PathVariable UUID id) {
        bannerService.deleteBanner(id);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
