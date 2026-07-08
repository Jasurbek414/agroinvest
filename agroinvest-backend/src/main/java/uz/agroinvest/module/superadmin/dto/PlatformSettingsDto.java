package uz.agroinvest.module.superadmin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlatformSettingsDto {
    private UUID id;
    private String settingKey;
    private String settingValue;
    private String description;
    private String updatedByName;
    private LocalDateTime updatedAt;
}
