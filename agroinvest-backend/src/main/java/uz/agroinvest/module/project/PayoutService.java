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
import uz.agroinvest.module.transaction.TransactionRepository;
import uz.agroinvest.module.transaction.entity.Transaction;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.module.wallet.WalletRepository;
import uz.agroinvest.module.wallet.entity.Wallet;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
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
 *     investor_i   = amount_i + round2(investorPool x amount_i / I); last investor
 *                    absorbs the pool's rounding remainder
 *     farmer       = F + E_paid + farmerProfit
 *
 *   Loss (R1 < K): recipients = investors (createdAt order) + farmer last iff F > 0
 *     recovery_k = round2(R1 x capital_k / K); last recipient absorbs remainder
 *     farmer     = recovery + E_paid
 * </pre>
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

    public PayoutService(
            ProjectRepository projectRepository,
            InvestmentRepository investmentRepository,
            WalletRepository walletRepository,
            TransactionRepository transactionRepository,
            UserRepository userRepository,
            ExpenseRepository expenseRepository
    ) {
        this.projectRepository = projectRepository;
        this.investmentRepository = investmentRepository;
        this.walletRepository = walletRepository;
        this.transactionRepository = transactionRepository;
        this.userRepository = userRepository;
        this.expenseRepository = expenseRepository;
    }

    @Transactional
    public void distributePayout(UUID projectId, BigDecimal salePrice) {
        // Lock the project row for the whole distribution: a second concurrent call
        // (double-click, retried request) blocks here until the first commits, then
        // sees status == COMPLETED and is rejected below instead of paying out twice.
        Project project = projectRepository.findByIdForUpdate(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        if (project.getStatus() != ProjectStatus.ACTIVE) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat faol (ACTIVE) loyihalarni yakunlab foydani taqsimlash mumkin");
        }

        if (salePrice.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Sotish narxi noldan yuqori bo'lishi shart");
        }

        // Every expense must be resolved before money is split - a PENDING expense
        // approved after payout could never be reimbursed.
        if (expenseRepository.countByProjectIdAndStatus(projectId, ExpenseStatus.PENDING) > 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Avval barcha kutilayotgan harajatlarni ko'rib chiqing (tasdiqlang yoki rad eting)");
        }

        BigDecimal s = salePrice.setScale(2, RoundingMode.HALF_UP);

        // Deterministic order: the last recipient absorbs rounding remainders.
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

            BigDecimal distributedPool = BigDecimal.ZERO;
            for (int i = 0; i < investments.size(); i++) {
                Investment inv = investments.get(i);
                boolean last = (i == investments.size() - 1);
                BigDecimal profitShare = last
                        ? investorPool.subtract(distributedPool)
                        : round2(investorPool.multiply(inv.getAmount()).divide(investorCapital, 10, RoundingMode.HALF_UP));
                distributedPool = distributedPool.add(profitShare);
                payInvestor(project, inv, inv.getAmount().add(profitShare));
            }
            totalInvestorPayout = investorCapital.add(investorPool);
        } else {
            // ---- 6. LOSS ---- proportional recovery of whatever remains
            farmerProfit = BigDecimal.ZERO;
            boolean farmerIsRecipient = farmerContribution.compareTo(BigDecimal.ZERO) > 0;
            int recipientCount = investments.size() + (farmerIsRecipient ? 1 : 0);

            BigDecimal distributed = BigDecimal.ZERO;
            totalInvestorPayout = BigDecimal.ZERO;
            for (int i = 0; i < investments.size(); i++) {
                Investment inv = investments.get(i);
                boolean last = (i == recipientCount - 1); // only when farmer is NOT a recipient
                BigDecimal recovery = last
                        ? remaining.subtract(distributed)
                        : round2(remaining.multiply(inv.getAmount()).divide(totalCapital, 10, RoundingMode.HALF_UP));
                distributed = distributed.add(recovery);
                totalInvestorPayout = totalInvestorPayout.add(recovery);
                payInvestor(project, inv, recovery);
            }
            // Farmer, appended last, absorbs the remainder of the recovery pool.
            farmerCapitalReturn = farmerIsRecipient ? remaining.subtract(distributed) : BigDecimal.ZERO;
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
}
