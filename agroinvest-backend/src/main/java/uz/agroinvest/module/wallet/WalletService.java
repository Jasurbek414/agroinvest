package uz.agroinvest.module.wallet;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.transaction.TransactionRepository;
import uz.agroinvest.module.transaction.dto.TransactionDto;
import uz.agroinvest.module.wallet.dto.WalletDto;
import uz.agroinvest.module.wallet.entity.Wallet;

import java.util.UUID;

@Service
public class WalletService {

    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;

    public WalletService(WalletRepository walletRepository, TransactionRepository transactionRepository) {
        this.walletRepository = walletRepository;
        this.transactionRepository = transactionRepository;
    }

    @Transactional(readOnly = true)
    public WalletDto getWalletByUserId(UUID userId) {
        Wallet wallet = walletRepository.findByUserId(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi hamyoni topilmadi"));

        return WalletDto.builder()
                .id(wallet.getId())
                .userId(wallet.getUser().getId())
                .balance(wallet.getBalance())
                .frozen(wallet.getFrozen())
                .totalEarned(wallet.getTotalEarned())
                .totalWithdrawn(wallet.getTotalWithdrawn())
                .updatedAt(wallet.getUpdatedAt())
                .build();
    }

    @Transactional(readOnly = true)
    public Page<TransactionDto> getTransactionHistory(UUID userId, Pageable pageable) {
        return transactionRepository.findByUserId(userId, pageable)
                .map(t -> TransactionDto.builder()
                        .id(t.getId())
                        .userId(t.getUser().getId())
                        .projectId(t.getProject() != null ? t.getProject().getId() : null)
                        .projectTitle(t.getProject() != null ? t.getProject().getTitle() : null)
                        .investmentId(t.getInvestment() != null ? t.getInvestment().getId() : null)
                        .type(t.getType())
                        .amount(t.getAmount())
                        .currency(t.getCurrency())
                        .paymentProvider(t.getPaymentProvider())
                        .externalPaymentId(t.getExternalPaymentId())
                        .status(t.getStatus())
                        .metadata(t.getMetadata())
                        .createdAt(t.getCreatedAt())
                        .build());
    }
}
