package uz.agroinvest.module.region;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.module.region.entity.Region;
import uz.agroinvest.module.region.dto.RegionDto;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1")
public class RegionController {
    private final RegionRepository regionRepository;

    public RegionController(RegionRepository regionRepository) {
        this.regionRepository = regionRepository;
    }

    @GetMapping("/regions")
    public ResponseEntity<ApiResponse<List<RegionDto>>> getRegions() {
        List<RegionDto> list = regionRepository.findAll()
                .stream()
                .map(r -> new RegionDto(r.getId(), r.getName()))
                .sorted((a, b) -> a.getName().compareToIgnoreCase(b.getName()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(list));
    }

    @PostMapping("/superadmin/regions")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<ApiResponse<RegionDto>> createRegion(@RequestBody RegionDto dto) {
        Region region = Region.builder().name(dto.getName()).build();
        Region saved = regionRepository.save(region);
        return ResponseEntity.ok(ApiResponse.success(new RegionDto(saved.getId(), saved.getName())));
    }

    @DeleteMapping("/superadmin/regions/{id}")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteRegion(@PathVariable UUID id) {
        regionRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
