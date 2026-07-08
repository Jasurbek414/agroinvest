package uz.agroinvest.module.project;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import uz.agroinvest.common.enums.*;
import uz.agroinvest.common.exception.ApiException;
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
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * Exercises the payout waterfall: commission -> farmer-expense reimbursement ->
 * capital return -> negotiated profit split. Every test asserts the conservation
 * invariant (the service itself throws if C + E + payouts != S).
 */
class PayoutServiceTest {

    private ProjectRepository projectRepository;
    private InvestmentRepository investmentRepository;
    private WalletRepository walletRepository;
    private TransactionRepository transactionRepository;
    private UserRepository userRepository;
    private ExpenseRepository expenseRepository;

    private PayoutService payoutService;

    private User farmer;
    private User admin;
    private Wallet farmerWallet;

    @BeforeEach
    void setUp() {
        projectRepository = mock(ProjectRepository.class);
        investmentRepository = mock(InvestmentRepository.class);
        walletRepository = mock(WalletRepository.class);
        transactionRepository = mock(TransactionRepository.class);
        userRepository = mock(UserRepository.class);
        expenseRepository = mock(ExpenseRepository.class);

        payoutService = new PayoutService(
                projectRepository,
                investmentRepository,
                walletRepository,
                transactionRepository,
                userRepository,
                expenseRepository
        );

        farmer = User.builder().id(UUID.randomUUID()).fullName("Farmer Boy").role(UserRole.FARMER).totalProjects(0).build();
        admin = User.builder().id(UUID.randomUUID()).fullName("Admin Staff").role(UserRole.ADMIN).build();
        farmerWallet = wallet(farmer, BigDecimal.ZERO, BigDecimal.ZERO);

        // No expenses unless a test overrides these
        when(expenseRepository.countByProjectIdAndStatus(any(), eq(ExpenseStatus.PENDING))).thenReturn(0L);
        when(expenseRepository.sumByProjectAndStatusAndPayer(any(), eq(ExpenseStatus.APPROVED), eq(PayerSource.FARMER)))
                .thenReturn(BigDecimal.ZERO);
        when(walletRepository.findByUserIdForUpdate(farmer.getId())).thenReturn(Optional.of(farmerWallet));
    }

    private Project project(UUID id, long target, int commissionPct, int investorSharePct, BigDecimal farmerContribution) {
        return Project.builder()
                .id(id)
                .title("Dummy Project")
                .targetAmount(BigDecimal.valueOf(target))
                .status(ProjectStatus.ACTIVE)
                .commissionPct(BigDecimal.valueOf(commissionPct))
                .investorSharePct(BigDecimal.valueOf(investorSharePct))
                .farmerSharePct(BigDecimal.valueOf(100 - investorSharePct))
                .farmerContributionValue(farmerContribution)
                .farmer(farmer)
                .approvedBy(admin)
                .build();
    }

    private Investment investment(Project project, User investor, long amount) {
        return Investment.builder()
                .id(UUID.randomUUID())
                .project(project)
                .investor(investor)
                .amount(BigDecimal.valueOf(amount))
                .status(InvestmentStatus.CONFIRMED)
                .build();
    }

    private Wallet wallet(User user, BigDecimal balance, BigDecimal frozen) {
        return Wallet.builder().user(user).balance(balance).frozen(frozen).totalEarned(BigDecimal.ZERO)
                .totalWithdrawn(BigDecimal.ZERO).build();
    }

    private void mockProject(Project project, List<Investment> investments) {
        when(projectRepository.findByIdForUpdate(project.getId())).thenReturn(Optional.of(project));
        when(investmentRepository.findByProjectIdAndStatusOrderByCreatedAtAscIdAsc(project.getId(), InvestmentStatus.CONFIRMED))
                .thenReturn(investments);
    }

    private static void assertMoney(double expected, BigDecimal actual) {
        assertEquals(0, BigDecimal.valueOf(expected).compareTo(actual),
                "expected " + expected + " but was " + actual);
    }

