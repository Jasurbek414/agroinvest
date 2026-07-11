package uz.agroinvest.module.news;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.news.dto.NewsDto;
import uz.agroinvest.module.news.dto.SaveNewsRequest;
import uz.agroinvest.module.news.entity.News;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;

import java.util.UUID;

@Service
public class NewsService {

    private final NewsRepository newsRepository;
    private final UserRepository userRepository;

    public NewsService(NewsRepository newsRepository, UserRepository userRepository) {
        this.newsRepository = newsRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public Page<NewsDto> getActiveNews(Pageable pageable) {
        return newsRepository.findByIsActiveTrueOrderByCreatedAtDesc(pageable).map(this::mapToDto);
    }

    @Transactional(readOnly = true)
    public Page<NewsDto> getAllNews(Pageable pageable) {
        return newsRepository.findAllByOrderByCreatedAtDesc(pageable).map(this::mapToDto);
    }

    @Transactional
    public NewsDto createNews(SaveNewsRequest request, UserPrincipal principal) {
        User createdBy = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        News saved = newsRepository.save(News.builder()
                .title(request.getTitle())
                .body(request.getBody())
                .imageUrl(request.getImageUrl())
                .isActive(request.isActive())
                .createdBy(createdBy)
                .build());
        return mapToDto(saved);
    }

    @Transactional
    public NewsDto updateNews(UUID id, SaveNewsRequest request) {
        News news = newsRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Yangilik topilmadi"));

        news.setTitle(request.getTitle());
        news.setBody(request.getBody());
        news.setImageUrl(request.getImageUrl());
        news.setActive(request.isActive());

        return mapToDto(newsRepository.save(news));
    }

    @Transactional
    public void deleteNews(UUID id) {
        if (!newsRepository.existsById(id)) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Yangilik topilmadi");
        }
        newsRepository.deleteById(id);
    }

    private NewsDto mapToDto(News news) {
        return NewsDto.builder()
                .id(news.getId())
                .title(news.getTitle())
                .body(news.getBody())
                .imageUrl(news.getImageUrl())
                .isActive(news.isActive())
                .createdAt(news.getCreatedAt())
                .build();
    }
}
