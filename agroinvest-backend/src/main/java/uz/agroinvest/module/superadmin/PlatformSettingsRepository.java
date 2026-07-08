package uz.agroinvest.module.superadmin;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.superadmin.entity.PlatformSettings;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PlatformSettingsRepository extends JpaRepository<PlatformSettings, UUID> {
    // open-in-view is disabled - updatedBy must be fetched eagerly here, or the
    // service-layer DTO mapper hits a LazyInitializationException once the
    // transaction/Hibernate session has already closed.
    @EntityGraph(attributePaths = {"updatedBy"})
    @Override
    Page<PlatformSettings> findAll(Pageable pageable);

    Optional<PlatformSettings> findBySettingKey(String settingKey);
}