    // Legacy scenario (no contribution, no expenses) - numbers identical to the
    // pre-waterfall implementation, proving backward compatibility.
    @Test
    void profitableCase_legacyProject() {
        UUID projectId = UUID.randomUUID();
        User investor = User.builder().id(UUID.randomUUID()).fullName("Investor Rich").role(UserRole.INVESTOR).build();
        Project project = project(projectId, 10_000_000, 5, 60, BigDecimal.ZERO);
        Investment inv = investment(project, investor, 10_000_000);
        Wallet investorWallet = wallet(investor, BigDecimal.ZERO, BigDecimal.valueOf(10_000_000));

        mockProject(project, List.of(inv));
        when(walletRepository.findByUserIdForUpdate(investor.getId())).thenReturn(Optional.of(investorWallet));

        // S=15m: C=750k, P0=14.25m, R1=14.25m, K=10m, profit=4.25m
        // pool=2.55m (60%), farmerProfit=1.7m
        payoutService.distributePayout(projectId, BigDecimal.valueOf(15_000_000));

        assertMoney(12_550_000, investorWallet.getBalance());
        assertMoney(0, investorWallet.getFrozen());
        assertMoney(2_550_000, investorWallet.getTotalEarned());
        assertMoney(1_700_000, farmerWallet.getBalance());
        assertEquals(ProjectStatus.COMPLETED, project.getStatus());
        assertEquals(InvestmentStatus.PAID_OUT, inv.getStatus());
        // investor PAYOUT + farmer PROFIT_SHARE + COMMISSION
        verify(transactionRepository, times(3)).save(any(Transaction.class));
    }

    @Test
    void profit_withFarmerContributionAndReimbursableExpenses() {
        UUID projectId = UUID.randomUUID();
        User investor = User.builder().id(UUID.randomUUID()).fullName("Investor Rich").role(UserRole.INVESTOR).build();
        Project project = project(projectId, 10_000_000, 10, 70, BigDecimal.valueOf(2_000_000));
        Investment inv = investment(project, investor, 8_000_000);
        Wallet investorWallet = wallet(investor, BigDecimal.ZERO, BigDecimal.valueOf(8_000_000));

        mockProject(project, List.of(inv));
        when(walletRepository.findByUserIdForUpdate(investor.getId())).thenReturn(Optional.of(investorWallet));
        when(expenseRepository.sumByProjectAndStatusAndPayer(projectId, ExpenseStatus.APPROVED, PayerSource.FARMER))
                .thenReturn(BigDecimal.valueOf(1_000_000));

        // S=20m: C=2m, P0=18m, E_paid=1m, R1=17m, K=8m+2m=10m, profit=7m
        // pool=4.9m (70%), farmerProfit=2.1m
        // investor: 8m + 4.9m = 12.9m ; farmer: 2m + 1m + 2.1m = 5.1m
        payoutService.distributePayout(projectId, BigDecimal.valueOf(20_000_000));

        assertMoney(12_900_000, investorWallet.getBalance());
        assertMoney(4_900_000, investorWallet.getTotalEarned());
        assertMoney(5_100_000, farmerWallet.getBalance());

        // Farmer ledger: three stage-tagged FARMER_PAYOUT rows
        ArgumentCaptor<Transaction> txns = ArgumentCaptor.forClass(Transaction.class);
        verify(transactionRepository, times(5)).save(txns.capture()); // 1 PAYOUT + 3 FARMER_PAYOUT + 1 COMMISSION
        List<Transaction> farmerTxns = txns.getAllValues().stream()
                .filter(t -> t.getType() == TransactionType.FARMER_PAYOUT).toList();
        assertEquals(3, farmerTxns.size());
        assertTrue(farmerTxns.stream().anyMatch(t -> t.getMetadata().contains("CAPITAL_RETURN")
                && t.getAmount().compareTo(BigDecimal.valueOf(2_000_000)) == 0));
        assertTrue(farmerTxns.stream().anyMatch(t -> t.getMetadata().contains("EXPENSE_REIMBURSEMENT")
                && t.getAmount().compareTo(BigDecimal.valueOf(1_000_000)) == 0));
        assertTrue(farmerTxns.stream().anyMatch(t -> t.getMetadata().contains("PROFIT_SHARE")
                && t.getAmount().compareTo(BigDecimal.valueOf(2_100_000)) == 0));
    }

