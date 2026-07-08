package uz.agroinvest.module.permission;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.permission.entity.CustomRole;

import java.util.List;
import java.util.UUID;

@Repository
public interface CustomRoleRepository extends JpaRepository<CustomRole, UUID> {
    // open-in-view is disabled - createdBy must be fetched eagerly here, or
    // Jackson hits a LazyInitializationException serializing it after the
    // transaction (and Hibernate session) has already closed.
    @EntityGraph(attributePaths = {"createdBy"})
    @Override
    List<CustomRole> findAll();

    Page<CustomRole> findAll(Pageable pageable);
    boolean existsByName(String name);
}
