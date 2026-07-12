package uz.agroinvest.module.region.dto;

import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RegionDto {
    private UUID id;
    private String name;
}
