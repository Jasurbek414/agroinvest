package uz.agroinvest.module.permission.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomRoleDto {
    private UUID id;
    private String name;
    private String description;
    private boolean active;
    private String createdByName;
    private LocalDateTime createdAt;
    private List<String> permissionCodes;
}
