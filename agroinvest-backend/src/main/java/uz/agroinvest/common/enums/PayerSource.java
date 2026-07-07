package uz.agroinvest.common.enums;

/**
 * Who actually bore an expense. FARMER-paid approved expenses are reimbursed
 * from sale revenue at payout (senior to capital return); INVESTOR_BUDGET ones
 * are transparency-only records of how the raise was spent.
 */
public enum PayerSource {
    INVESTOR_BUDGET,
    FARMER
}
