package uz.agroinvest.common.exception;

import org.springframework.http.HttpStatus;

public class ApiException extends RuntimeException {

    private final ErrorCode errorCode;
    private final HttpStatus httpStatus;
    private final Object details;

    public ApiException(ErrorCode errorCode, HttpStatus httpStatus) {
        super(errorCode.getDefaultMessage());
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
        this.details = null;
    }

    public ApiException(ErrorCode errorCode, HttpStatus httpStatus, String customMessage) {
        super(customMessage);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
        this.details = null;
    }

    public ApiException(ErrorCode errorCode, HttpStatus httpStatus, Object details) {
        super(errorCode.getDefaultMessage());
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
        this.details = details;
    }

    public ErrorCode getErrorCode() {
        return errorCode;
    }

    public HttpStatus getHttpStatus() {
        return httpStatus;
    }

    public Object getDetails() {
        return details;
    }
}
