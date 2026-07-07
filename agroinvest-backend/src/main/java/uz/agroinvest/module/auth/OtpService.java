package uz.agroinvest.module.auth;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.integration.sms.SmsService;

import java.security.SecureRandom;
import java.util.concurrent.TimeUnit;

@Service
public class OtpService {

    private static final Logger logger = LoggerFactory.getLogger(OtpService.class);
    private final RedisTemplate<String, Object> redisTemplate;
    private final SmsService smsService;
    private final SecureRandom secureRandom = new SecureRandom();

    private final long otpExpiryMinutes = 5;
    private final int maxOtpAttempts = 3;
    private final long resendCooldownSeconds = 60;
    private final int maxSendsPerHour = 5;
    private final long verifiedTicketMinutes = 10;

    // Same "safe until configured" pattern as SmsService/FcmPushService: with no real
    // Eskiz.uz credentials, SMS never actually reaches the user's phone, so - only in
    // that mock mode - every OTP is this fixed code instead of a random one, letting
    // registration/login/withdrawal etc. be tested without reading server logs.
    private static final String MOCK_OTP_CODE = "123456";

    @Value("${sms.email:}")
    private String smsEmail;

    @Value("${sms.password:}")
    private String smsPassword;

    public OtpService(RedisTemplate<String, Object> redisTemplate, SmsService smsService) {
        this.redisTemplate = redisTemplate;
        this.smsService = smsService;
    }

    private boolean isSmsProviderConfigured() {
        return smsEmail != null && !smsEmail.isBlank() && smsPassword != null && !smsPassword.isBlank();
    }

    public String generateAndSaveOtp(String phoneNumber, String purpose) {
        String cooldownKey = getCooldownKey(phoneNumber, purpose);
        if (Boolean.TRUE.equals(redisTemplate.hasKey(cooldownKey))) {
            // Tell the client exactly how long to wait - the mobile app shows this as a
            // countdown and (since a valid code is already live) still lets the user
            // proceed to the code-entry screen instead of dead-ending them here.
            Long ttl = redisTemplate.getExpire(cooldownKey, TimeUnit.SECONDS);
            long waitSeconds = (ttl != null && ttl > 0) ? ttl : resendCooldownSeconds;
            throw new ApiException(ErrorCode.OTP_SEND_TOO_SOON, HttpStatus.TOO_MANY_REQUESTS,
                    "Kod allaqachon yuborilgan. Qayta yuborish uchun " + waitSeconds + " soniya kuting");
        }

        // Blunts SMS-bombing: caps how many codes can be requested for one phone/purpose per hour.
        String sendCountKey = getSendCountKey(phoneNumber, purpose);
        Long sendCount = redisTemplate.opsForValue().increment(sendCountKey);
        if (sendCount != null && sendCount == 1L) {
            redisTemplate.expire(sendCountKey, 1, TimeUnit.HOURS);
        }
        if (sendCount != null && sendCount > maxSendsPerHour) {
            throw new ApiException(ErrorCode.OTP_SEND_LIMIT, HttpStatus.TOO_MANY_REQUESTS);
        }

        String redisKey = getRedisKey(phoneNumber, purpose);
        String attemptsKey = getAttemptsKey(phoneNumber, purpose);

        String code = isSmsProviderConfigured()
                ? String.format("%06d", secureRandom.nextInt(1_000_000))
                : MOCK_OTP_CODE;

        redisTemplate.opsForValue().set(redisKey, code, otpExpiryMinutes, TimeUnit.MINUTES);
        // Attempts counter is keyed to the phone+purpose, not to this specific code, and is
        // only initialized if absent - resending a code must NOT give an attacker a fresh
        // set of guesses against whatever code is currently live.
        redisTemplate.opsForValue().setIfAbsent(attemptsKey, 0, otpExpiryMinutes, TimeUnit.MINUTES);

        smsService.sendSms(phoneNumber, "AgroInvest tasdiqlash kodi: " + code + ". Kodni hech kimga bermang.");
        // Cooldown starts only once the send has been handed off - a synchronous failure
        // above must not leave the user blocked from retrying with no SMS in hand.
        redisTemplate.opsForValue().set(cooldownKey, "1", resendCooldownSeconds, TimeUnit.SECONDS);
        logger.info("OTP generated for {} ({})", phoneNumber, purpose);

        return code;
    }

    public void verifyOtp(String phoneNumber, String purpose, String code) {
        String redisKey = getRedisKey(phoneNumber, purpose);
        String attemptsKey = getAttemptsKey(phoneNumber, purpose);

        String savedCode = (String) redisTemplate.opsForValue().get(redisKey);
        if (savedCode == null) {
            throw new ApiException(ErrorCode.OTP_EXPIRED, HttpStatus.BAD_REQUEST);
        }

        Integer attemptsObj = (Integer) redisTemplate.opsForValue().get(attemptsKey);
        int attempts = (attemptsObj == null) ? 0 : attemptsObj;

        if (attempts >= maxOtpAttempts) {
            redisTemplate.delete(redisKey);
            redisTemplate.delete(attemptsKey);
            throw new ApiException(ErrorCode.OTP_MAX_ATTEMPTS, HttpStatus.BAD_REQUEST);
        }

        if (!savedCode.equals(code)) {
            attempts++;
            redisTemplate.opsForValue().set(attemptsKey, attempts, otpExpiryMinutes, TimeUnit.MINUTES);
            throw new ApiException(ErrorCode.OTP_INVALID, HttpStatus.BAD_REQUEST);
        }

        // OTP verified successfully, clean up and issue a short-lived "verified" ticket so a
        // dependent action (registration, KYC, password reset) can prove phone ownership
        // without re-sending the code.
        redisTemplate.delete(redisKey);
        redisTemplate.delete(attemptsKey);
        redisTemplate.opsForValue().set(getVerifiedKey(phoneNumber, purpose), "1", verifiedTicketMinutes, TimeUnit.MINUTES);
    }

    /**
     * Consumes the "verified" ticket left by a successful verifyOtp call. Throws if the
     * phone number was never verified (or the ticket expired), so callers like
     * AuthService.register cannot be reached without a real OTP round-trip first.
     */
    public void requireVerified(String phoneNumber, String purpose) {
        String verifiedKey = getVerifiedKey(phoneNumber, purpose);
        Boolean existed = redisTemplate.delete(verifiedKey);
        if (!Boolean.TRUE.equals(existed)) {
            throw new ApiException(ErrorCode.PHONE_NOT_VERIFIED, HttpStatus.BAD_REQUEST);
        }
    }

    private String getRedisKey(String phoneNumber, String purpose) {
        return "otp:" + purpose.toLowerCase() + ":" + phoneNumber;
    }

    private String getAttemptsKey(String phoneNumber, String purpose) {
        return "otp_attempts:" + purpose.toLowerCase() + ":" + phoneNumber;
    }

    private String getCooldownKey(String phoneNumber, String purpose) {
        return "otp_cooldown:" + purpose.toLowerCase() + ":" + phoneNumber;
    }

    private String getSendCountKey(String phoneNumber, String purpose) {
        return "otp_send_count:" + purpose.toLowerCase() + ":" + phoneNumber;
    }

    private String getVerifiedKey(String phoneNumber, String purpose) {
        return "otp_verified:" + purpose.toLowerCase() + ":" + phoneNumber;
    }
}
