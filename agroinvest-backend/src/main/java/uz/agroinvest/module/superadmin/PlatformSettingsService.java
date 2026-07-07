package uz.agroinvest.module.superadmin;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;

/**
 * Typed accessors over the platform_settings key/value table. Previously
 * ProjectService/InvestmentService hardcoded these as Java literals, so changing a
 * value via the SuperAdmin settings UI had no effect on actual behavior - reading
 * live here is what makes that UI real instead of cosmetic.
 */
@Service
public class PlatformSettingsService {

    private final PlatformSettingsRepository repository;

    public PlatformSettingsService(PlatformSettingsRepository repository) {
        this.repository = repository;
    }

    public BigDecimal getCommissionPct() {
        return getDecimal("default_commission_pct", BigDecimal.valueOf(10));
    }

    public BigDecimal getInvestorSharePct() {
        return getDecimal("default_investor_share_pct", BigDecimal.valueOf(70));
    }

    public BigDecimal getFarmerSharePct() {
        return getDecimal("default_farmer_share_pct", BigDecimal.valueOf(30));
    }

    public BigDecimal getMinInvestmentAmount() {
        return getDecimal("min_investment_amount", BigDecimal.valueOf(100000));
    }

    // Bounds within which a farmer may PROPOSE the per-project investor share
    // ("kelishuv asosida" negotiated split); farmer share is always 100 - investor.
    public BigDecimal getMinInvestorSharePct() {
        return getDecimal("min_investor_share_pct", BigDecimal.valueOf(50));
    }

    public BigDecimal getMaxInvestorSharePct() {
        return getDecimal("max_investor_share_pct", BigDecimal.valueOf(90));
    }

    public long getMaxInvestmentCancelHours() {
        return getLong("max_investment_cancel_hours", 24);
    }

    public int getReportFrequencyDays() {
        return (int) getLong("report_frequency_days", 14);
    }

    private BigDecimal getDecimal(String key, BigDecimal fallback) {
        return repository.findBySettingKey(key)
                .map(s -> {
                    try {
                        return new BigDecimal(s.getSettingValue());
                    } catch (NumberFormatException e) {
                        return fallback;
                    }
                })
                .orElse(fallback);
    }

    private long getLong(String key, long fallback) {
        return repository.findBySettingKey(key)
                .map(s -> {
                    try {
                        return Long.parseLong(s.getSettingValue());
                    } catch (NumberFormatException e) {
                        return fallback;
                    }
                })
                .orElse(fallback);
    }
}
