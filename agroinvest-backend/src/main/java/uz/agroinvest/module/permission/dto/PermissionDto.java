package uz.agroinvest.module.permission.dto;

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
public class PermissionDto {
    private UUID id;
    private String code;
    private String description;
    private LocalDateTime createdAt;
}
