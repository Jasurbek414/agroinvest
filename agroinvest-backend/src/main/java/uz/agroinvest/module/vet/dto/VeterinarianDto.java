package uz.agroinvest.module.vet.dto;

import uz.agroinvest.module.vet.entity.Veterinarian;
import java.time.LocalDateTime;
import java.util.UUID;

public record VeterinarianDto(
    UUID id,
    String name,
    String licenseNo,
    String phone,
    String specialty,
    Boolean isActive,
    LocalDateTime createdAt
) {
    public static VeterinarianDto fromEntity(Veterinarian vet) {
        return new VeterinarianDto(
            vet.getId(),
            vet.getName(),
            vet.getLicenseNo(),
            vet.getPhone(),
            vet.getSpecialty(),
            vet.getIsActive(),
            vet.getCreatedAt()
        );
    }
}