    @Test
    void profit_threeInvestors_lastAbsorbsRoundingRemainder() {
        UUID projectId = UUID.randomUUID();
        User inv1User = User.builder().id(UUID.randomUUID()).fullName("A A").build();
        User inv2User = User.builder().id(UUID.randomUUID()).fullName("B B").build();
        User inv3User = User.builder().id(UUID.randomUUID()).fullName("C C").build();
        Project project = project(projectId, 10_000_000, 10, 70, BigDecimal.ZERO);

        Investment i1 = Investment.builder().id(UUID.randomUUID()).project(project).investor(inv1User)
                .amount(new BigDecimal("3333333.33")).status(InvestmentStatus.CONFIRMED).build();
        Investment i2 = Investment.builder().id(UUID.randomUUID()).project(project).investor(inv2User)
                .amount(new BigDecimal("3333333.33")).status(InvestmentStatus.CONFIRMED).build();
        Investment i3 = Investment.builder().id(UUID.randomUUID()).project(project).investor(inv3User)
                .amount(new BigDecimal("3333333.34")).status(InvestmentStatus.CONFIRMED).build();

        Wallet w1 = wallet(inv1User, BigDecimal.ZERO, i1.getAmount());
        Wallet w2 = wallet(inv2User, BigDecimal.ZERO, i2.getAmount());
        Wallet w3 = wallet(inv3User, BigDecimal.ZERO, i3.getAmount());

        mockProject(project, List.of(i1, i2, i3));
        when(walletRepository.findByUserIdForUpdate(inv1User.getId())).thenReturn(Optional.of(w1));
        when(walletRepository.findByUserIdForUpdate(inv2User.getId())).thenReturn(Optional.of(w2));
        when(walletRepository.findByUserIdForUpdate(inv3User.getId())).thenReturn(Optional.of(w3));

        // S=13m: C=1.3m, R1=11.7m, K=10m, profit=1.7m, pool=1.19m (70%)
        // Largest-remainder allocation: exact shares are 396,666.66627 (i1),
        // 396,666.66627 (i2), 396,666.66746 (i3); flooring all three gives
        // 396,666.66 x3 = 1,189,999.98, leaving 2 leftover cents. i3 has the
        // largest fractional remainder (0.00746) and gets one; the other goes to
        // i1, whose remainder (0.00627) ties i2's but sorts first by list order.
        payoutService.distributePayout(projectId, BigDecimal.valueOf(13_000_000));

        assertMoney(3_333_333.33 + 396_666.67, w1.getBalance());
        assertMoney(3_333_333.33 + 396_666.66, w2.getBalance());
        assertMoney(3_333_333.34 + 396_666.67, w3.getBalance());
        // farmer profit = 1.7m - 1.19m = 510k
        assertMoney(510_000, farmerWallet.getBalance());
        // pool distributed exactly
        assertMoney(1_190_000, w1.getTotalEarned().add(w2.getTotalEarned()).add(w3.getTotalEarned()));
    }

