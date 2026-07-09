package uz.agroinvest.module.permission;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.enums.UserRole;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.permission.dto.CustomRoleDto;
import uz.agroinvest.module.permission.dto.PermissionDto;
import uz.agroinvest.module.permission.entity.*;
import uz.agroinvest.module.user.UserRepository;
import uz.agroinvest.module.user.entity.User;
import uz.agroinvest.security.UserPrincipal;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * Resolves a user's EFFECTIVE permission set: their fixed base role's granted
 * permissions (role_permissions, Redis-cached since it changes rarely) union
 * every active custom role currently assigned to them (custom_role_permissions,
 * looked up directly - custom-role assignment is expected to be staff-only and
 * infrequent, so this doesn't need its own cache layer yet).
 *
 * Also the single write path for permission/custom-role CRUD used by the
 * SuperAdmin management endpoints (PermissionController).
 *
 * Implements ApplicationRunner to evict every role_permissions:* cache entry on
 * startup: a Flyway migration that seeds new role_permissions rows (e.g. V24
 * granting SUPERADMIN 'banner.manage') writes straight to the DB, bypassing
 * grantToRole()/evictRoleCache() - without this, a role's cached permission set
 * from before the migration would keep denying the newly-granted permission
 * for up to ROLE_CACHE_TTL_HOURS after every deploy.
 */
@Service
public class PermissionService implements ApplicationRunner {

    private static final Logger logger = LoggerFactory.getLogger(PermissionService.class);

    private static final String ROLE_CACHE_KEY_PREFIX = "role_permissions:";
    private static final long ROLE_CACHE_TTL_HOURS = 6;

    private final PermissionRepository permissionRepository;
    private final RolePermissionRepository rolePermissionRepository;
    private final CustomRoleRepository customRoleRepository;
    private final CustomRolePermissionRepository customRolePermissionRepository;
    private final UserCustomRoleRepository userCustomRoleRepository;
    private final UserRepository userRepository;
    private final RedisTemplate<String, Object> redisTemplate;

    public PermissionService(
            PermissionRepository permissionRepository,
            RolePermissionRepository rolePermissionRepository,
            CustomRoleRepository customRoleRepository,
            CustomRolePermissionRepository customRolePermissionRepository,
            UserCustomRoleRepository userCustomRoleRepository,
            UserRepository userRepository,
            RedisTemplate<String, Object> redisTemplate
    ) {
        this.permissionRepository = permissionRepository;
        this.rolePermissionRepository = rolePermissionRepository;
        this.customRoleRepository = customRoleRepository;
        this.customRolePermissionRepository = customRolePermissionRepository;
        this.userCustomRoleRepository = userCustomRoleRepository;
        this.userRepository = userRepository;
        this.redisTemplate = redisTemplate;
    }

    @Override
    public void run(ApplicationArguments args) {
        try {
            Set<String> keys = redisTemplate.keys(ROLE_CACHE_KEY_PREFIX + "*");
            if (keys != null && !keys.isEmpty()) {
                redisTemplate.delete(keys);
                logger.info("Evicted {} stale role-permission cache entries on startup", keys.size());
            }
        } catch (Exception e) {
            // Redis being briefly unavailable at startup shouldn't fail the boot -
            // getRolePermissions() already falls back to the DB on any cache-read error.
            logger.warn("Could not evict role-permission cache on startup: {}", e.getMessage());
        }
    }

    /** Used by the `@authz.has(...)` SpEL bean backing @PreAuthorize("hasPermission(...)") checks. */
    @Transactional(readOnly = true)
    public boolean hasPermission(UserPrincipal principal, String code) {
        if (principal == null || code == null) return false;
        return getEffectivePermissions(principal.getId(), principal.getRole()).contains(code);
    }

    @Transactional(readOnly = true)
    public Set<String> getEffectivePermissions(UUID userId, UserRole baseRole) {
        Set<String> effective = new HashSet<>(getRolePermissions(baseRole));
        effective.addAll(customRolePermissionRepository.findPermissionCodesForUser(userId));
        return effective;
    }

    private Set<String> getRolePermissions(UserRole role) {
        String cacheKey = ROLE_CACHE_KEY_PREFIX + role.name();
        try {
            Object cached = redisTemplate.opsForValue().get(cacheKey);
            if (cached instanceof List<?> list) {
                return list.stream().map(Object::toString).collect(Collectors.toSet());
            }
        } catch (Exception e) {
            // A cache entry written as List.copyOf(...) (a JDK-internal immutable
            // collection type) doesn't reliably round-trip through Jackson's
            // polymorphic Redis serializer across JVM restarts - treat any
            // deserialization failure as a cache miss instead of failing every
            // permission check for the role until the 6h TTL happens to expire.
            logger.warn("Could not read cached permissions for role {}, recomputing from DB: {}", role, e.getMessage());
        }

        Set<String> codes = rolePermissionRepository.findByRole(role).stream()
                .map(RolePermission::getPermissionCode)
                .collect(Collectors.toSet());
        redisTemplate.opsForValue().set(cacheKey, new ArrayList<>(codes), ROLE_CACHE_TTL_HOURS, TimeUnit.HOURS);
        return codes;
    }

    private void evictRoleCache(UserRole role) {
        redisTemplate.delete(ROLE_CACHE_KEY_PREFIX + role.name());
    }

    /** Backs the SuperAdmin permission-matrix UI: which codes are currently granted to a role. */
    @Transactional(readOnly = true)
    public List<String> getRolePermissionCodes(UserRole role) {
        return getRolePermissions(role).stream().sorted().toList();
    }

    // ---- Permission CRUD (SuperAdmin) ----

    @Transactional
    public PermissionDto createPermission(String code, String description) {
        if (permissionRepository.existsByCode(code)) {
            throw new ApiException(ErrorCode.CONFLICT, HttpStatus.CONFLICT, "Bu kod bilan ruxsat allaqachon mavjud: " + code);
        }
        Permission saved = permissionRepository.save(Permission.builder().code(code).description(description).build());
        return mapToDto(saved);
    }

    @Transactional(readOnly = true)
    public List<PermissionDto> listPermissions() {
        return permissionRepository.findAll().stream().map(this::mapToDto).toList();
    }

    private PermissionDto mapToDto(Permission permission) {
        return PermissionDto.builder()
                .id(permission.getId())
                .code(permission.getCode())
                .description(permission.getDescription())
                .createdAt(permission.getCreatedAt())
                .build();
    }

    @Transactional
    public void grantToRole(UserRole role, String permissionCode) {
        Permission permission = permissionRepository.findByCode(permissionCode)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Ruxsat topilmadi: " + permissionCode));
        if (!rolePermissionRepository.existsByRoleAndPermissionCode(role, permission.getCode())) {
            rolePermissionRepository.save(RolePermission.builder().role(role).permissionCode(permission.getCode()).build());
            evictRoleCache(role);
        }
    }

    @Transactional
    public void revokeFromRole(UserRole role, String permissionCode) {
        rolePermissionRepository.deleteByRoleAndPermissionCode(role, permissionCode);
        evictRoleCache(role);
    }

    // ---- Custom role CRUD (SuperAdmin) ----

    @Transactional
    public CustomRoleDto createCustomRole(String name, String description, UserPrincipal creator) {
        if (customRoleRepository.existsByName(name)) {
            throw new ApiException(ErrorCode.CONFLICT, HttpStatus.CONFLICT, "Bu nom bilan rol allaqachon mavjud: " + name);
        }
        User createdBy = userRepository.findById(creator.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
        CustomRole saved = customRoleRepository.save(CustomRole.builder().name(name).description(description).createdBy(createdBy).build());
        return mapToDto(saved, List.of());
    }

    @Transactional
    public void addPermissionToCustomRole(UUID customRoleId, String permissionCode) {
        CustomRole customRole = customRoleRepository.findById(customRoleId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Rol topilmadi"));
        Permission permission = permissionRepository.findByCode(permissionCode)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Ruxsat topilmadi: " + permissionCode));
        if (!customRolePermissionRepository.existsByCustomRoleIdAndPermissionCode(customRoleId, permission.getCode())) {
            customRolePermissionRepository.save(CustomRolePermission.builder().customRole(customRole).permissionCode(permission.getCode()).build());
        }
    }

    @Transactional
    public void assignCustomRoleToUser(UUID userId, UUID customRoleId, UserPrincipal assignedBy) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Foydalanuvchi topilmadi"));
        CustomRole customRole = customRoleRepository.findById(customRoleId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Rol topilmadi"));
        if (userCustomRoleRepository.findByUserIdAndCustomRoleId(userId, customRoleId).isPresent()) {
            return; // already assigned - idempotent
        }
        User admin = userRepository.findById(assignedBy.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND));
        userCustomRoleRepository.save(UserCustomRole.builder().user(user).customRole(customRole).assignedBy(admin).build());
    }

    @Transactional
    public void unassignCustomRoleFromUser(UUID userId, UUID customRoleId) {
        userCustomRoleRepository.findByUserIdAndCustomRoleId(userId, customRoleId)
                .ifPresent(userCustomRoleRepository::delete);
    }

    @Transactional(readOnly = true)
    public List<CustomRoleDto> listCustomRoles() {
        return customRoleRepository.findAll().stream()
                .map(role -> mapToDto(role, customRolePermissionRepository.findByCustomRoleId(role.getId()).stream()
                        .map(CustomRolePermission::getPermissionCode)
                        .toList()))
                .toList();
    }

    private CustomRoleDto mapToDto(CustomRole role, List<String> permissionCodes) {
        return CustomRoleDto.builder()
                .id(role.getId())
                .name(role.getName())
                .description(role.getDescription())
                .active(role.isActive())
                .createdByName(role.getCreatedBy() != null ? role.getCreatedBy().getFullName() : null)
                .createdAt(role.getCreatedAt())
                .permissionCodes(permissionCodes)
                .build();
    }
}
