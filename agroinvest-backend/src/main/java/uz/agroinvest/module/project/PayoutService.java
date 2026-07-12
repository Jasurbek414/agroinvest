package uz.agroinvest.module.project;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.*;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.expense.ExpenseRepository;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.investment.entity.Investment;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.superadmin.AuditLogService;
import uz.agroinvest.module.transaction.TransactionRepository;
import uz.agroinvest.module.transaction.entity.Transaction;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.module.wallet.WalletRepository;
import uz.agroinvest.module.wallet.entity.Wallet;
import uz.agroinvest.security.UserPrincipal;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Sale-revenue distribution waterfall:
 *
 * <pre>
 *   S  = sale price
 *   C  = round2(S x commissionPct / 100)          - platform commission, off the top
 *   P0 = S - C
 *   E_paid = min(E, P0)                            - APPROVED farmer-paid expenses,
 *                                                    reimbursed senior to all capital
 *   R1 = P0 - E_paid
 *   K  = I + F   (I = sum of CONFIRMED investments, F = farmer contribution)
 *
 *   Profit (R1 >= K):  profit = R1 - K
 *     investorPool = round2(profit x investorSharePct / 100)
 *     farmerProfit = profit - investorPool          (exact remainder, not re-rounded)
 *     investor_i   = amount_i + allocateProportionally(investorPool, amounts)_i
 *     farmer       = F + E_paid + farmerProfit
 *
 *   Loss (R1 < K): recipients = investors (createdAt order) + farmer last iff F > 0
 *     recovery = allocateProportionally(R1, capitals) over that recipient list
 *     farmer   = recovery + E_paid
 * </pre>
 *
 * allocateProportionally uses the largest-remainder method (floor every share,
 * then hand out the leftover cents to the largest fractional remainders) so
 * every recipient's share is bounded between its floor and floor+0.01 - unlike
 * a "last recipient absorbs whatever's left" scheme, no recipient can ever go
 * negative from other recipients' rounding accumulating against them.
 *
 * Invariant (asserted): C + E_paid + all payouts == S exactly at scale 2.
 * Legacy projects (F=0, E=0, fully funded) reduce to the original formula.
 */
@Service
public class PayoutService {

    private static final BigDecimal HUNDRED = BigDecimal.valueOf(100);

    private final ProjectRepository projectRepository;
    private final InvestmentRepository investmentRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final ExpenseRepository expenseRepository;
    private final AuditLogService auditLogService;

