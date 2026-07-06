package uz.agroinvest.module.superadmin;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.superadmin.entity.PlatformSettings;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PlatformSettingsRepository extends JpaRepository<PlatformSettings, UUID> {
    Optional<PlatformSettings> findBySettingKey(String settingKey);
}
