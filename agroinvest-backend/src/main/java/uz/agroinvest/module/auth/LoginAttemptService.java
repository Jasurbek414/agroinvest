package uz.agroinvest.module.auth;

import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;

import java.util.concurrent.TimeUnit;

/**
 * Blunts online password brute-forcing: a phone number that fails too many login
 * attempts in a short window is locked out for a cooldown period, independent of
 * whether the password guesses are actually correct.
 */
@Service
public class LoginAttemptService {

    private static final int MAX_ATTEMPTS = 5;
    private static final long LOCKOUT_MINUTES = 15;

    private final RedisTemplate<String, Object> redisTemplate;

    public LoginAttemptService(RedisTemplate<String, Object> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public void checkNotLocked(String phoneNumber) {
        Integer attempts = (Integer) redisTemplate.opsForValue().get(key(phoneNumber));
        if (attempts != null && attempts >= MAX_ATTEMPTS) {
            throw new ApiException(ErrorCode.LOGIN_LOCKED, HttpStatus.TOO_MANY_REQUESTS);
        }
    }

    public void recordFailure(String phoneNumber) {
        String redisKey = key(phoneNumber);
        Long attempts = redisTemplate.opsForValue().increment(redisKey);
        if (attempts != null && attempts == 1L) {
            redisTemplate.expire(redisKey, LOCKOUT_MINUTES, TimeUnit.MINUTES);
        }
    }

    public void resetOnSuccess(String phoneNumber) {
        redisTemplate.delete(key(phoneNumber));
    }

    private String key(String phoneNumber) {
        return "login_attempts:" + phoneNumber;
    }
}
