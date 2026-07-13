package uz.agroinvest.module.vet;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import uz.agroinvest.common.response.ApiResponse;
import uz.agroinvest.module.vet.dto.SaveVeterinarianRequest;
import uz.agroinvest.module.vet.dto.VeterinarianDto;

import java.util.List;
import java.util.UUID;

@RestController
public class VeterinarianController {

    private final VeterinarianService service;

    public VeterinarianController(VeterinarianService service) {
        this.service = service;
    }

    /** Public/Authenticated endpoint for farmers to list active veterinarians */
    @GetMapping("/api/v1/vet-inspections/veterinarians")
    public ResponseEntity<ApiResponse<List<VeterinarianDto>>> getActiveVeterinarians() {
        return ResponseEntity.ok(ApiResponse.success(service.getActiveVeterinarians()));
    }

    /** SuperAdmin lists all veterinarians */
    @GetMapping("/api/v1/superadmin/veterinarians")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<ApiResponse<List<VeterinarianDto>>> getAllVeterinarians() {
        return ResponseEntity.ok(ApiResponse.success(service.getAllVeterinarians()));
    }

    /** SuperAdmin registers a new veterinarian */
    @PostMapping("/api/v1/superadmin/veterinarians")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<ApiResponse<VeterinarianDto>> addVeterinarian(
            @Valid @RequestBody SaveVeterinarianRequest request
    ) {
        VeterinarianDto dto = service.addVeterinarian(request);
        return new ResponseEntity<>(ApiResponse.success(dto), HttpStatus.CREATED);
    }

    /** SuperAdmin deletes a veterinarian */
    @DeleteMapping("/api/v1/superadmin/veterinarians/{id}")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteVeterinarian(@PathVariable UUID id) {
        service.deleteVeterinarian(id);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
