package uz.agroinvest.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.common.response.ApiResponse;

import java.io.IOException;

/**
 * Without this, Spring Security's default entry point for a missing/invalid/expired
 * JWT (Http403ForbiddenEntryPoint) returns a bare 403 with an empty body - the exact
 * same status GlobalExceptionHandler uses for a genuine @PreAuthorize role denial
 * (valid session, wrong role), just with a real ApiResponse body. Clients can't tell
 * "your session expired, log in again" apart from "you're logged in but not allowed
 * here" by status code alone, so a web client can never safely auto-refresh-and-retry
 * on session expiry without also mis-firing on legitimate 403s. This returns 401
 * with the same ApiResponse envelope the rest of the API uses, reserved for the
 * "not authenticated at all" case.
 */
@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private final ObjectMapper objectMapper;

    public RestAuthenticationEntryPoint(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response, AuthenticationException authException)
            throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        ApiResponse<Void> body = ApiResponse.fail(ErrorCode.UNAUTHORIZED.getCode(), ErrorCode.UNAUTHORIZED.getDefaultMessage());
        response.getWriter().write(objectMapper.writeValueAsString(body));
    }
}