    public PayoutService(
            ProjectRepository projectRepository,
            InvestmentRepository investmentRepository,
            WalletRepository walletRepository,
            TransactionRepository transactionRepository,
            UserRepository userRepository,
            ExpenseRepository expenseRepository,
            AuditLogService auditLogService
    ) {
        this.projectRepository = projectRepository;
        this.investmentRepository = investmentRepository;
        this.walletRepository = walletRepository;
        this.transactionRepository = transactionRepository;
        this.userRepository = userRepository;
        this.expenseRepository = expenseRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public void distributePayout(UUID projectId, BigDecimal salePrice, UserPrincipal principal) {
        // Lock the project row for the whole distribution: a second concurrent call
        // (double-click, retried request) blocks here until the first commits, then
        // sees status == COMPLETED and is rejected below instead of paying out twice.
        Project project = projectRepository.findByIdForUpdate(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        if (project.getStatus() != ProjectStatus.ACTIVE && project.getStatus() != ProjectStatus.MONITORING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat faol (ACTIVE) yoki kuzatuvdagi (MONITORING) loyihalarni yakunlab foydani taqsimlash mumkin");
        }

        if (project.isFrozen()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Loyiha muzlatilgan, foyda taqsimlash mumkin emas");
        }

        BigDecimal finalPrice = salePrice;
        if (finalPrice == null) {
            finalPrice = project.getProposedSalePrice();
        }

        if (finalPrice == null || finalPrice.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Sotish narxi noldan yuqori bo'lishi shart");
        }

        salePrice = finalPrice;

        // Every expense must be resolved before money is split - a PENDING expense
        // approved after payout could never be reimbursed.
        if (expenseRepository.countByProjectIdAndStatus(projectId, ExpenseStatus.PENDING) > 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Avval barcha kutilayotgan harajatlarni ko'rib chiqing (tasdiqlang yoki rad eting)");
        }

        BigDecimal s = salePrice.setScale(2, RoundingMode.HALF_UP);

        // Deterministic order: ties in allocateProportionally's remainder sort
        // break by this order, so results are reproducible.
        List<Investment> investments =
                investmentRepository.findByProjectIdAndStatusOrderByCreatedAtAscIdAsc(projectId, InvestmentStatus.CONFIRMED);

        BigDecimal investorCapital = investments.stream()
                .map(Investment::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);

        BigDecimal farmerContribution = project.getFarmerContributionValue() == null
                ? BigDecimal.ZERO
                : project.getFarmerContributionValue().setScale(2, RoundingMode.HALF_UP);

        BigDecimal totalCapital = investorCapital.add(farmerContribution);
        if (totalCapital.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Loyihada taqsimlanadigan kapital yo'q (investitsiya ham, fermer hissasi ham 0)");
        }

        // 1-2. Commission off the top
        BigDecimal commission = round2(s.multiply(project.getCommissionPct()).divide(HUNDRED, 10, RoundingMode.HALF_UP));
        BigDecimal afterCommission = s.subtract(commission);

        // 3. Farmer-paid approved expenses, reimbursed senior to capital
        BigDecimal reimbursableExpenses = expenseRepository
                .sumByProjectAndStatusAndPayer(projectId, ExpenseStatus.APPROVED, PayerSource.FARMER)
                .setScale(2, RoundingMode.HALF_UP);
        BigDecimal expensesPaid = reimbursableExpenses.min(afterCommission);

        // 4. What remains for capital + profit
        BigDecimal remaining = afterCommission.subtract(expensesPaid);

        BigDecimal totalInvestorPayout;
        BigDecimal farmerCapitalReturn;
        BigDecimal farmerProfit;

        if (remaining.compareTo(totalCapital) >= 0) {
            // ---- 5. PROFIT ----
            BigDecimal profit = remaining.subtract(totalCapital);
            BigDecimal investorPool = investments.isEmpty()
                    ? BigDecimal.ZERO
                    : round2(profit.multiply(project.getInvestorSharePct()).divide(HUNDRED, 10, RoundingMode.HALF_UP));
            farmerProfit = profit.subtract(investorPool); // exact remainder
            farmerCapitalReturn = farmerContribution;

            List<BigDecimal> investorWeights = investments.stream().map(Investment::getAmount).toList();
            List<BigDecimal> profitShares = allocateProportionally(investorPool, investorWeights);
            for (int i = 0; i < investments.size(); i++) {
                Investment inv = investments.get(i);
                payInvestor(project, inv, inv.getAmount().add(profitShares.get(i)));
            }
            totalInvestorPayout = investorCapital.add(investorPool);
        } else {
            // ---- 6. LOSS ---- proportional recovery of whatever remains, investors
            // and (if contributing) the farmer treated as one recipient list so the
            // largest-remainder allocator never has to special-case who's "last".
            farmerProfit = BigDecimal.ZERO;
            boolean farmerIsRecipient = farmerContribution.compareTo(BigDecimal.ZERO) > 0;

            List<BigDecimal> weights = new ArrayList<>(investments.stream().map(Investment::getAmount).toList());
            if (farmerIsRecipient) {
                weights.add(farmerContribution);
            }
            List<BigDecimal> recoveries = allocateProportionally(remaining, weights);

            totalInvestorPayout = BigDecimal.ZERO;
            for (int i = 0; i < investments.size(); i++) {
                BigDecimal recovery = recoveries.get(i);
                totalInvestorPayout = totalInvestorPayout.add(recovery);
                payInvestor(project, investments.get(i), recovery);
            }
            farmerCapitalReturn = farmerIsRecipient ? recoveries.get(investments.size()) : BigDecimal.ZERO;
        }

        // 7. Farmer credit: capital return + expense reimbursement + profit share,
        //    one wallet credit but separate stage-tagged ledger entries.
        BigDecimal farmerTotal = farmerCapitalReturn.add(expensesPaid).add(farmerProfit);
        if (farmerTotal.compareTo(BigDecimal.ZERO) > 0) {
            Wallet farmerWallet = walletRepository.findByUserIdForUpdate(project.getFarmer().getId())
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Fermer hamyoni topilmadi"));
            farmerWallet.setBalance(farmerWallet.getBalance().add(farmerTotal));
            walletRepository.save(farmerWallet);

            recordFarmerStage(project, farmerCapitalReturn, "CAPITAL_RETURN");
            recordFarmerStage(project, expensesPaid, "EXPENSE_REIMBURSEMENT");
            recordFarmerStage(project, farmerProfit, "PROFIT_SHARE");
        }

        // 8. Platform commission ledger entry (chk_transaction_amount forbids 0)
        if (commission.compareTo(BigDecimal.ZERO) > 0) {
            Transaction commTxn = Transaction.builder()
                    .user(project.getApprovedBy()) // Approved admin registered as transaction agent
                    .project(project)
                    .type(TransactionType.COMMISSION)
                    .amount(commission)
                    .status(TransactionStatus.COMPLETED)
                    .build();
            transactionRepository.save(commTxn);
        }

        // 9. Conservation invariant: every tiyin of S is accounted for.
        BigDecimal accountedFor = commission.add(expensesPaid).add(totalInvestorPayout)
                .add(farmerCapitalReturn).add(farmerProfit);
        if (accountedFor.compareTo(s) != 0) {
            throw new ApiException(ErrorCode.INTERNAL_SERVER_ERROR, HttpStatus.INTERNAL_SERVER_ERROR,
                    "Taqsimot balansi buzildi: " + accountedFor + " != " + s);
        }

        // 10. Complete project
        project.setStatus(ProjectStatus.COMPLETED);
        project.setFinalAmount(s);
        project.setCompletedAt(LocalDateTime.now());
        projectRepository.save(project);

        // TZ F-2.8: farmer's project-history counter, surfaced on their public
        // profile/project cards alongside the review-based rating (see ReviewService).
        User farmer = project.getFarmer();
        farmer.setTotalProjects(farmer.getTotalProjects() == null ? 1 : farmer.getTotalProjects() + 1);
        userRepository.save(farmer);

        User admin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
        auditLogService.log(admin, "DISTRIBUTE_PAYOUT", "Project", project.getId().toString(),
                "{\"status\": \"ACTIVE\"}",
                "{\"status\": \"COMPLETED\", \"salePrice\": \"" + s + "\", \"commission\": \"" + commission + "\"}");
    }

    /**
     * Releases the investor's escrow and credits the payout. Runs even for a
     * zero payout (deep loss) - the frozen escrow must still be released and the
     * investment closed - but a zero-amount ledger row is skipped
     * (chk_transaction_amount requires amount > 0).
     */
    private void payInvestor(Project project, Investment inv, BigDecimal payout) {
        Wallet investorWallet = walletRepository.findByUserIdForUpdate(inv.getInvestor().getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Investor hamyoni topilmadi"));

        investorWallet.setFrozen(investorWallet.getFrozen().subtract(inv.getAmount()));
        investorWallet.setBalance(investorWallet.getBalance().add(payout));
        investorWallet.setTotalEarned(investorWallet.getTotalEarned().add(payout.subtract(inv.getAmount())));
        walletRepository.save(investorWallet);

        inv.setStatus(InvestmentStatus.PAID_OUT);
        inv.setPayoutAmount(payout);
        inv.setPayoutDate(LocalDateTime.now());
        investmentRepository.save(inv);

        if (payout.compareTo(BigDecimal.ZERO) > 0) {
            Transaction txn = Transaction.builder()
                    .user(inv.getInvestor())
                    .project(project)
                    .investment(inv)
                    .type(TransactionType.PAYOUT)
                    .amount(payout)
                    .status(TransactionStatus.COMPLETED)
                    .build();
            transactionRepository.save(txn);
        }
    }

    private void recordFarmerStage(Project project, BigDecimal amount, String stage) {
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            return; // chk_transaction_amount requires amount > 0
        }
        Transaction txn = Transaction.builder()
                .user(project.getFarmer())
                .project(project)
                .type(TransactionType.FARMER_PAYOUT)
                .amount(amount)
                .status(TransactionStatus.COMPLETED)
                .metadata("{\"stage\":\"" + stage + "\"}")
                .build();
        transactionRepository.save(txn);
    }

    private static BigDecimal round2(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Splits {@code pool} across {@code weights} proportionally using the
     * largest-remainder method: each share is floored to 2dp first (so every
     * result is >= 0 and never more than one cent above its exact proportional
     * share), then the leftover cents (pool minus the sum of floors - always a
     * small non-negative number of cents, since flooring never over-allocates)
     * are handed out one at a time to the recipients with the largest fractional
     * remainder, ties broken by list order for determinism.
     *
     * This guarantees sum(result) == pool exactly and every result_i >= 0 -
     * unlike naively rounding each share independently and letting one
     * designated recipient "absorb the remainder", which can go negative when
     * the other recipients' independent roundings accumulate past the pool.
     */
    private static List<BigDecimal> allocateProportionally(BigDecimal pool, List<BigDecimal> weights) {
        int n = weights.size();
        List<BigDecimal> result = new ArrayList<>(n);
        for (int i = 0; i < n; i++) {
            result.add(BigDecimal.ZERO);
        }

        BigDecimal totalWeight = weights.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal targetPool = pool.setScale(2, RoundingMode.HALF_UP);
        if (n == 0 || totalWeight.compareTo(BigDecimal.ZERO) <= 0 || targetPool.compareTo(BigDecimal.ZERO) <= 0) {
            return result;
        }

        BigDecimal[] floors = new BigDecimal[n];
        BigDecimal[] fractions = new BigDecimal[n];
        BigDecimal floorSum = BigDecimal.ZERO;
        for (int i = 0; i < n; i++) {
            BigDecimal exact = targetPool.multiply(weights.get(i)).divide(totalWeight, 10, RoundingMode.HALF_UP);
            floors[i] = exact.setScale(2, RoundingMode.DOWN);
            fractions[i] = exact.subtract(floors[i]);
            floorSum = floorSum.add(floors[i]);
        }

        BigDecimal leftoverCentsDecimal = targetPool.subtract(floorSum).movePointRight(2);
        int leftoverCents = leftoverCentsDecimal.setScale(0, RoundingMode.HALF_UP).intValue();

        List<Integer> order = new ArrayList<>(n);
        for (int i = 0; i < n; i++) {
            order.add(i);
        }
        order.sort(Comparator.<Integer, BigDecimal>comparing(i -> fractions[i]).reversed());

        BigDecimal cent = new BigDecimal("0.01");
        for (int k = 0; k < leftoverCents && k < n; k++) {
            int idx = order.get(k);
            floors[idx] = floors[idx].add(cent);
        }

        for (int i = 0; i < n; i++) {
            result.set(i, floors[i]);
        }
        return result;
    }
}
