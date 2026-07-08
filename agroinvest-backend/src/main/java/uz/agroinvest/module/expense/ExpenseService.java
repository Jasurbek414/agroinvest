package uz.agroinvest.module.expense;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.ExpensePolicy;
import uz.agroinvest.common.enums.ExpenseStatus;
import uz.agroinvest.common.enums.NotificationChannel;
import uz.agroinvest.common.enums.PayerSource;
import uz.agroinvest.common.enums.ProjectStatus;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.expense.dto.CreateExpenseRequest;
import uz.agroinvest.module.expense.dto.ExpenseDto;
import uz.agroinvest.module.expense.entity.Expense;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.notification.NotificationService;
import uz.agroinvest.module.project.ProjectRepository;
import uz.agroinvest.module.project.entity.Project;
import uz.agroinvest.module.superadmin.AuditLogService;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class ExpenseService {

    private static final Set<UserRole> STAFF_ROLES = Set.of(UserRole.SUPERADMIN, UserRole.ADMIN, UserRole.MODERATOR);

    private final ExpenseRepository expenseRepository;
    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final InvestmentRepository investmentRepository;
    private final NotificationService notificationService;
    private final AuditLogService auditLogService;

    public ExpenseService(
            ExpenseRepository expenseRepository,
            ProjectRepository projectRepository,
            UserRepository userRepository,
            InvestmentRepository investmentRepository,
            NotificationService notificationService,
            AuditLogService auditLogService
    ) {
        this.expenseRepository = expenseRepository;
        this.projectRepository = projectRepository;
        this.userRepository = userRepository;
        this.investmentRepository = investmentRepository;
        this.notificationService = notificationService;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public ExpenseDto submitExpense(UUID projectId, CreateExpenseRequest request, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        if (!project.getFarmer().getId().equals(principal.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN,
                    "Faqat loyiha egasi harajat kiritishi mumkin");
        }

        if (project.getStatus() != ProjectStatus.ACTIVE && project.getStatus() != ProjectStatus.FUNDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Harajat faqat faol yoki moliyalashtirilayotgan loyihaga kiritiladi");
        }

        User farmer = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        Expense expense = Expense.builder()
                .project(project)
                .submittedBy(farmer)
                .category(request.getCategory())
                .amount(request.getAmount())
                .description(request.getDescription())
                .receiptUrls(request.getReceiptUrls())
                .expenseDate(request.getExpenseDate())
                .payerSource(derivePayerSource(project.getExpensePolicy(), request.getPayerSource()))
                .status(ExpenseStatus.PENDING)
                .build();

        return mapToDto(expenseRepository.save(expense));
    }

    /**
     * The payer is a consequence of the project's expense policy, decided at
     * project creation - never client-chosen, except under MIXED where each
     * expense is tagged individually.
     */
    private PayerSource derivePayerSource(ExpensePolicy policy, PayerSource requested) {
        return switch (policy) {
            case INVESTOR_BUDGET -> PayerSource.INVESTOR_BUDGET;
            case FARMER_REIMBURSED -> PayerSource.FARMER;
            case MIXED -> {
                if (requested == null) {
                    throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                            "Aralash siyosatda har bir harajat uchun to'lovchini tanlang");
                }
                yield requested;
            }
        };
    }

    /**
     * Visibility: project owner, this project's investors, and staff. Expense
     * details (receipts, amounts) are financially sensitive - not public.
     */
    @Transactional(readOnly = true)
    public List<ExpenseDto> getProjectExpenses(UUID projectId, UserPrincipal principal) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Loyiha topilmadi"));

        boolean isOwner = project.getFarmer().getId().equals(principal.getId());
        boolean isStaff = STAFF_ROLES.contains(principal.getRole());
        boolean isInvestor = investmentRepository.existsByProjectIdAndInvestorId(projectId, principal.getId());

        if (!isOwner && !isStaff && !isInvestor) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN,
                    "Harajatlarni faqat loyiha egasi, investorlari va adminlar ko'ra oladi");
        }

        return expenseRepository.findByProjectIdOrderByExpenseDateDescCreatedAtDesc(projectId).stream()
                .map(this::mapToDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public Page<ExpenseDto> getPendingExpenses(Pageable pageable) {
        return expenseRepository.findByStatusOrderByCreatedAtAsc(ExpenseStatus.PENDING, pageable).map(this::mapToDto);
    }

    @Transactional
    public ExpenseDto reviewExpense(UUID expenseId, boolean approve, String comment, UserPrincipal principal) {
        Expense expense = expenseRepository.findById(expenseId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Harajat topilmadi"));

        if (expense.getStatus() != ExpenseStatus.PENDING) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST,
                    "Faqat kutilayotgan harajatni ko'rib chiqish mumkin");
        }

        User reviewer = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        expense.setStatus(approve ? ExpenseStatus.APPROVED : ExpenseStatus.REJECTED);
        expense.setReviewedBy(reviewer);
        expense.setReviewedAt(LocalDateTime.now());
        expense.setReviewComment(comment);
        Expense saved = expenseRepository.save(expense);

        auditLogService.log(reviewer, approve ? "APPROVE_EXPENSE" : "REJECT_EXPENSE", "Expense", saved.getId().toString(),
                "{\"status\": \"PENDING\"}",
                "{\"status\": \"" + saved.getStatus() + "\", \"amount\": \"" + saved.getAmount() + "\", \"comment\": \"" + (comment != null ? comment : "") + "\"}");

        notificationService.createNotification(
                expense.getSubmittedBy(),
                "EXPENSE_REVIEWED",
                approve ? "Harajat tasdiqlandi" : "Harajat rad etildi",
                "\"" + expense.getProject().getTitle() + "\" loyihasidagi "
                        + expense.getAmount().stripTrailingZeros().toPlainString() + " so'mlik harajatingiz "
                        + (approve ? "tasdiqlandi" : ("rad etildi" + (comment != null && !comment.isBlank() ? ": " + comment : ""))),
                NotificationChannel.IN_APP
        );

        return mapToDto(saved);
    }

    private ExpenseDto mapToDto(Expense expense) {
        return ExpenseDto.builder()
                .id(expense.getId())
                .projectId(expense.getProject().getId())
                .projectTitle(expense.getProject().getTitle())
                .submittedByName(expense.getSubmittedBy().getFullName())
                .category(expense.getCategory())
                .amount(expense.getAmount())
                .description(expense.getDescription())
                .receiptUrls(expense.getReceiptUrls())
                .expenseDate(expense.getExpenseDate())
                .payerSource(expense.getPayerSource())
                .status(expense.getStatus())
                .reviewComment(expense.getReviewComment())
                .reviewedAt(expense.getReviewedAt())
                .createdAt(expense.getCreatedAt())
                .build();
    }
}
