package uz.agroinvest.common.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import uz.agroinvest.common.response.ApiResponse;

import java.util.List;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ApiResponse<Void>> handleApiException(ApiException ex) {
        logger.error("ApiException caught: {} - Status: {}", ex.getMessage(), ex.getHttpStatus());
        ApiResponse<Void> response = ApiResponse.fail(ex.getErrorCode().getCode(), ex.getMessage(), ex.getDetails());
        return new ResponseEntity<>(response, ex.getHttpStatus());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidationException(MethodArgumentNotValidException ex) {
        logger.error("Validation error caught: {}", ex.getMessage());
        List<ValidationErrorDetail> details = ex.getBindingResult().getFieldErrors().stream()
                .map(err -> new ValidationErrorDetail(err.getField(), err.getDefaultMessage()))
                .collect(Collectors.toList());

        ApiResponse<Void> response = ApiResponse.fail(
                ErrorCode.VALIDATION_ERROR.getCode(),
                ErrorCode.VALIDATION_ERROR.getDefaultMessage(),
                details
        );
        return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDeniedException(AccessDeniedException ex) {
        logger.error("AccessDeniedException caught: {}", ex.getMessage());
        ApiResponse<Void> response = ApiResponse.fail(
                ErrorCode.FORBIDDEN.getCode(),
                ErrorCode.FORBIDDEN.getDefaultMessage()
        );
        return new ResponseEntity<>(response, HttpStatus.FORBIDDEN);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGeneralException(Exception ex) {
        logger.error("General Exception caught", ex);
        ApiResponse<Void> response = ApiResponse.fail(
                ErrorCode.INTERNAL_SERVER_ERROR.getCode(),
                ErrorCode.INTERNAL_SERVER_ERROR.getDefaultMessage()
        );
        return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    public static class ValidationErrorDetail {
        private final String field;
        private final String message;

        public ValidationErrorDetail(String field, String message) {
            this.field = field;
            this.message = message;
        }

        public String getField() {
            return field;
        }

        public String getMessage() {
            return message;
        }
    }
}
