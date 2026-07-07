package uz.agroinvest.module.project;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.*;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
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

@Service
public class PayoutService {

    private final ProjectRepository projectRepository;
    private final InvestmentRepository investmentRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;

    public PayoutService(
            ProjectRepository projectRepository,
            InvestmentRepository investmentRepository,
            WalletRepository walletRepository,
            TransactionRepository transactionRepository,
            UserRepository userRepository
    ) {
        this.projectRepository = projectRepository;
        this.investmentRepository = investmentRepository;
        this.walletRepository = walletRepository;
        this.transactionRepository = transactionRepository;
        this.userRepository = userRepository;
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

        List<Investment> investments = investmentRepository.findByProjectIdAndStatus(projectId, InvestmentStatus.CONFIRMED);

        // 1. Calculate Platform Commission
        BigDecimal platformCommission = salePrice
                .multiply(project.getCommissionPct())
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);

        // 2. Calculate Net Profit
        BigDecimal initialFunding = project.getTargetAmount();
        BigDecimal netProfit = salePrice.subtract(initialFunding).subtract(platformCommission);

        boolean isProfit = netProfit.compareTo(BigDecimal.ZERO) > 0;

        // 3. Distribute to each investor
        for (Investment inv : investments) {
            BigDecimal investorPayout;
            if (isProfit) {
                // Profit distribution: initial investment + (netProfit * sharePct / 100)
                BigDecimal profitShare = netProfit
                        .multiply(inv.getSharePct())
                        .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
                investorPayout = inv.getAmount().add(profitShare);
            } else {
                // Loss distribution: final sales pool shared proportionally to initial contributions
                investorPayout = salePrice
                        .subtract(platformCommission)
                        .multiply(inv.getAmount())
                        .divide(initialFunding, 2, RoundingMode.HALF_UP);
            }

            // Update Investor Wallet
            Wallet investorWallet = walletRepository.findByUserIdForUpdate(inv.getInvestor().getId())
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

            // Unfreeze and add payout
            investorWallet.setFrozen(investorWallet.getFrozen().subtract(inv.getAmount()));
            investorWallet.setBalance(investorWallet.getBalance().add(investorPayout));
            investorWallet.setTotalEarned(investorWallet.getTotalEarned().add(investorPayout.subtract(inv.getAmount())));
            walletRepository.save(investorWallet);

            // Update Investment status
            inv.setStatus(InvestmentStatus.PAID_OUT);
            inv.setPayoutAmount(investorPayout);
            inv.setPayoutDate(LocalDateTime.now());
            investmentRepository.save(inv);

            // Record transaction
            Transaction txn = Transaction.builder()
                    .user(inv.getInvestor())
                    .project(project)
                    .investment(inv)
                    .type(TransactionType.PAYOUT)
                    .amount(investorPayout)
                    .status(TransactionStatus.COMPLETED)
                    .build();
            transactionRepository.save(txn);
        }

        // 4. Distribute to farmer if there was profit
        if (isProfit) {
            BigDecimal farmerProfitShare = netProfit
                    .multiply(project.getFarmerSharePct())
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);

            Wallet farmerWallet = walletRepository.findByUserIdForUpdate(project.getFarmer().getId())
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

            farmerWallet.setBalance(farmerWallet.getBalance().add(farmerProfitShare));
            walletRepository.save(farmerWallet);

            // Record farmer profit transaction
            Transaction farmerTxn = Transaction.builder()
                    .user(project.getFarmer())
                    .project(project)
                    .type(TransactionType.FARMER_PAYOUT)
                    .amount(farmerProfitShare)
                    .status(TransactionStatus.COMPLETED)
                    .build();
            transactionRepository.save(farmerTxn);
        }

        // 5. Record Platform Commission Revenue
        Transaction commTxn = Transaction.builder()
                .user(project.getApprovedBy()) // Approved admin registered as transaction agent
                .project(project)
                .type(TransactionType.COMMISSION)
                .amount(platformCommission)
                .status(TransactionStatus.COMPLETED)
                .build();
        transactionRepository.save(commTxn);

        // 6. Complete Project status
        project.setStatus(ProjectStatus.COMPLETED);
        project.setFinalAmount(salePrice);
        project.setCompletedAt(LocalDateTime.now());
        projectRepository.save(project);

        // TZ F-2.8: farmer's project-history counter, surfaced on their public
        // profile/project cards alongside the review-based rating (see ReviewService).
        User farmer = project.getFarmer();
        farmer.setTotalProjects(farmer.getTotalProjects() == null ? 1 : farmer.getTotalProjects() + 1);
        userRepository.save(farmer);
    }
}
