package uz.agroinvest.security;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import uz.agroinvest.module.permission.PermissionService;

/**
 * Backs `@PreAuthorize("@authz.has('project.approve')")` fine-grained permission
 * checks - lives ALONGSIDE the existing hasRole()/hasAnyRole() checks, does not
 * replace them. New/migrated endpoints adopt @authz.has(...); untouched
 * endpoints keep their role-based check unchanged (see PLATFORM_ROADMAP.md).
 */
@Component("authz")
public class AuthorizationBean {

    private final PermissionService permissionService;

    public AuthorizationBean(PermissionService permissionService) {
        this.permissionService = permissionService;
    }

    public boolean has(String permissionCode) {
        Object principal = SecurityContextHolder.getContext().getAuthentication() != null
                ? SecurityContextHolder.getContext().getAuthentication().getPrincipal()
                : null;
        if (!(principal instanceof UserPrincipal userPrincipal)) {
            return false;
        }
        return permissionService.hasPermission(userPrincipal, permissionCode);
    }
}
