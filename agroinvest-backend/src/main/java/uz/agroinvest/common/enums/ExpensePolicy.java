package uz.agroinvest.common.enums;

/**
 * Per-project rule for who bears running costs. INVESTOR_BUDGET: costs come out
 * of the raised amount already released to the farmer via milestones (recorded
 * for transparency, never reimbursed at payout). FARMER_REIMBURSED: the farmer
 * pays and approved expenses are repaid from sale revenue before profit split.
 * MIXED: each expense is tagged individually.
 */
public enum ExpensePolicy {
    INVESTOR_BUDGET,
    FARMER_REIMBURSED,
    MIXED
}
