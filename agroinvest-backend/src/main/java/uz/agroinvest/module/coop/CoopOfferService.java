package uz.agroinvest.module.coop;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import uz.agroinvest.module.notification.NotificationService;
import uz.agroinvest.common.enums.UserRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.module.coop.dto.CoopOfferDto;
import uz.agroinvest.module.coop.dto.SaveCoopOfferRequest;
import uz.agroinvest.module.coop.entity.CoopOffer;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import org.springframework.http.HttpStatus;

import java.util.UUID;

@Service
public class CoopOfferService {

    private final CoopOfferRepository repository;
    private final UserRepository userRepository;

    @Autowired
    @Lazy
    private NotificationService notificationService;

    public CoopOfferService(CoopOfferRepository repository, UserRepository userRepository) {
        this.repository = repository;
        this.userRepository = userRepository;
    }

    public Page<CoopOfferDto> getActiveOffers(String type, Pageable pageable) {
        Page<CoopOffer> page;
        if (type != null && !type.trim().isEmpty()) {
            page = repository.findAllByTypeAndStatus(type, "APPROVED", pageable);
        } else {
            page = repository.findAllByStatus("APPROVED", pageable);
        }
        return page.map(CoopOfferDto::fromEntity);
    }

    public Page<CoopOfferDto> getAllOffers(Pageable pageable) {
        return repository.findAll(pageable).map(CoopOfferDto::fromEntity);
    }

    @Transactional
    public CoopOfferDto createOffer(SaveCoopOfferRequest request, UserPrincipal principal) {
        User creator = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("Foydalanuvchi topilmadi"));

        CoopOffer offer = CoopOffer.builder()
                .title(request.title())
                .description(request.description())
                .type(request.type())
                .amount(request.amount())
                .status("PENDING")
                .creatorId(creator.getId())
                .creatorName(creator.getFullName())
                .contactPhone(request.contactPhone())
                .investmentId(request.investmentId())
                .build();
        
        CoopOffer saved = repository.save(offer);

        // Notify admins
        try {
            List<User> admins = userRepository.findByRoleIn(List.of(UserRole.ADMIN, UserRole.SUPERADMIN));
            for (User admin : admins) {
                notificationService.createNotification(
                        admin,
                        "COOP_OFFER_SUBMISSION",
                        "Investitsiyani bozorga chiqarish arizasi",
                        creator.getFullName() + " o'zining investitsiyasini investitsiya bozoriga chiqarish bo'yicha ariza berdi.",
                        uz.agroinvest.common.enums.NotificationChannel.IN_APP
                );
            }
        } catch (Exception ex) {
            // ignore
        }

        return CoopOfferDto.fromEntity(saved);
    }

    @Transactional
    public CoopOfferDto updateOfferStatus(UUID id, String status) {
        CoopOffer offer = repository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Loyiha topilmadi"));
        
        offer.setStatus(status);
        CoopOffer saved = repository.save(offer);
        return CoopOfferDto.fromEntity(saved);
    }

    @Transactional
    public void deleteOffer(UUID id) {
        if (!repository.existsById(id)) {
            throw new IllegalArgumentException("Loyiha topilmadi");
        }
        repository.deleteById(id);
    }

    @Transactional
    public void withdrawOffer(UUID id, UserPrincipal principal) {
        CoopOffer offer = repository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "E'lon topilmadi"));
        
        if (!offer.getCreatorId().equals(principal.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Ushbu e'lonni o'chirishga huquqingiz yo'q");
        }

        offer.setStatus("WITHDRAWN");
        CoopOffer saved = repository.save(offer);

        // Notify admins
        try {
            List<User> admins = userRepository.findByRoleIn(List.of(UserRole.ADMIN, UserRole.SUPERADMIN));
            for (User admin : admins) {
                notificationService.createNotification(
                        admin,
                        "COOP_OFFER_WITHDRAWN",
                        "Investitsiya bozori arizasi qaytarib olindi",
                        saved.getCreatorName() + " o'zining investitsiya bozoridagi arizasini qaytarib oldi.",
                        uz.agroinvest.common.enums.NotificationChannel.IN_APP
                );
            }
        } catch (Exception ex) {
            // ignore
        }
    }
}
