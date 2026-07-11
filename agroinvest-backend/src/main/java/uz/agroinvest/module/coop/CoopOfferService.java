package uz.agroinvest.module.coop;

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

import java.util.UUID;

@Service
public class CoopOfferService {

    private final CoopOfferRepository repository;
    private final UserRepository userRepository;

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
                .build();
        
        CoopOffer saved = repository.save(offer);
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
}
