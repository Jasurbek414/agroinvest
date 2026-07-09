package uz.agroinvest.module.upload;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Real object storage for KYC documents, project photos, and progress-report media -
 * replaces the mock Unsplash/empty-array placeholders the clients used previously.
 * Works against any S3-compatible endpoint (MinIO locally, Cloudflare R2 in prod).
 */
@Service
public class FileStorageService {

    private static final Logger logger = LoggerFactory.getLogger(FileStorageService.class);

    private static final long MAX_SIZE_BYTES = 10L * 1024 * 1024; // 10MB
    // PDF added for vet-inspection conclusions and expense receipts, which are
    // routinely issued as documents rather than photos.
    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of("image/jpeg", "image/png", "image/webp", "application/pdf");
    private static final Map<String, String> EXTENSION_BY_CONTENT_TYPE = Map.of(
            "image/jpeg", ".jpg",
            "image/png", ".png",
            "image/webp", ".webp",
            "application/pdf", ".pdf"
    );
    private static final Set<String> ALLOWED_CATEGORIES = Set.of("kyc", "project", "report", "general", "vet", "expense", "deposit", "banner");

    private final S3Client s3Client;
    private final String bucket;
    private final String publicUrl;

    public FileStorageService(
            S3Client s3Client,
            @Value("${s3.bucket}") String bucket,
            @Value("${s3.public-url}") String publicUrl
    ) {
        this.s3Client = s3Client;
        this.bucket = bucket;
        this.publicUrl = publicUrl.endsWith("/") ? publicUrl.substring(0, publicUrl.length() - 1) : publicUrl;
    }

    public String upload(MultipartFile file, String category) {
        if (file == null || file.isEmpty()) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Fayl tanlanmagan");
        }
        if (file.getSize() > MAX_SIZE_BYTES) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Fayl hajmi 10MB dan oshmasligi kerak");
        }
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new ApiException(ErrorCode.BAD_REQUEST, HttpStatus.BAD_REQUEST, "Faqat JPEG, PNG, WEBP rasm yoki PDF fayllari qabul qilinadi");
        }

        String safeCategory = ALLOWED_CATEGORIES.contains(category == null ? "" : category.toLowerCase())
                ? category.toLowerCase()
                : "general";
        String key = safeCategory + "/" + UUID.randomUUID() + EXTENSION_BY_CONTENT_TYPE.get(contentType);

        try {
            s3Client.putObject(
                    PutObjectRequest.builder()
                            .bucket(bucket)
                            .key(key)
                            .contentType(contentType)
                            .build(),
                    RequestBody.fromInputStream(file.getInputStream(), file.getSize())
            );
        } catch (IOException e) {
            logger.error("File upload failed for category={}", safeCategory, e);
            throw new ApiException(ErrorCode.INTERNAL_SERVER_ERROR, HttpStatus.INTERNAL_SERVER_ERROR, "Faylni yuklashda xatolik yuz berdi");
        }

        return publicUrl + "/" + key;
    }
}
