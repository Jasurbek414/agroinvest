package uz.agroinvest.module.auth;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.KycStatus;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.auth.dto.AuthResponse;
import uz.agroinvest.module.auth.dto.LoginRequest;
import uz.agroinvest.module.auth.dto.RegisterRequest;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.module.wallet.WalletRepository;
import uz.agroinvest.module.wallet.entity.Wallet;
import uz.agroinvest.security.JwtTokenProvider;
import uz.agroinvest.security.UserPrincipal;

import java.math.BigDecimal;

@Service
public class AuthService {

    private static final String REGISTER_OTP_PURPOSE = "REGISTER";

    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final OtpService otpService;
    private final LoginAttemptService loginAttemptService;

    public AuthService(
            UserRepository userRepository,
            WalletRepository walletRepository,
            PasswordEncoder passwordEncoder,
            JwtTokenProvider jwtTokenProvider,
            OtpService otpService,
            LoginAttemptService loginAttemptService
    ) {
        this.userRepository = userRepository;
        this.walletRepository = walletRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenProvider = jwtTokenProvider;
        this.otpService = otpService;
        this.loginAttemptService = loginAttemptService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // Phone ownership must be proven via a real send-otp/verify-otp round-trip first;
        // this consumes the one-time ticket left by OtpService.verifyOtp.
        otpService.requireVerified(request.getPhoneNumber(), REGISTER_OTP_PURPOSE);

        if (userRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new ApiException(ErrorCode.PHONE_ALREADY_EXISTS, HttpStatus.BAD_REQUEST);
        }
        if (request.getEmail() != null && !request.getEmail().isBlank() && userRepository.existsByEmail(request.getEmail())) {
            throw new ApiException(ErrorCode.EMAIL_ALREADY_EXISTS, HttpStatus.BAD_REQUEST);
        }

        // Restrict role registration publicly to INVESTOR or FARMER
        if (request.getRole() != UserRole.INVESTOR && request.getRole() != UserRole.FARMER) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.BAD_REQUEST, "Ushbu rolda ro'yxatdan o'tish taqiqlangan");
        }

        // Create User
        User user = User.builder()
                .fullName(request.getFullName())
                .phoneNumber(request.getPhoneNumber())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())
                .kycStatus(KycStatus.PENDING)
                .rating(BigDecimal.ZERO)
                .totalProjects(0)
                .isActive(true)
                .isBlocked(false)
                .build();

        User savedUser = userRepository.save(user);

        // Create Wallet
        Wallet wallet = Wallet.builder()
                .user(savedUser)
                .balance(BigDecimal.ZERO)
                .frozen(BigDecimal.ZERO)
                .totalEarned(BigDecimal.ZERO)
                .totalWithdrawn(BigDecimal.ZERO)
                .build();

        walletRepository.save(wallet);

        UserPrincipal principal = new UserPrincipal(
                savedUser.getId(),
                savedUser.getPhoneNumber(),
                savedUser.getPasswordHash(),
                savedUser.getRole(),
                savedUser.isActive(),
                savedUser.isBlocked()
        );

        String accessToken = jwtTokenProvider.generateAccessToken(principal);
        String refreshToken = jwtTokenProvider.generateRefreshToken(principal);

        return new AuthResponse(
                accessToken,
                refreshToken,
                savedUser.getId(),
                savedUser.getFullName(),
                savedUser.getPhoneNumber(),
                savedUser.getRole()
        );
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        loginAttemptService.checkNotLocked(request.getPhoneNumber());

        User user = userRepository.findByPhoneNumber(request.getPhoneNumber())
                .orElseThrow(() -> {
                    loginAttemptService.recordFailure(request.getPhoneNumber());
                    return new ApiException(ErrorCode.INVALID_CREDENTIALS, HttpStatus.BAD_REQUEST);
                });

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            loginAttemptService.recordFailure(request.getPhoneNumber());
            throw new ApiException(ErrorCode.INVALID_CREDENTIALS, HttpStatus.BAD_REQUEST);
        }

        loginAttemptService.resetOnSuccess(request.getPhoneNumber());

        if (user.isBlocked()) {
            throw new ApiException(ErrorCode.USER_BLOCKED, HttpStatus.FORBIDDEN, user.getBlockedReason());
        }

        if (!user.isActive()) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Hisobingiz faol emas");
        }

        UserPrincipal principal = new UserPrincipal(
                user.getId(),
                user.getPhoneNumber(),
                user.getPasswordHash(),
                user.getRole(),
                user.isActive(),
                user.isBlocked()
        );

        String accessToken = jwtTokenProvider.generateAccessToken(principal);
        String refreshToken = jwtTokenProvider.generateRefreshToken(principal);

        return new AuthResponse(
                accessToken,
                refreshToken,
                user.getId(),
                user.getFullName(),
                user.getPhoneNumber(),
                user.getRole()
        );
    }

    @Transactional(readOnly = true)
    public AuthResponse refresh(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken)
                || !JwtTokenProvider.TYPE_REFRESH.equals(jwtTokenProvider.getTokenType(refreshToken))) {
            throw new ApiException(ErrorCode.INVALID_TOKEN, HttpStatus.UNAUTHORIZED);
        }

        String phoneNumber = jwtTokenProvider.getUsernameFromJwt(refreshToken);
        User user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new ApiException(ErrorCode.INVALID_TOKEN, HttpStatus.UNAUTHORIZED));

        if (user.isBlocked() || !user.isActive()) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Hisobingiz faol emas");
        }

        UserPrincipal principal = new UserPrincipal(
                user.getId(),
                user.getPhoneNumber(),
                user.getPasswordHash(),
                user.getRole(),
                user.isActive(),
                user.isBlocked()
        );

        // Rotate both tokens on every refresh rather than just minting a new access token.
        String newAccessToken = jwtTokenProvider.generateAccessToken(principal);
        String newRefreshToken = jwtTokenProvider.generateRefreshToken(principal);

        return new AuthResponse(
                newAccessToken,
                newRefreshToken,
                user.getId(),
                user.getFullName(),
                user.getPhoneNumber(),
                user.getRole()
        );
    }
}