    @Test
    void loss_shallow_proportionalRecoveryIncludingFarmerCapital() {
        UUID projectId = UUID.randomUUID();
        User investor = User.builder().id(UUID.randomUUID()).fullName("Investor Rich").build();
        Project project = project(projectId, 10_000_000, 10, 70, BigDecimal.valueOf(2_000_000));
        Investment inv = investment(project, investor, 8_000_000);
        Wallet investorWallet = wallet(investor, BigDecimal.ZERO, BigDecimal.valueOf(8_000_000));

        mockProject(project, List.of(inv));
        when(walletRepository.findByUserIdForUpdate(investor.getId())).thenReturn(Optional.of(investorWallet));
        when(expenseRepository.sumByProjectAndStatusAndPayer(projectId, ExpenseStatus.APPROVED, PayerSource.FARMER))
                .thenReturn(BigDecimal.valueOf(500_000));

        // S=9m: C=900k, P0=8.1m, E_paid=500k, R1=7.6m < K=10m -> loss
        // investor recovery = 7.6m x 8/10 = 6.08m ; farmer absorbs 1.52m + 500k expenses
        payoutService.distributePayout(projectId, BigDecimal.valueOf(9_000_000));

        assertMoney(6_080_000, investorWallet.getBalance());
        assertMoney(0, investorWallet.getFrozen());
        assertMoney(-1_920_000, investorWallet.getTotalEarned());
        assertMoney(2_020_000, farmerWallet.getBalance());
        assertEquals(InvestmentStatus.PAID_OUT, inv.getStatus());
        assertMoney(6_080_000, inv.getPayoutAmount());
    }

    @Test
    void loss_deeperThanExpenses_investorsGetZeroButEscrowIsReleased() {
        UUID projectId = UUID.randomUUID();
        User investor = User.builder().id(UUID.randomUUID()).fullName("Investor Rich").build();
        Project project = project(projectId, 5_000_000, 10, 70, BigDecimal.ZERO);
        Investment inv = investment(project, investor, 5_000_000);
        Wallet investorWallet = wallet(investor, BigDecimal.ZERO, BigDecimal.valueOf(5_000_000));

        mockProject(project, List.of(inv));
        when(walletRepository.findByUserIdForUpdate(investor.getId())).thenReturn(Optional.of(investorWallet));
        when(expenseRepository.sumByProjectAndStatusAndPayer(projectId, ExpenseStatus.APPROVED, PayerSource.FARMER))
                .thenReturn(BigDecimal.valueOf(2_000_000));

        // S=1m: C=100k, P0=900k, E_paid=min(2m,900k)=900k, R1=0 -> investors get 0
        payoutService.distributePayout(projectId, BigDecimal.valueOf(1_000_000));

        assertMoney(0, investorWallet.getBalance());
        assertMoney(0, investorWallet.getFrozen()); // escrow still released
        assertMoney(-5_000_000, investorWallet.getTotalEarned());
        assertMoney(900_000, farmerWallet.getBalance());
        assertEquals(InvestmentStatus.PAID_OUT, inv.getStatus());
        assertMoney(0, inv.getPayoutAmount());

        // No zero-amount ledger rows: only EXPENSE_REIMBURSEMENT + COMMISSION
        ArgumentCaptor<Transaction> txns = ArgumentCaptor.forClass(Transaction.class);
        verify(transactionRepository, times(2)).save(txns.capture());
        assertTrue(txns.getAllValues().stream().noneMatch(t -> t.getAmount().compareTo(BigDecimal.ZERO) == 0));
    }

