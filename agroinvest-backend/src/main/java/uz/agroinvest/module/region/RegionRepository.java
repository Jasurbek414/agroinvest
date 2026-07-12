package uz.agroinvest.module.region;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.region.entity.Region;
import java.util.UUID;

@Repository
public interface RegionRepository extends JpaRepository<Region, UUID> {
}
