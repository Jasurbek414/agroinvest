package uz.agroinvest.module.withdrawal;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.TransactionStatus;
import uz.agroinvest.common.enums.TransactionType;
import uz.agroinvest.common.enums.WithdrawalStatus;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.common.util.EncryptionUtil;
import uz.agroinvest.module.superadmin.AuditLogService;
import uz.agroinvest.module.transaction.TransactionRepository;
import uz.agroinvest.module.transaction.entity.Transaction;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.module.wallet.WalletRepository;
import uz.agroinvest.module.wallet.entity.Wallet;
import uz.agroinvest.module.withdrawal.dto.CreateWithdrawalRequest;
import uz.agroinvest.module.withdrawal.dto.WithdrawalDto;
import uz.agroinvest.module.withdrawal.entity.WithdrawalRequest;
import uz.agroinvest.security.UserPrincipal;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class WithdrawalService {

    private final WithdrawalRepository withdrawalRepository;
    private final WalletRepository walletRepository;
    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final EncryptionUtil encryptionUtil;
    private final AuditLogService auditLogService;

    public WithdrawalService(
            WithdrawalRepository withdrawalRepository,
            WalletRepository walletRepository,
            UserRepository userRepository,
            TransactionRepository transactionRepository,
            EncryptionUtil encryptionUtil,
            AuditLogService auditLogService
    ) {
        this.withdrawalRepository = withdrawalRepository;
        this.walletRepository = walletRepository;
        this.userRepository = userRepository;
        this.transactionRepository = transactionRepository;
        this.encryptionUtil = encryptionUtil;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public WithdrawalDto requestWithdrawal(CreateWithdrawalRequest request, UserPrincipal principal) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        // AML/KYC: only identity-verified users may cash out, mirroring the same
        // check ProjectService.createProject already applies to farmers.
        if (user.getKycStatus() != KycStatus.VERIFIED) {
            throw new ApiException(ErrorCode.KYC_REQUIRED, HttpStatus.BAD_REQUEST, "Pul yechish uchun profilingiz tasdiqlangan bo'lishi shart");
        }

        Wallet wallet = walletRepository.findByUserIdForUpdate(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Hamyon topilmadi"));

        if (wallet.getBalance().compareTo(request.getAmount()) < 0) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Yechib olish uchun mablag' yetarli emas. Balans: " + wallet.getBalance() + " UZS");
        }

        // Deduct balance immediately
        wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
        walletRepository.save(wallet);

        WithdrawalRequest withdrawalRequest = WithdrawalRequest.builder()
                .user(user)
                .amount(request.getAmount())
                .status(WithdrawalStatus.PENDING)
                .bankName(request.getBankName())
                // The PAN is sensitive payment data at rest, same as passport data -
                // encrypt it with the same AES-GCM utility rather than storing plaintext.
                .cardNumber(encryptionUtil.encrypt(request.getCardNumber()))
                .build();

        WithdrawalRequest saved = withdrawalRepository.save(withdrawalRequest);
        return mapToDto(saved);
    }

    @Transactional
    public WithdrawalDto approveWithdrawal(UUID id, boolean approve, String adminComment, UserPrincipal principal) {
        WithdrawalRequest request = withdrawalRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Yechish so'rovi topilmadi"));

        if (request.getStatus() != WithdrawalStatus.PENDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Ushbu so'rov allaqachon ko'rib chiqilgan");
        }

        User admin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        Wallet wallet = walletRepository.findByUserIdForUpdate(request.getUser().getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        if (approve) {
            request.setStatus(WithdrawalStatus.APPROVED);
            wallet.setTotalWithdrawn(wallet.getTotalWithdrawn().add(request.getAmount()));
            walletRepository.save(wallet);

            // Record IMMUTABLE WITHDRAWAL transaction
            Transaction transaction = Transaction.builder()
                    .user(request.getUser())
                    .type(TransactionType.WITHDRAWAL)
                    .amount(request.getAmount())
                    .status(TransactionStatus.COMPLETED)
                    .build();
            transactionRepository.save(transaction);
        } else {
            request.setStatus(WithdrawalStatus.REJECTED);
            // Refund balance back to user's wallet
            wallet.setBalance(wallet.getBalance().add(request.getAmount()));
            walletRepository.save(wallet);

            // Record IMMUTABLE REFUND transaction
            Transaction transaction = Transaction.builder()
                    .user(request.getUser())
                    .type(TransactionType.REFUND)
                    .amount(request.getAmount())
                    .status(TransactionStatus.COMPLETED)
                    .metadata("{\"reason\": \"Withdrawal request rejected by Admin\"}")
                    .build();
            transactionRepository.save(transaction);
        }

        request.setAdminComment(adminComment);
        request.setProcessedBy(admin);
        request.setProcessedAt(LocalDateTime.now());

        WithdrawalRequest saved = withdrawalRepository.save(request);
        auditLogService.log(admin, approve ? "APPROVE_WITHDRAWAL" : "REJECT_WITHDRAWAL", "WithdrawalRequest", saved.getId().toString(),
                null, "{\"amount\": \"" + saved.getAmount() + "\", \"adminComment\": \"" + (adminComment != null ? adminComment : "") + "\"}");
        return mapToDto(saved);
    }

    @Transactional(readOnly = true)
    public Page<WithdrawalDto> getMyWithdrawalRequests(UserPrincipal principal, Pageable pageable) {
        return withdrawalRepository.findByUserId(principal.getId(), pageable).map(this::mapToDto);
    }

    @Transactional(readOnly = true)
    public Page<WithdrawalDto> getAllWithdrawalRequests(Pageable pageable) {
        return withdrawalRepository.findAll(pageable).map(this::mapToDto);
    }

    private WithdrawalDto mapToDto(WithdrawalRequest request) {
        return new WithdrawalDto(
                request.getId(),
                request.getUser().getId(),
                request.getUser().getFullName(),
                request.getAmount(),
                request.getStatus(),
                request.getBankName(),
                maskCardNumber(encryptionUtil.decrypt(request.getCardNumber())),
                request.getAdminComment(),
                request.getCreatedAt()
        );
    }

    // Only the last 4 digits are ever exposed via the API (list views, admin queue, etc).
    // The full PAN stays in the database for the operator who actually executes the bank
    // transfer to look up directly, not for display in any JSON response.
    private String maskCardNumber(String cardNumber) {
        if (cardNumber == null || cardNumber.isBlank()) {
            return cardNumber;
        }
        String digitsOnly = cardNumber.replaceAll("\\D", "");
        if (digitsOnly.length() < 4) {
            return "****";
        }
        String last4 = digitsOnly.substring(digitsOnly.length() - 4);
        return "**** **** **** " + last4;
    }
}