    @Test
    void loss_noFarmerContribution_lastInvestorAbsorbsRemainder() {
        UUID projectId = UUID.randomUUID();
        User inv1User = User.builder().id(UUID.randomUUID()).fullName("A A").build();
        User inv2User = User.builder().id(UUID.randomUUID()).fullName("B B").build();
        Project project = project(projectId, 10_000_000, 10, 70, BigDecimal.ZERO);
        Investment i1 = investment(project, inv1User, 3_000_000);
        Investment i2 = investment(project, inv2User, 7_000_000);
        Wallet w1 = wallet(inv1User, BigDecimal.ZERO, i1.getAmount());
        Wallet w2 = wallet(inv2User, BigDecimal.ZERO, i2.getAmount());

        mockProject(project, List.of(i1, i2));
        when(walletRepository.findByUserIdForUpdate(inv1User.getId())).thenReturn(Optional.of(w1));
        when(walletRepository.findByUserIdForUpdate(inv2User.getId())).thenReturn(Optional.of(w2));

        // S=8m: C=800k, R1=7.2m < 10m -> loss. i1: 7.2 x 3/10 = 2.16m ; i2 absorbs 5.04m
        payoutService.distributePayout(projectId, BigDecimal.valueOf(8_000_000));

        assertMoney(2_160_000, w1.getBalance());
        assertMoney(5_040_000, w2.getBalance());
        assertMoney(0, farmerWallet.getBalance()); // no capital, no expenses, no profit
    }

    @Test
    void loss_manyEqualInvestors_noNegativePayoutFromRounding() {
        // Regression test: independently HALF_UP-rounding each non-last recipient's
        // share and letting one designated recipient "absorb the remainder" can
        // drive that recipient's payout negative once enough of the others round
        // up. 10 equal-capital investors + a near-zero recovery pool reproduces
        // it: round2(0.05/10)=round2(0.005)=0.01 for every naive independent
        // share, so 9 of them alone would sum to 0.09 > the 0.05 pool, leaving
        // -0.04 for the 10th under the old scheme. allocateProportionally's
        // largest-remainder method must keep every payout >= 0.
        UUID projectId = UUID.randomUUID();
        Project project = project(projectId, 10_000_000, 0, 70, BigDecimal.ZERO); // 0% commission keeps the math exact

        List<Investment> investments = new ArrayList<>();
        List<Wallet> wallets = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            User investorUser = User.builder().id(UUID.randomUUID()).fullName("Investor " + i).build();
            Investment inv = investment(project, investorUser, 1_000_000);
            Wallet w = wallet(investorUser, BigDecimal.ZERO, inv.getAmount());
            investments.add(inv);
            wallets.add(w);
            when(walletRepository.findByUserIdForUpdate(investorUser.getId())).thenReturn(Optional.of(w));
        }
        mockProject(project, investments);

        // S=0.05, C=0, R1=0.05 << K=10,000,000 -> deep loss, recovery pool = 0.05.
        payoutService.distributePayout(projectId, new BigDecimal("0.05"));

        BigDecimal totalPayout = BigDecimal.ZERO;
        for (Wallet w : wallets) {
            assertTrue(w.getBalance().compareTo(BigDecimal.ZERO) >= 0,
                    "payout must never be negative, was " + w.getBalance());
            totalPayout = totalPayout.add(w.getBalance());
        }
        assertMoney(0.05, totalPayout);
    }

    @Test
    void pendingExpense_blocksPayout() {
        UUID projectId = UUID.randomUUID();
        Project project = project(projectId, 10_000_000, 10, 70, BigDecimal.ZERO);
        when(projectRepository.findByIdForUpdate(projectId)).thenReturn(Optional.of(project));
        when(expenseRepository.countByProjectIdAndStatus(projectId, ExpenseStatus.PENDING)).thenReturn(1L);

        ApiException ex = assertThrows(ApiException.class,
                () -> payoutService.distributePayout(projectId, BigDecimal.valueOf(15_000_000)));
        assertTrue(ex.getMessage().toLowerCase().contains("harajat"));
        assertEquals(ProjectStatus.ACTIVE, project.getStatus());
        verify(transactionRepository, never()).save(any());
    }

    @Test
    void zeroCapital_rejected() {
        UUID projectId = UUID.randomUUID();
        Project project = project(projectId, 10_000_000, 10, 70, BigDecimal.ZERO);
        mockProject(project, List.of());

        assertThrows(ApiException.class,
                () -> payoutService.distributePayout(projectId, BigDecimal.valueOf(15_000_000)));
        verify(transactionRepository, never()).save(any());
    }
}
