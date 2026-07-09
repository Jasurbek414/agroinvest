package uz.agroinvest.module.deposit;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.DepositStatus;
import uz.agroinvest.common.enums.PaymentProvider;
import uz.agroinvest.common.enums.TransactionStatus;
import uz.agroinvest.common.enums.TransactionType;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.deposit.dto.CreateDepositRequest;
import uz.agroinvest.module.deposit.dto.DepositRequestDto;
import uz.agroinvest.module.deposit.entity.DepositRequest;
import uz.agroinvest.module.superadmin.AuditLogService;
import uz.agroinvest.module.transaction.TransactionRepository;
import uz.agroinvest.module.transaction.entity.Transaction;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.module.wallet.WalletRepository;
import uz.agroinvest.module.wallet.entity.Wallet;
import uz.agroinvest.security.UserPrincipal;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Manual top-up approval queue - interim replacement for a live Payme/Click
 * gateway (product decision: payments go through admin/superadmin approval for
 * now). Unlike WithdrawalService, creating a request does NOT touch the wallet -
 * only approveOrReject(approve=true) credits the balance, since nothing has
 * left/entered the platform yet at request time (the user is just submitting
 * evidence of an off-platform bank transfer for a human to verify).
 */
@Service
public class DepositRequestService {

    private final DepositRequestRepository depositRequestRepository;
    private final WalletRepository walletRepository;
    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final AuditLogService auditLogService;

    public DepositRequestService(
            DepositRequestRepository depositRequestRepository,
            WalletRepository walletRepository,
            UserRepository userRepository,
            TransactionRepository transactionRepository,
            AuditLogService auditLogService
    ) {
        this.depositRequestRepository = depositRequestRepository;
        this.walletRepository = walletRepository;
        this.userRepository = userRepository;
        this.transactionRepository = transactionRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public DepositRequestDto createDepositRequest(CreateDepositRequest request, UserPrincipal principal) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        DepositRequest saved = depositRequestRepository.save(DepositRequest.builder()
                .user(user)
                .amount(request.getAmount())
                .proofUrl(request.getProofUrl())
                .status(DepositStatus.PENDING)
                .build());

        return mapToDto(saved);
    }

    @Transactional
    public DepositRequestDto approveOrReject(UUID id, boolean approve, String adminComment, UserPrincipal principal) {
        DepositRequest request = depositRequestRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "To'lov so'rovi topilmadi"));

        if (request.getStatus() != DepositStatus.PENDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Ushbu so'rov allaqachon ko'rib chiqilgan");
        }

        User admin = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        if (approve) {
            Wallet wallet = walletRepository.findByUserIdForUpdate(request.getUser().getId())
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Hamyon topilmadi"));

            wallet.setBalance(wallet.getBalance().add(request.getAmount()));
            walletRepository.save(wallet);

            Transaction transaction = Transaction.builder()
                    .user(request.getUser())
                    .type(TransactionType.DEPOSIT)
                    .amount(request.getAmount())
                    .status(TransactionStatus.COMPLETED)
                    .paymentProvider(PaymentProvider.MANUAL)
                    .build();
            transactionRepository.save(transaction);

            request.setStatus(DepositStatus.APPROVED);
        } else {
            // Nothing was debited at creation, so there is nothing to refund - just record the decision.
            request.setStatus(DepositStatus.REJECTED);
        }

        request.setAdminComment(adminComment);
        request.setReviewedBy(admin);
        request.setReviewedAt(LocalDateTime.now());

        DepositRequest saved = depositRequestRepository.save(request);
        auditLogService.log(admin, approve ? "APPROVE_DEPOSIT" : "REJECT_DEPOSIT", "DepositRequest", saved.getId().toString(),
                null, "{\"amount\": \"" + saved.getAmount() + "\", \"adminComment\": \"" + (adminComment != null ? adminComment : "") + "\"}");
        return mapToDto(saved);
    }

    @Transactional(readOnly = true)
    public Page<DepositRequestDto> getMyDepositRequests(UserPrincipal principal, Pageable pageable) {
        return depositRequestRepository.findByUserId(principal.getId(), pageable).map(this::mapToDto);
    }

    @Transactional(readOnly = true)
    public Page<DepositRequestDto> getAllDepositRequests(Pageable pageable) {
        return depositRequestRepository.findAll(pageable).map(this::mapToDto);
    }

    private DepositRequestDto mapToDto(DepositRequest request) {
        return new DepositRequestDto(
                request.getId(),
                request.getUser().getId(),
                request.getUser().getFullName(),
                request.getAmount(),
                request.getProofUrl(),
                request.getStatus(),
                request.getAdminComment(),
                request.getCreatedAt()
        );
    }
}
