package uz.agroinvest.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtTokenProvider {

    private static final Logger logger = LoggerFactory.getLogger(JwtTokenProvider.class);

    private final SecretKey key;
    private final long accessExpiryMs;
    private final long refreshExpiryMs;

    public JwtTokenProvider(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.access-expiry-seconds:900}") long accessExpirySeconds,
            @Value("${jwt.refresh-expiry-seconds:2592000}") long refreshExpirySeconds
    ) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessExpiryMs = accessExpirySeconds * 1000;
        this.refreshExpiryMs = refreshExpirySeconds * 1000;
    }

    public static final String TYPE_ACCESS = "access";
    public static final String TYPE_REFRESH = "refresh";

    public String generateAccessToken(UserPrincipal principal) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + accessExpiryMs);

        return Jwts.builder()
                .subject(principal.getUsername())
                .claim("userId", principal.getId().toString())
                .claim("role", principal.getRole().name())
                .claim("type", TYPE_ACCESS)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }

    public String generateRefreshToken(UserPrincipal principal) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + refreshExpiryMs);

        return Jwts.builder()
                .subject(principal.getUsername())
                .claim("userId", principal.getId().toString())
                .claim("type", TYPE_REFRESH)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }

    public String getUsernameFromJwt(String token) {
        return parseClaims(token).getSubject();
    }

    /**
     * "access" or "refresh". A refresh token has no role claim and a 30-day expiry,
     * so it must never be accepted as an API bearer credential - only /auth/refresh
     * may consume it. See JwtAuthFilter, which rejects anything that isn't TYPE_ACCESS.
     */
    public String getTokenType(String token) {
        return parseClaims(token).get("type", String.class);
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            logger.error("Invalid JWT token: {}", e.getMessage());
        }
        return false;
    }
}
