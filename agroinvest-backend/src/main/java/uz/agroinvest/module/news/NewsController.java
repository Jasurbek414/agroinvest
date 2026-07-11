package uz.agroinvest.module.news;

import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.common.response.PageResponse;
import uz.agroinvest.module.news.dto.NewsDto;
import uz.agroinvest.module.news.dto.SaveNewsRequest;
import uz.agroinvest.security.UserPrincipal;

import java.util.UUID;

@RestController
public class NewsController {

    private final NewsService newsService;

    public NewsController(NewsService newsService) {
        this.newsService = newsService;
    }

    /** Public feed - the mobile home dashboard's news section. */
    @GetMapping("/api/v1/news")
    public ResponseEntity<ApiResponse<PageResponse<NewsDto>>> getActiveNews(Pageable pageable) {
        Page<NewsDto> page = newsService.getActiveNews(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @GetMapping("/api/v1/superadmin/news")
    @PreAuthorize("@authz.has('news.manage')")
    public ResponseEntity<ApiResponse<PageResponse<NewsDto>>> getAllNews(Pageable pageable) {
        Page<NewsDto> page = newsService.getAllNews(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.from(page)));
    }

    @PostMapping("/api/v1/superadmin/news")
    @PreAuthorize("@authz.has('news.manage')")
    public ResponseEntity<ApiResponse<NewsDto>> createNews(
            @Valid @RequestBody SaveNewsRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        NewsDto dto = newsService.createNews(request, principal);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    @PatchMapping("/api/v1/superadmin/news/{id}")
    @PreAuthorize("@authz.has('news.manage')")
    public ResponseEntity<ApiResponse<NewsDto>> updateNews(@PathVariable UUID id, @Valid @RequestBody SaveNewsRequest request) {
        return ResponseEntity.ok(ApiResponse.success(newsService.updateNews(id, request)));
    }

    @DeleteMapping("/api/v1/superadmin/news/{id}")
    @PreAuthorize("@authz.has('news.manage')")
    public ResponseEntity<ApiResponse<Void>> deleteNews(@PathVariable UUID id) {
        newsService.deleteNews(id);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
