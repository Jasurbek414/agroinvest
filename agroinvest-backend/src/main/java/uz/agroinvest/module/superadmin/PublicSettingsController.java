package uz.agroinvest.module.superadmin;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import uz.agroinvest.common.response.ApiResponse;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Public (unauthenticated) subset of platform settings that clients need BEFORE
 * a user is logged in or while building forms: profit-split slider bounds,
 * minimum investment, commission. Never expose the full settings table here.
 */
@RestController
@RequestMapping("/api/v1/settings")
public class PublicSettingsController {

    private final PlatformSettingsService platformSettingsService;

    public PublicSettingsController(PlatformSettingsService platformSettingsService) {
        this.platformSettingsService = platformSettingsService;
    }

    @GetMapping("/public")
    public ResponseEntity<ApiResponse<Map<String, BigDecimal>>> getPublicSettings() {
        Map<String, BigDecimal> settings = new LinkedHashMap<>();
        settings.put("minInvestorSharePct", platformSettingsService.getMinInvestorSharePct());
        settings.put("maxInvestorSharePct", platformSettingsService.getMaxInvestorSharePct());
        settings.put("defaultInvestorSharePct", platformSettingsService.getInvestorSharePct());
        settings.put("minInvestmentAmount", platformSettingsService.getMinInvestmentAmount());
        settings.put("commissionPct", platformSettingsService.getCommissionPct());
        return ResponseEntity.ok(ApiResponse.success(settings));
    }
}
