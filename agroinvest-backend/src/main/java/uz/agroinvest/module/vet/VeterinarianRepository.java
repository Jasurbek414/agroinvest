package uz.agroinvest.module.vet;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.vet.entity.Veterinarian;
import java.util.Optional;
import java.util.UUID;
import java.util.List;

@Repository
public interface VeterinarianRepository extends JpaRepository<Veterinarian, UUID> {
    Optional<Veterinarian> findByLicenseNo(String licenseNo);
    List<Veterinarian> findAllByIsActiveTrue();
}
