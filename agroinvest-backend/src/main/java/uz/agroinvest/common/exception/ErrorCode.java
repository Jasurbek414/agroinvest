package uz.agroinvest.common.exception;

public enum ErrorCode {
    INTERNAL_SERVER_ERROR("INTERNAL_SERVER_ERROR", "Ichki server xatoligi yuz berdi"),
    VALIDATION_ERROR("VALIDATION_ERROR", "Kiritilgan ma'lumotlar tekshiruvdan o'tmadi"),
    UNAUTHORIZED("UNAUTHORIZED", "Tizimga kirish talab etiladi"),
    FORBIDDEN("FORBIDDEN", "Ushbu amalni bajarish uchun ruxsat etilmagan"),
    NOT_FOUND("NOT_FOUND", "Resurs topilmadi"),
    BAD_REQUEST("BAD_REQUEST", "Noto'g'ri so'rov yuborildi"),
    OTP_EXPIRED("OTP_EXPIRED", "OTP tasdiqlash kodi muddati tugagan"),
    OTP_INVALID("OTP_INVALID", "Tasdiqlash kodi xato"),
    OTP_MAX_ATTEMPTS("OTP_MAX_ATTEMPTS", "Urinishlar soni cheklangan, qayta yuboring"),
    PHONE_ALREADY_EXISTS("PHONE_ALREADY_EXISTS", "Ushbu telefon raqami ro'yxatdan o'tgan"),
    EMAIL_ALREADY_EXISTS("EMAIL_ALREADY_EXISTS", "Ushbu email ro'yxatdan o'tgan"),
    INVALID_CREDENTIALS("INVALID_CREDENTIALS", "Telefon raqami yoki parol xato"),
    USER_BLOCKED("USER_BLOCKED", "Sizning hisobingiz bloklangan"),
    KYC_REQUIRED("KYC_REQUIRED", "Ushbu amal uchun KYC tasdiqlash zarur"),
    IDEMPOTENCY_VIOLATION("IDEMPOTENCY_VIOLATION", "Ushbu so'rov allaqachon bajarilmoqda"),
    LOGIN_LOCKED("LOGIN_LOCKED", "Juda ko'p xato urinish. Iltimos,15 daqiqadan so'ng qayta urining"),
    PHONE_NOT_VERIFIED("PHONE_NOT_VERIFIED", "Avval telefon raqamingizni SMS kod orqali tasdiqlang"),
    OTP_SEND_TOO_SOON("OTP_SEND_TOO_SOON", "Kodni qayta yuborish uchun biroz kuting"),
    OTP_SEND_LIMIT("OTP_SEND_LIMIT", "Ushbu raqam uchun so'rovlar chegarasiga yetdingiz, keyinroq urining"),
    INVALID_TOKEN("INVALID_TOKEN", "Token yaroqsiz yoki muddati tugagan"),
    CONFLICT("CONFLICT", "So'rov ziddiyati yuz berdi, iltimos qaytadan urinib ko'ring");

    private final String code;
    private final String defaultMessage;

    ErrorCode(String code, String defaultMessage) {
        this.code = code;
        this.defaultMessage = defaultMessage;
    }

    public String getCode() {
        return code;
    }

    public String getDefaultMessage() {
        return defaultMessage;
    }
}
