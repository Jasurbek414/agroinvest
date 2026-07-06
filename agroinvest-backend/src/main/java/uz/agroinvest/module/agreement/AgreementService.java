package uz.agroinvest.module.agreement;

import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.Paragraph;
import com.itextpdf.layout.properties.TextAlignment;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import uz.agroinvest.common.exception.ApiException;
import uz.agroinvest.common.exception.ErrorCode;
import uz.agroinvest.module.investment.InvestmentRepository;
import uz.agroinvest.module.investment.entity.Investment;

import java.io.ByteArrayOutputStream;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Service
public class AgreementService {

    private final InvestmentRepository investmentRepository;

    public AgreementService(InvestmentRepository investmentRepository) {
        this.investmentRepository = investmentRepository;
    }

    @Transactional(readOnly = true)
    public byte[] generateInvestmentAgreementPdf(UUID investmentId, UUID requestingUserId) {
        Investment investment = investmentRepository.findById(investmentId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Sarmoya topilmadi"));

        // Ownership check: without this, any authenticated investor who guesses/enumerates
        // a UUID can download another investor's contract (full name, phone, amount).
        if (!investment.getInvestor().getId().equals(requestingUserId)) {
            throw new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Ushbu shartnomani ko'rishga ruxsatingiz yo'q");
        }

        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PdfWriter writer = new PdfWriter(out);
            PdfDocument pdf = new PdfDocument(writer);
            Document document = new Document(pdf);

            // Title
            Paragraph title = new Paragraph("INVESTITSIYA SHARTNOMASI (OFFERTA)")
                    .setTextAlignment(TextAlignment.CENTER)
                    .setBold()
                    .setFontSize(16);
            document.add(title);
            
            // Subtitle / Date
            String dateStr = investment.getCreatedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            Paragraph subtitle = new Paragraph("Shartnoma raqami: AI-" + investment.getId().toString().substring(0, 8).toUpperCase() + "\nSana: " + dateStr)
                    .setTextAlignment(TextAlignment.RIGHT)
                    .setFontSize(10);
            document.add(subtitle);
            document.add(new Paragraph("\n"));

            // Content
            document.add(new Paragraph("1. SHARTNOMA SHARTLARI").setBold().setFontSize(12));
            document.add(new Paragraph(
                    "Ushbu shartnoma AgroInvest platformasi orqali Investor va Fermer o'rtasidagi kelishuvni tartibga soladi. " +
                    "Investor loyihani moliyalashtirish uchun mablag' kiritadi va Fermer loyihani o'z vaqtida parvarish qilib, mahsulotni sotish va foydani taqsimlash majburiyatini oladi."
            ).setFontSize(10));
            document.add(new Paragraph("\n"));

            document.add(new Paragraph("2. TOMONLAR MA'LUMOTLARI").setBold().setFontSize(12));
            document.add(new Paragraph("Sarmoyador: " + investment.getInvestor().getFullName() + " (Tel: " + investment.getInvestor().getPhoneNumber() + ")").setFontSize(10));
            document.add(new Paragraph("Loyiha: " + investment.getProject().getTitle() + " (Fermer: " + investment.getProject().getFarmer().getFullName() + ")").setFontSize(10));
            document.add(new Paragraph("\n"));

            document.add(new Paragraph("3. MOLIYAVIY PARAMETRLAR").setBold().setFontSize(12));
            document.add(new Paragraph("Sarmoya miqdori: " + investment.getAmount() + " UZS").setFontSize(10));
            document.add(new Paragraph("Loyiha muddati: " + investment.getProject().getDurationDays() + " kun").setFontSize(10));
            document.add(new Paragraph("Kutilayotgan foyda: +" + investment.getProject().getExpectedReturnPct() + "%").setFontSize(10));
            document.add(new Paragraph("Investor ulushi (Loyiha umumiy daromadida): " + investment.getSharePct() + "%").setFontSize(10));
            document.add(new Paragraph("\n"));

            document.add(new Paragraph("4. YAKUNIY QOIDALAR").setBold().setFontSize(12));
            document.add(new Paragraph(
                    "Mablag'lar loyiha to'liq moliyalashtirilgunga qadar platforma hamyonida muzlatiladi. Loyiha muvaffaqiyatsiz tugasa yoki muddatida " +
                    "yig'ilmasa, barcha mablag'lar investor balansiga komissiyasiz qaytariladi. Shartnoma elektron ko'rinishda tasdiqlangan va yuridik kuchga ega."
            ).setFontSize(10));

            document.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("PDF shartnomasini yaratishda xatolik yuz berdi", e);
        }
    }
}
