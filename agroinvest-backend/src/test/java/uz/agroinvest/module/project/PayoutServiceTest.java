package uz.agroinvest.module.project;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import uz.agroinvest.common.enums.*;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.investment.entity.Investment;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.transaction.TransactionRepository;
import uz.agroinvest.module.transaction.entity.Transaction;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.module.wallet.WalletRepository;
import uz.agroinvest.module.wallet.entity.Wallet;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class PayoutServiceTest {

    private ProjectRepository projectRepository;
    private InvestmentRepository investmentRepository;
    private WalletRepository walletRepository;
    private TransactionRepository transactionRepository;

    private PayoutService payoutService;

    @BeforeEach
    void setUp() {
        projectRepository = mock(ProjectRepository.class);
        investmentRepository = mock(InvestmentRepository.class);
        walletRepository = mock(WalletRepository.class);
        transactionRepository = mock(TransactionRepository.class);

        payoutService = new PayoutService(
                projectRepository,
                investmentRepository,
                walletRepository,
                transactionRepository
        );
    }

    @Test
    void testDistributePayout_ProfitableCase() {
        UUID projectId = UUID.randomUUID();

        // 1. Setup entities
        User farmer = User.builder().id(UUID.randomUUID()).fullName("Farmer Boy").role(UserRole.FARMER).build();
        User investor = User.builder().id(UUID.randomUUID()).fullName("Investor Rich").role(UserRole.INVESTOR).build();
        User admin = User.builder().id(UUID.randomUUID()).fullName("Admin Staff").role(UserRole.ADMIN).build();

        Project project = Project.builder()
                .id(projectId)
                .title("Dummy Project")
                .targetAmount(BigDecimal.valueOf(10000000)) // 10m UZS
                .status(ProjectStatus.ACTIVE)
                .commissionPct(BigDecimal.valueOf(5)) // 5%
                .investorSharePct(BigDecimal.valueOf(60)) // 60%
                .farmerSharePct(BigDecimal.valueOf(40)) // 40%
                .farmer(farmer)
                .approvedBy(admin)
                .build();

        Investment investment = Investment.builder()
                .id(UUID.randomUUID())
                .project(project)
                .investor(investor)
                .amount(BigDecimal.valueOf(10000000)) // investor invested full 10m
                .sharePct(BigDecimal.valueOf(60)) // 60% share
                .status(InvestmentStatus.CONFIRMED)
                .build();

        Wallet investorWallet = Wallet.builder()
                .user(investor)
                .balance(BigDecimal.ZERO)
                .frozen(BigDecimal.valueOf(10000000))
                .totalEarned(BigDecimal.ZERO)
                .build();

        Wallet farmerWallet = Wallet.builder()
                .user(farmer)
                .balance(BigDecimal.ZERO)
                .frozen(BigDecimal.ZERO)
                .totalEarned(BigDecimal.ZERO)
                .build();

        // 2. Mock repositories behavior
        // PayoutService locks the project/wallet rows for the duration of the payout
        // (see ProjectRepository.findByIdForUpdate / WalletRepository.findByUserIdForUpdate),
        // so those are the methods under test here, not the unlocked finders.
        when(projectRepository.findByIdForUpdate(projectId)).thenReturn(Optional.of(project));
        when(investmentRepository.findByProjectIdAndStatus(projectId, InvestmentStatus.CONFIRMED))
                .thenReturn(Collections.singletonList(investment));
        when(walletRepository.findByUserIdForUpdate(investor.getId())).thenReturn(Optional.of(investorWallet));
        when(walletRepository.findByUserIdForUpdate(farmer.getId())).thenReturn(Optional.of(farmerWallet));

        // 3. Trigger distribution with sales price 15,000,000 UZS
        // Net Profit = 15m - 10m (target) - 750k (5% commission of 15m) = 4,250,000 UZS
        // Investor share of net profit = 4,250,000 * 60% = 2,550,000 UZS
        // Farmer share of net profit = 4,250,000 * 40% = 1,700,000 UZS
        // Total Investor Payout = 10m (initial) + 2.55m = 12,550,000 UZS
        payoutService.distributePayout(projectId, BigDecimal.valueOf(15000000));

        // 4. Verify updates
        assertEquals(BigDecimal.valueOf(12550000.00).stripTrailingZeros(), investorWallet.getBalance().stripTrailingZeros());
        assertEquals(BigDecimal.ZERO.stripTrailingZeros(), investorWallet.getFrozen().stripTrailingZeros());
        assertEquals(BigDecimal.valueOf(2550000.00).stripTrailingZeros(), investorWallet.getTotalEarned().stripTrailingZeros());

        assertEquals(BigDecimal.valueOf(1700000.00).stripTrailingZeros(), farmerWallet.getBalance().stripTrailingZeros());

        assertEquals(ProjectStatus.COMPLETED, project.getStatus());
        assertEquals(BigDecimal.valueOf(15000000), project.getFinalAmount());

        // Verify transaction logs were saved
        verify(transactionRepository, times(3)).save(any(Transaction.class));
    }
}
