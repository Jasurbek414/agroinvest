package uz.agroinvest.module.expense;

import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.common.response.PageResponse;
import uz.agroinvest.module.expense.dto.CreateExpenseRequest;
import uz.agroinvest.module.expense.dto.ExpenseDto;
import uz.agroinvest.module.expense.dto.ReviewExpenseRequest;
import uz.agroinvest.security.UserPrincipal;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/expenses")
public class ExpenseController {

    private final ExpenseService expenseService;

    public ExpenseController(ExpenseService expenseService) {
        this.expenseService = expenseService;
    }

    @PostMapping("/project/{projectId}")
    @PreAuthorize("hasRole('FARMER')")
    public ResponseEntity<ApiResponse<ExpenseDto>> submitExpense(
            @PathVariable UUID projectId,
            @Valid @RequestBody CreateExpenseRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        ExpenseDto dto = expenseService.submitExpense(projectId, request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    @GetMapping("/project/{projectId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<ExpenseDto>>> getProjectExpenses(
            @PathVariable UUID projectId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(ApiResponse.success(expenseService.getProjectExpenses(projectId, principal)));
    }

    @GetMapping("/pending")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<PageResponse<ExpenseDto>>> getPendingExpenses(Pageable pageable) {
        Page<ExpenseDto> page = expenseService.getPendingExpenses(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @PatchMapping("/{id}/review")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<ExpenseDto>> reviewExpense(
            @PathVariable UUID id,
            @Valid @RequestBody ReviewExpenseRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        ExpenseDto dto = expenseService.reviewExpense(id, request.getApprove(), request.getComment(), principal);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }
}
