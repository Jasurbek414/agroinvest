package uz.agroinvest.module.vet;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.module.vet.dto.SaveVeterinarianRequest;
import uz.agroinvest.module.vet.dto.VeterinarianDto;
import uz.agroinvest.module.vet.entity.Veterinarian;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class VeterinarianService {

    private final VeterinarianRepository repository;

    public VeterinarianService(VeterinarianRepository repository) {
        this.repository = repository;
    }

    public List<VeterinarianDto> getActiveVeterinarians() {
        return repository.findAllByIsActiveTrue().stream()
                .map(VeterinarianDto::fromEntity)
                .collect(Collectors.toList());
    }

    public List<VeterinarianDto> getAllVeterinarians() {
        return repository.findAll().stream()
                .map(VeterinarianDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public VeterinarianDto addVeterinarian(SaveVeterinarianRequest request) {
        if (repository.findByLicenseNo(request.licenseNo()).isPresent()) {
            throw new IllegalArgumentException("Ushbu litsenziya raqamiga ega veterinar allaqachon ro'yxatdan o'tgan");
        }

        Veterinarian vet = Veterinarian.builder()
                .name(request.name())
                .licenseNo(request.licenseNo())
                .phone(request.phone())
                .specialty(request.specialty())
                .isActive(true)
                .build();

        return VeterinarianDto.fromEntity(repository.save(vet));
    }

    @Transactional
    public void deleteVeterinarian(UUID id) {
        if (!repository.existsById(id)) {
            throw new IllegalArgumentException("Veterinar topilmadi");
        }
        repository.deleteById(id);
    }
}
