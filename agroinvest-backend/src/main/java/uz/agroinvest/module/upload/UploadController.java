package uz.agroinvest.module.upload;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import uz.agroinvest.common.response.ApiResponse;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/uploads")
@PreAuthorize("isAuthenticated()")
public class UploadController {

    private final FileStorageService fileStorageService;

    public UploadController(FileStorageService fileStorageService) {
        this.fileStorageService = fileStorageService;
    }

    /**
     * category: "kyc" | "project" | "report" - used only to namespace the storage key;
     * unrecognised values fall back to "general". Returns the public URL to attach to
     * the corresponding JSON payload (KycRequest.passportPhotoUrl, CreateProjectRequest.mediaUrls,
     * CreateReportRequest.mediaUrls, etc).
     */
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, String>>> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam(defaultValue = "general") String category
    ) {
        String url = fileStorageService.upload(file, category);
        return ResponseEntity.ok(ApiResponse.success(Map.of("url", url)));
    }
}
