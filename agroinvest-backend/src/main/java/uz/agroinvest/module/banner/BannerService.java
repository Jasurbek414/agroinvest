package uz.agroinvest.module.banner;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.BannerAudience;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.banner.dto.BannerDto;
import uz.agroinvest.module.banner.dto.SaveBannerRequest;
import uz.agroinvest.module.banner.entity.Banner;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class BannerService {

    private final BannerRepository bannerRepository;
    private final UserRepository userRepository;

    public BannerService(BannerRepository bannerRepository, UserRepository userRepository) {
        this.bannerRepository = bannerRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<BannerDto> getActiveBanners(BannerAudience audience) {
        return bannerRepository.findActiveForAudience(audience, LocalDateTime.now()).stream()
                .map(this::mapToDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<BannerDto> getAllBanners() {
        return bannerRepository.findAllByOrderBySortOrderAscCreatedAtDesc().stream()
                .map(this::mapToDto)
                .toList();
    }

    @Transactional
    public BannerDto createBanner(SaveBannerRequest request, UserPrincipal principal) {
        User createdBy = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));

        Banner saved = bannerRepository.save(Banner.builder()
                .title(request.getTitle())
                .imageUrl(request.getImageUrl())
                .linkUrl(request.getLinkUrl())
                .targetAudience(request.getTargetAudience())
                .isActive(request.isActive())
                .sortOrder(request.getSortOrder() != null ? request.getSortOrder() : 0)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .createdBy(createdBy)
                .build());
        return mapToDto(saved);
    }

    @Transactional
    public BannerDto updateBanner(UUID id, SaveBannerRequest request) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Reklama topilmadi"));

        banner.setTitle(request.getTitle());
        banner.setImageUrl(request.getImageUrl());
        banner.setLinkUrl(request.getLinkUrl());
        banner.setTargetAudience(request.getTargetAudience());
        banner.setActive(request.isActive());
        banner.setSortOrder(request.getSortOrder() != null ? request.getSortOrder() : 0);
        banner.setStartDate(request.getStartDate());
        banner.setEndDate(request.getEndDate());

        return mapToDto(bannerRepository.save(banner));
    }

    @Transactional
    public void deleteBanner(UUID id) {
        if (!bannerRepository.existsById(id)) {
            throw new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Reklama topilmadi");
        }
        bannerRepository.deleteById(id);
    }

    private BannerDto mapToDto(Banner banner) {
        return BannerDto.builder()
                .id(banner.getId())
                .title(banner.getTitle())
                .imageUrl(banner.getImageUrl())
                .linkUrl(banner.getLinkUrl())
                .targetAudience(banner.getTargetAudience())
                .isActive(banner.isActive())
                .sortOrder(banner.getSortOrder())
                .startDate(banner.getStartDate())
                .endDate(banner.getEndDate())
                .createdAt(banner.getCreatedAt())
                .build();
    }
}
