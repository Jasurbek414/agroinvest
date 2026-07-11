package uz.agroinvest.module.coop.dto;

import uz.agroinvest.module.coop.entity.CoopOffer;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record CoopOfferDto(
    UUID id,
    String title,
    String description,
    String type,
    BigDecimal amount,
    String status,
    UUID creatorId,
    String creatorName,
    String contactPhone,
    LocalDateTime createdAt
) {
    public static CoopOfferDto fromEntity(CoopOffer offer) {
        return new CoopOfferDto(
            offer.getId(),
            offer.getTitle(),
            offer.getDescription(),
            offer.getType(),
            offer.getAmount(),
            offer.getStatus(),
            offer.getCreatorId(),
            offer.getCreatorName(),
            offer.getContactPhone(),
            offer.getCreatedAt()
        );
    }
}
