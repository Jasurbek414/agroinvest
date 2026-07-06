package uz.agroinvest.module.dispute;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.dispute.entity.Dispute;

import java.util.List;
import java.util.UUID;

@Repository
public interface DisputeRepository extends JpaRepository<Dispute, UUID> {
    List<Dispute> findByProjectId(UUID projectId);
    Page<Dispute> findAll(Pageable pageable);
    Page<Dispute> findByFiledById(UUID filedById, Pageable pageable);
}
