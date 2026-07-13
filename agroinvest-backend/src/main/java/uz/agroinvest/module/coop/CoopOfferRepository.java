package uz.agroinvest.module.coop;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uz.agroinvest.module.coop.entity.CoopOffer;

import java.util.UUID;
import java.util.List;

@Repository
public interface CoopOfferRepository extends JpaRepository<CoopOffer, UUID> {
    Page<CoopOffer> findAllByStatus(String status, Pageable pageable);
    Page<CoopOffer> findAllByTypeAndStatus(String type, String status, Pageable pageable);
    List<CoopOffer> findByInvestmentIdAndStatusIn(UUID investmentId, List<String> statuses);
    long countByStatus(String status);
}
