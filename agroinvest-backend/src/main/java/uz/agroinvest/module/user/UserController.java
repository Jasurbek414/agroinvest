package uz.agroinvest.module.user;

import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.common.response.PageResponse;
import uz.agroinvest.module.user.dto.KycDetailDto;
import uz.agroinvest.module.user.dto.KycRequest;
import uz.agroinvest.module.user.dto.UpdateFcmTokenRequest;
import uz.agroinvest.module.user.dto.UpdateProfileRequest;
import uz.agroinvest.module.user.dto.UserDto;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@PreAuthorize("isAuthenticated()")
public class UserController {

    private final UserService userService;
    private final UserRepository userRepository;

    public UserController(UserService userService, UserRepository userRepository) {
        this.userService = userService;
        this.userRepository = userRepository;
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserDto>> getMe(@AuthenticationPrincipal UserPrincipal principal) {
        UserDto dto = userService.getUserDtoById(principal.getId());
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @PatchMapping("/me")
    public ResponseEntity<ApiResponse<UserDto>> updateProfile(
            @Valid @RequestBody UpdateProfileRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        UserDto dto = userService.updateProfile(principal.getId(), request);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @PatchMapping("/me/fcm-token")
    public ResponseEntity<ApiResponse<Void>> updateFcmToken(
            @Valid @RequestBody UpdateFcmTokenRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        userService.updateFcmToken(principal.getId(), request.getFcmToken());
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PostMapping("/me/kyc")
    public ResponseEntity<ApiResponse<UserDto>> submitKyc(
            @Valid @RequestBody KycRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        UserDto dto = userService.submitKyc(principal.getId(), request);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @GetMapping("/{id}/public")
    public ResponseEntity<ApiResponse<UserDto>> getPublicProfile(@PathVariable UUID id) {
        UserDto dto = userService.getPublicProfile(id);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<PageResponse<UserDto>>> getAllUsers(
            @RequestParam(required = false) UserRole role,
            @RequestParam(required = false) String q,
            Pageable pageable
    ) {
        Page<UserDto> page = userService.getAllUsers(role, q, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @GetMapping("/{id}/kyc-detail")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<KycDetailDto>> getKycDetail(@PathVariable UUID id) {
        KycDetailDto dto = userService.getKycDetail(id);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @PatchMapping("/{id}/block")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<ApiResponse<Void>> blockUser(
            @PathVariable UUID id,
            @RequestParam boolean block,
            @RequestParam(required = false) String reason,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        User admin = userRepository.findById(principal.getId()).orElseThrow();
        userService.blockUser(id, block, reason, admin);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PatchMapping("/{id}/kyc")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN', 'MODERATOR')")
    public ResponseEntity<ApiResponse<UserDto>> updateKyc(
            @PathVariable UUID id,
            @RequestParam KycStatus status,
            @RequestParam(required = false) String rejectedReason,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        User admin = userRepository.findById(principal.getId()).orElseThrow();
        UserDto dto = userService.updateKycStatus(id, status, rejectedReason, admin);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }
}
